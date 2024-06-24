import ballerina/websocket;
import websocket_test.types;
import ballerina/io;

listener websocket:Listener websocketListener = check new(9092);
map<types:User> users = {};

@websocket:ServiceConfig{dispatcherKey: "event"}
service / on websocketListener {
    # An echo service that echoes the messages sent by the client.
    # + return - User status
    resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new WsService();
    }

}

@websocket:ServiceConfig{dispatcherKey: "event"}
service /user on websocketListener {
    # Allows clients to get real-time data on users and chat with them.
    # + return - websocket service
    resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new WsServiceUser();
    }

}

service class WsService {
    *websocket:Service;

    remote function onHello(types:Hello clientData) returns types:Response? {
        return {message:"You sent: " + clientData.message, id: "null"};
    }

}

service class WsServiceUser {
    *websocket:Service;
    
    remote function onSubscribe(websocket:Caller caller, types:Subscribe sub) returns types:Response {
        io:println("Subscribe: " + caller.getConnectionId());
        types:User user = {caller: caller, gender: sub.gender, name: sub.name, id: caller.getConnectionId(), streamId: sub.id};
        users[caller.getConnectionId()] = user;
        broadcast("System: User " + user.name + " (" + caller.getConnectionId() + ")" + " has joined the chat");
        return {message: "System: Welcome to the chat!", event:"chat", id: sub.id};
    } 

    remote function onUnsubscribe(websocket:Caller caller, types:Unsubscribe unsubscribe) returns error? {
        broadcast("System: User " + users.get(caller.getConnectionId()).name + " has left the chat");
        _ = users.remove(caller.getConnectionId());
        check caller->close(0);
    }

    remote function onClose(websocket:Caller caller) returns websocket:Error? {
        _ = users.remove(caller.getConnectionId());
        _ = check caller->close(0);
    }

    remote function onChat(websocket:Caller caller, types:Chat message) returns types:Response|error {
        if (!users.hasKey(caller.getConnectionId())) {
            return { message: "Please subscribe first to send messages", id: message.id, event:"chat"};
        }
        types:User sender = users.get(caller.getConnectionId());
        if (!users.hasKey(message.toUserId)) {
            return {message:"User not found", id: message.id, event:"chat"};
        }
        types:User receiver = users.get(message.toUserId);
        websocket:Caller? receiverCaller = receiver.caller;
        if (receiverCaller is ()) {
            return {message:"User not found", id: message.id, event:"chat"};
        }
        _ = check receiverCaller->writeMessage({message: sender.name + ": " + message.message, event:"chat", id: receiver.streamId});
        return {message:"You: " + message.message, event: "chat", id: message.id};
    }
  
}

function broadcast(string message) {
    users.forEach(function (types:User user) {
        websocket:Caller? caller = user.caller;
        if (caller is ()) {
            return;
        }
        types:Response response = {message: message, event: "chat", id: user.streamId};
        error? err = caller->writeMessage(response);
        if (err is error) {
            io:println("Error broadcasting message: " + err.message());
        }
    });
}
