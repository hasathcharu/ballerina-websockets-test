import ballerina/lang.runtime;
import ballerina/log;
import ballerina/uuid;
import ballerina/websocket;

import xlibb/pipe;

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

    # Use to write messages to the websocket.
    #
    private isolated function startMessageWriting() {
        worker writeMessage {
            while true {
                lock {
                    if !self.isActive {
                        break;
                    }
                }
                Message|pipe:Error message = self.writeMessageQueue.consume(5);
                if message is pipe:Error {
                    if message.message() == "Operation has timed out" {
                        continue;
                    }
                    log:printError("[writeMessage]PipeError: " + message.message());
                    self.attemptToCloseConnection();
                    return;
                }
                websocket:Error? wsErr = self.clientEp->writeMessage(message);
                if wsErr is websocket:Error {
                    log:printError("[writeMessage]WsError: " + wsErr.message());
                    self.attemptToCloseConnection();
                    return;
                }
                runtime:sleep(0.01);
            }
        }
    }

    # Use to read messages from the websocket.
    #
    private isolated function startMessageReading() {
        worker readMessage {
            while true {
                lock {
                    if !self.isActive {
                        break;
                    }
                }
                Message|websocket:Error message = self.clientEp->readMessage(Message);
                if message is websocket:Error {
                    log:printError("[readMessage]WsError: " + message.message());
                    self.attemptToCloseConnection();
                    return;
                }
                pipe:Pipe pipe;
                MessageWithId|error messageWithId = message.cloneWithType(MessageWithId);
                if messageWithId is MessageWithId {
                    pipe = self.pipes.getPipe(messageWithId.id);
                } else {
                    pipe = self.pipes.getPipe(message.event);
                }
                pipe:Error? pipeErr = pipe.produce(message, 5);
                if pipeErr is pipe:Error {
                    log:printError("[readMessage]PipeError: " + pipeErr.message());
                    self.attemptToCloseConnection();
                    return;
                }
                runtime:sleep(0.01);
            }
        }
    }

    #
    remote isolated function doSubscribe(Subscribe subscribe, decimal timeout) returns stream<Response,error?>|error {
        lock {
            if !self.isActive {
                return error("[doSubscribe]ConnectionError: Connection has been closed");
            }
        }
        subscribe.id = uuid:createType1AsString();
        Message|error message = subscribe.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error("[doSubscribe]DataBindingError: Error in cloning message");
        }
        pipe:Error? pipeErr = self.writeMessageQueue.produce(message, timeout);
        if pipeErr is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doSubscribe]PipeError: Error in producing message");
        }
        stream<Response,error?> streamMessages;
        lock {
            ResponseStreamGenerator streamGenerator = new (self.pipes.getPipe(subscribe.id), timeout);
            self.streamGenerators.addStreamGenerator(streamGenerator);
            streamMessages = new (streamGenerator);
        }
        return streamMessages;
    }

    #
    remote isolated function doUnsubscribe(Unsubscribe unsubscribe, decimal timeout) returns error? {
        lock {
            if !self.isActive {
                return error("[doUnsubscribe]ConnectionError: Connection has been closed");
            }
        }
        Message|error message = unsubscribe.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error("[doUnsubscribe]DataBindingError: Error in cloning message");
        }
        pipe:Error? pipeErr = self.writeMessageQueue.produce(message, timeout);
        if pipeErr is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doUnsubscribe]PipeError: Error in producing message");
        }
    }

    #
    remote isolated function doChat(Chat chat, decimal timeout) returns Response|error {
        lock {
            if !self.isActive {
                return error("[doChat]ConnectionError: Connection has been closed");
            }
        }
        chat.id = uuid:createType1AsString();
        Message|error message = chat.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error("[doChat]DataBindingError: Error in cloning message");
        }
        pipe:Error? pipeErr = self.writeMessageQueue.produce(message, timeout);
        if pipeErr is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doChat]PipeError: Error in producing message");
        }
        Message|pipe:Error responseMessage = self.pipes.getPipe(chat.id).consume(timeout);
        if responseMessage is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doChat]PipeError: Error in consuming message");
        }
        pipe:Error? pipeCloseError = self.pipes.getPipe(chat.id).gracefulClose();
        if pipeCloseError is pipe:Error {
            log:printDebug("[doChat]PipeError: Error in closing pipe.");
        }
        Response|error response = responseMessage.cloneWithType();
        if response is error {
            self.attemptToCloseConnection();
            return error("[doChat]DataBindingError: Error in cloning message");
        }
        return response;
    }

    isolated function attemptToCloseConnection() {
        error? connectionClose = self->connectionClose();
        if connectionClose is error {
            log:printError("ConnectionError: " + connectionClose.message());
        }
    }

    remote isolated function connectionClose() returns error? {
        lock {
            self.isActive = false;
            check self.writeMessageQueue.immediateClose();
            check self.pipes.removePipes();
            check self.streamGenerators.removeStreamGenerators();
            check self.clientEp->close();
        }
    };
}
