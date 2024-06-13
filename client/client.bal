import ballerina/lang.runtime;
import ballerina/websocket;

import xlibb/pipe;
import ballerina/io;

public client isolated class UserClient {
    public final websocket:Client clientEp;
    private final pipe:Pipe writeMessageQueue;
    private final pipe:Pipe readMessageQueue;
    private final PipesMap pipes;
    private boolean isActive;

    # Gets invoked to initialize the `connector`.
    #
    # + config - The configurations to be used when initializing the `connector` 
    # + serviceUrl - URL of the target service 
    # + return - An error if connector initialization failed 
    public isolated function init(websocket:ClientConfiguration clientConfig =  {}, string serviceUrl = "ws://localhost:9092/user") returns error? {
        self.pipes = new ();
        self.writeMessageQueue = new (1000);
        self.readMessageQueue = new (1000);
        websocket:Client websocketEp = check new (serviceUrl, clientConfig);
        self.clientEp = websocketEp;
        self.isActive = true;
        self.startMessageWriting();
        self.startMessageReading();
        self.startPipeTriggering();
        return;
    }

    private isolated function startMessageWriting() {
        worker writeMessage {
            while true {
                lock {
                    if !self.isActive {
                        break;
                    }
                }
                Message|pipe:Error requestMessage = self.writeMessageQueue.consume(5);
                if requestMessage is pipe:Error {
                    if (requestMessage.message() == "Operation has timed out") {
                        continue;
                    }
                    io:println("PipeError: " + requestMessage.message());
                    self.attemptToCloseConnection();
                    return;
                }
                websocket:Error? err =  self.clientEp->writeMessage(requestMessage);
                if err is websocket:Error {
                    io:println("WsError: " + err.message());
                    self.attemptToCloseConnection();
                    return;
                }
                runtime:sleep(0.01);
            }
        }
        
    }

    private isolated function startMessageReading() {
        worker readMessage {
            while true {
                lock {
                    if !self.isActive {
                        break;
                    }
                }
                Message|error message = self.clientEp->readMessage();
                if message is error {
                    io:println("WsError: " + message.message());
                    self.attemptToCloseConnection();
                    return;
                }
                pipe:Error? err = self.readMessageQueue.produce(message, 5);
                if err is pipe:Error {
                    io:println("PipeError: " + err.message());
                    self.attemptToCloseConnection();
                    return;
                }
                runtime:sleep(0.01);
            }
        }
    }

    private isolated function startPipeTriggering() {
        worker pipeTrigger {
            while true {
                lock {
                    if !self.isActive {
                        break;
                    }
                }
                Message|pipe:Error message = self.readMessageQueue.consume(5);
                if message is pipe:Error {
                    if (message.message() == "Operation has timed out") {
                        continue;
                    }
                    io:println("PipeError: " + message.message());
                    self.attemptToCloseConnection();
                    return;
                }
                pipe:Pipe pipe = self.pipes.getPipe(message.event);
                pipe:Error? err = pipe.produce(message, 5);
                if (err is pipe:Error) {
                    io:println("PipeError: " + err.message());
                    self.attemptToCloseConnection();
                    return;
                }
            }
        }
    }

    remote isolated function doSubscribe(Subscribe subscribe, decimal timeout) returns Response|error {
        lock {
            if !self.isActive {
                return error("ConnectionError: Connection has been closed");
            }
        }
        Message|error message = subscribe.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error ("DataBindingError: Error in cloning message");
        }
        pipe:Error? err =  self.writeMessageQueue.produce(message, timeout);
        if err is pipe:Error {
            self.attemptToCloseConnection();
            return error ("PipeError: Error in producing message");
        }
        Message|pipe:Error responseMessage;
        responseMessage = self.pipes.getPipe("subscribe").consume(timeout);
        if responseMessage is pipe:Error {
            self.attemptToCloseConnection();
            return error ("PipeError: Error in consuming message");
        }
        Response|error response = responseMessage.cloneWithType();
        if response is error {
            self.attemptToCloseConnection();
            return error ("DataBindingError: Error in cloning message");
        }
        return response;
    }

    remote isolated function doUnsubscribe(Unsubscribe unsubscribe, decimal timeout) returns error? {
        lock {
            if !self.isActive {
                return error("ConnectionError: Connection has been closed");
            }
        }
        Message|error message = unsubscribe.cloneWithType();
        if message is error {
             self.attemptToCloseConnection();
            return error ("DataBindingError: Error in cloning message");
        }
        pipe:Error? err = self.writeMessageQueue.produce(message, timeout);
        if err is pipe:Error {
             self.attemptToCloseConnection();
            return error ("PipeError: Error in producing message");
        }
    }

    remote isolated function doChat(Chat chat, decimal timeout) returns Response|error {
        lock {
            if !self.isActive {
                return error("ConnectionError: Connection has been closed");
            }
        }
        Message|error message = chat.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error ("DataBindingError: Error in cloning message");
        }
        pipe:Error? err =  self.writeMessageQueue.produce(message, timeout);
        if err is pipe:Error {
            self.attemptToCloseConnection();
            return error ("PipeError: Error in producing message");
        }
        Message|pipe:Error responseMessage;
        responseMessage = self.pipes.getPipe("chat").consume(timeout);
        if responseMessage is pipe:Error {
            self.attemptToCloseConnection();
            return error ("PipeError: Error in consuming message");
        }
        Response|error response = responseMessage.cloneWithType();
        if response is error {
            self.attemptToCloseConnection();
            return error ("DataBindingError: Error in cloning message");
        }
        return response;
    }

    isolated function attemptToCloseConnection() {
        error? connectionClose = self->connectionClose();
        if connectionClose is error {
            string errorMessage = "ConnectionError: " + connectionClose.message();
            io:println(errorMessage);
        }
    }

    remote isolated function connectionClose() returns error? {
        lock {
            self.isActive = false;
            check self.writeMessageQueue.immediateClose();
            check self.readMessageQueue.immediateClose();
            check self.clientEp->close();
        }
    };
}
