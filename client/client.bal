import ballerina/lang.runtime;
import ballerina/websocket;

import xlibb/pipe;
import ballerina/io;

public client isolated class UserClient {
    private final websocket:Client clientEp;
    private final pipe:Pipe writeMessageQueue;
    private final pipe:Pipe readMessageQueue;
    private final PipesMap pipes;
    private boolean isMessageWriting;
    private boolean isMessageReading;
    private boolean isPipeTriggering;
    private pipe:Pipe? subscribePipe;
    private pipe:Pipe? chatPipe;

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
        self.subscribePipe = ();
        self.chatPipe = ();
        self.isMessageWriting = true;
        self.isMessageReading = true;
        self.isPipeTriggering = true;
        self.startMessageWriting();
        self.startMessageReading();
        self.startPipeTriggering();
        return;
    }

    # Use to write messages to the websocket.
    #
    private isolated function startMessageWriting() {
        worker writeMessage returns error? {
            while true {
                lock {
                    if !self.isMessageWriting {
                        break;
                    }
                }
                anydata requestMessage = check self.writeMessageQueue.consume(5);
                check self.clientEp->writeMessage(requestMessage);
                runtime:sleep(0.01);
            }
        }
        
    }

    # Use to read messages from the websocket.
    #
    private isolated function startMessageReading() {
        worker readMessage returns error? {
            while true {
                lock {
                    if !self.isMessageReading {
                        break;
                    }
                }
                io:println("Reading message");
                string|error message = self.clientEp->readMessage();
                if message is error {
                    io:println("WsError: " + message.message());
                    return;
                }
                io:println("MessageR: " + message.toBalString());
                check self.readMessageQueue.produce(message, 5);
                runtime:sleep(0.01);
            }
        }
    }

    # Use to map received message responses into relevant requests.
    #
    private isolated function startPipeTriggering() {
        worker pipeTrigger returns error? {
            while true {
                lock {
                    if !self.isPipeTriggering {
                        break;
                    }
                }
                Message|pipe:Error message = self.readMessageQueue.consume(5);
                if message is pipe:Error {
                    if (message.message() == "Operation has timed out") {
                        continue;
                    }
                    io:println("Pipe error" + message.message());
                    return error ("Pipe triggering stopped");
                }
                string event = message.event;
                io:println("Event: " + event);
                match (event) {
                    "Response" => {
                        pipe:Pipe subscribePipe = self.pipes.getPipe("subscribe");
                        check subscribePipe.produce(message, 5);
                    }
                    "Response" => {
                        pipe:Pipe chatPipe = self.pipes.getPipe("chat");
                        check chatPipe.produce(message, 5);
                    }
                }
            }
            return error ("Pipe triggering stopped");
        }
    }

    #
    remote isolated function doSubscribe(Subscribe subscribe, decimal timeout) returns Response|error {
        if self.writeMessageQueue.isClosed() {
            return error("connection closed");
        }
        pipe:Pipe subscribePipe;
        lock {
            self.subscribePipe = self.pipes.getPipe("subscribe");
        }
        Message message = check subscribe.cloneWithType();
        check self.writeMessageQueue.produce(message, timeout);
        lock {
            subscribePipe = check self.subscribePipe.ensureType();
        }
        anydata responseMessage = check subscribePipe.consume(timeout);
        Response response = check responseMessage.cloneWithType();
        return response;
    }

    #
    remote isolated function doUnsubscribe(Unsubscribe unsubscribe, decimal timeout) returns error? {
        if self.writeMessageQueue.isClosed() {
            return error("connection closed");
        }
        Message message = check unsubscribe.cloneWithType();
        check self.writeMessageQueue.produce(message, timeout);
    }

    #
    remote isolated function doChat(Chat chat, decimal timeout) returns Response|error {
        if self.writeMessageQueue.isClosed() {
            return error("connection closed");
        }
        pipe:Pipe chatPipe;
        lock {
            self.chatPipe = self.pipes.getPipe("chat");
        }
        Message message = check chat.cloneWithType();
        check self.writeMessageQueue.produce(message, timeout);
        lock {
            chatPipe = check self.chatPipe.ensureType();
        }
        anydata responseMessage = check chatPipe.consume(timeout);
        Response response = check responseMessage.cloneWithType();
        return response;
    }

    remote isolated function closeSubscribePipe() returns error? {
        lock {
            if self.subscribePipe !is() {
                pipe:Pipe subscribePipe = check self.subscribePipe.ensureType();
                check subscribePipe.gracefulClose();
            }
        }
    };

    remote isolated function closeChatPipe() returns error? {
        lock {
            if self.chatPipe !is() {
                pipe:Pipe chatPipe = check self.chatPipe.ensureType();
                check chatPipe.gracefulClose();
            }
        }
    };

    remote isolated function connectionClose() returns error? {
        lock {
            self.isMessageReading = false;
            self.isMessageWriting = false;
            self.isPipeTriggering = false;
            check self.writeMessageQueue.immediateClose();
            check self.readMessageQueue.immediateClose();
            check self.pipes.removePipes();
            check self.clientEp->close();
        }
    };
}
