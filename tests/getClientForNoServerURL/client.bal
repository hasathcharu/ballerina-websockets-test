import ballerina/lang.runtime;
import ballerina/log;
import ballerina/websocket;

import xlibb/pipe;

public client isolated class ChatClient {
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
    public isolated function init(string serviceUrl, websocket:ClientConfiguration clientConfig =  {}) returns error? {
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
                pipe:Pipe pipe = self.pipes.getPipe(message.'type);
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

    # subscribemessage description
    #
    # + subscribeMessage - subscribe payload description 
    # + timeout - waiting period to keep the event in the buffer in seconds 
    # + return - subscribe response description 
    remote isolated function doSubscribeMessage(SubscribeMessage subscribeMessage, decimal timeout) returns stream<NextMessage|CompleteMessage|ErrorMessage,error?>|error {
        lock {
            if !self.isActive {
                return error("[doSubscribeMessage]ConnectionError: Connection has been closed");
            }
        }
        Message|error message = subscribeMessage.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error("[doSubscribeMessage]DataBindingError: Error in cloning message");
        }
        pipe:Error? pipeErr = self.writeMessageQueue.produce(message, timeout);
        if pipeErr is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doSubscribeMessage]PipeError: Error in producing message");
        }
        stream<NextMessage|CompleteMessage|ErrorMessage,error?> streamMessages;
        lock {
            NextMessageCompleteMessageErrorMessageStreamGenerator streamGenerator = new (self.pipes, "subscribeMessage", timeout);
            self.streamGenerators.addStreamGenerator(streamGenerator);
            streamMessages = new (streamGenerator);
        }
        return streamMessages;
    }

    #
    remote isolated function doPingMessage(PingMessage pingMessage, decimal timeout) returns PongMessage|error {
        lock {
            if !self.isActive {
                return error("[doPingMessage]ConnectionError: Connection has been closed");
            }
        }
        Message|error message = pingMessage.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error("[doPingMessage]DataBindingError: Error in cloning message");
        }
        pipe:Error? pipeErr = self.writeMessageQueue.produce(message, timeout);
        if pipeErr is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doPingMessage]PipeError: Error in producing message");
        }
        Message|pipe:Error responseMessage = self.pipes.getPipe("pingMessage").consume(timeout);
        if responseMessage is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doPingMessage]PipeError: Error in consuming message");
        }
        PongMessage|error pongMessage = responseMessage.cloneWithType();
        if pongMessage is error {
            self.attemptToCloseConnection();
            return error("[doPingMessage]DataBindingError: Error in cloning message");
        }
        return pongMessage;
    }

    #
    remote isolated function doPongMessage(PongMessage pongMessage, decimal timeout) returns error? {
        lock {
            if !self.isActive {
                return error("[doPongMessage]ConnectionError: Connection has been closed");
            }
        }
        Message|error message = pongMessage.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error("[doPongMessage]DataBindingError: Error in cloning message");
        }
        pipe:Error? pipeErr = self.writeMessageQueue.produce(message, timeout);
        if pipeErr is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doPongMessage]PipeError: Error in producing message");
        }
    }

    #
    remote isolated function doConnectionInitMessage(ConnectionInitMessage connectionInitMessage, decimal timeout) returns ConnectionAckMessage|error {
        lock {
            if !self.isActive {
                return error("[doConnectionInitMessage]ConnectionError: Connection has been closed");
            }
        }
        Message|error message = connectionInitMessage.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error("[doConnectionInitMessage]DataBindingError: Error in cloning message");
        }
        pipe:Error? pipeErr = self.writeMessageQueue.produce(message, timeout);
        if pipeErr is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doConnectionInitMessage]PipeError: Error in producing message");
        }
        Message|pipe:Error responseMessage = self.pipes.getPipe("connectionInitMessage").consume(timeout);
        if responseMessage is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doConnectionInitMessage]PipeError: Error in consuming message");
        }
        ConnectionAckMessage|error connectionAckMessage = responseMessage.cloneWithType();
        if connectionAckMessage is error {
            self.attemptToCloseConnection();
            return error("[doConnectionInitMessage]DataBindingError: Error in cloning message");
        }
        return connectionAckMessage;
    }

    #
    remote isolated function doCompleteMessage(CompleteMessage completeMessage, decimal timeout) returns error? {
        lock {
            if !self.isActive {
                return error("[doCompleteMessage]ConnectionError: Connection has been closed");
            }
        }
        Message|error message = completeMessage.cloneWithType();
        if message is error {
            self.attemptToCloseConnection();
            return error("[doCompleteMessage]DataBindingError: Error in cloning message");
        }
        pipe:Error? pipeErr = self.writeMessageQueue.produce(message, timeout);
        if pipeErr is pipe:Error {
            self.attemptToCloseConnection();
            return error("[doCompleteMessage]PipeError: Error in producing message");
        }
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
