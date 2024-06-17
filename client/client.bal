import ballerina/lang.runtime;
import ballerina/websocket;

import xlibb/pipe;
import ballerina/io;

public client isolated class UserClient {
    private final websocket:Client clientEp;
    private final pipe:Pipe writeMessageQueue;
    private final PipesMap pipes;
    private final StreamGeneratorsMap streamGenerators;
    private boolean isActive;

    # Gets invoked to initialize the `connector`.
    #
    # + config - The configurations to be used when initializing the `connector` 
    # + serviceUrl - URL of the target service 
    # + return - An error if connector initialization failed 
    public isolated function init(websocket:ClientConfiguration clientConfig =  {}, string serviceUrl = "ws://localhost:9092/user") returns error? {
        self.pipes = new ();
        self.streamGenerators = new ();
        self.writeMessageQueue = new (1000);
        websocket:Client websocketEp = check new (serviceUrl, clientConfig);
        self.clientEp = websocketEp;
        self.isActive = true;
        self.startMessageWriting();
        self.startMessageReading();
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
                    io:println("[writeMessage]PipeError: " + requestMessage.message());
                    self.attemptToCloseConnection();
                    return;
                }
                websocket:Error? err =  self.clientEp->writeMessage(requestMessage);
                if err is websocket:Error {
                    io:println("[writeMessage]WsError: " + err.message());
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
                    io:println("[readMessage]WsError: " + message.message());
                    self.attemptToCloseConnection();
                    return;
                }
                pipe:Pipe pipe = self.pipes.getPipe(message.event);
                pipe:Error? err = pipe.produce(message, 5);
                if (err is pipe:Error) {
                    io:println("[readMessage]PipeError: " + err.message());
                    self.attemptToCloseConnection();
                    return;
                }
                runtime:sleep(0.01);
            }
        }
    }

    remote isolated function doSubscribe(Subscribe subscribe, decimal timeout) returns stream<Response,error?>|error {
        lock {
            if !self.isActive {
                return error("[doSubscribe]ConnectionError: Connection has been closed");
            }
        }
        Message|error message = subscribe.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error ("[doSubscribe]DataBindingError: Error in cloning message");
        }
        pipe:Error? err =  self.writeMessageQueue.produce(message, timeout);
        if err is pipe:Error {
            self.attemptToCloseConnection();
            return error ("[doSubscribe]PipeError: Error in producing message");
        }
        stream<Response,error?> streamMessages;
        lock {
            ResponseStreamGenerator streamGenerator = check new (self.pipes.getPipe("chat"), timeout);
            self.streamGenerators.addStreamGenerator(streamGenerator);
            streamMessages = new (streamGenerator);
        }
        return streamMessages;
    }

    remote isolated function doUnsubscribe(Unsubscribe unsubscribe, decimal timeout) returns error? {
        lock {
            if !self.isActive {
                return error("[doUnsubscribe]ConnectionError: Connection has been closed");
            }
        }
        Message|error message = unsubscribe.cloneWithType();
        if message is error {
             self.attemptToCloseConnection();
            return error ("[doUnsubscribe]DataBindingError: Error in cloning message");
        }
        pipe:Error? err = self.writeMessageQueue.produce(message, timeout);
        if err is pipe:Error {
             self.attemptToCloseConnection();
            return error ("[doUnsubscribe]PipeError: Error in producing message");
        }
    }

    remote isolated function doChat(Chat chat, decimal timeout) returns Response|error {
        lock {
            if !self.isActive {
                return error("[doChat]ConnectionError: Connection has been closed");
            }
        }
        Message|error message = chat.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error ("[doChat]DataBindingError: Error in cloning message");
        }
        pipe:Error? err =  self.writeMessageQueue.produce(message, timeout);
        if err is pipe:Error {
            self.attemptToCloseConnection();
            return error ("[doChat]PipeError: Error in producing message");
        }
        Message|pipe:Error responseMessage;
        responseMessage = self.pipes.getPipe("chat").consume(timeout);
        if responseMessage is pipe:Error {
            self.attemptToCloseConnection();
            return error ("[doChat]PipeError: Error in consuming message");
        }
        Response|error response = responseMessage.cloneWithType();
        if response is error {
            self.attemptToCloseConnection();
            return error ("[doChat]DataBindingError: Error in cloning message");
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
            check self.clientEp->close();
        }
    };
}
