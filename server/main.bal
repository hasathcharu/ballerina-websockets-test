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
        return {message:"You sent: " + clientData.message};
    }

}

service class WsServiceUser {
    *websocket:Service;
    
    remote function onSubscribe(websocket:Caller caller, types:Subscribe sub) returns types:Response {
        string callerId = caller.getConnectionId();
        io:println("Subscribe: " + callerId);
        types:User user = {caller: caller, gender: sub.gender, name: sub.name, id: callerId};
        users[callerId] = user;
        broadcast("System: User " + user.name + " (" + callerId + ")" + " has joined the chat");
        return {message: "System: Welcome to the chat!", event:"subscribe"};
    } 

    remote function onUnsubscribe(websocket:Caller caller, types:Unsubscribe unsubscribe) returns error? {
        string callerId = caller.getConnectionId();
        broadcast("System: User " + users.get(callerId).name + " has left the chat");
        _ = users.remove(callerId);
    }

    remote function onClose(websocket:Caller caller) returns websocket:Error? {
        string callerId = caller.getConnectionId();
        if (users.hasKey(callerId)) {
            _ = users.remove(callerId);
        }   
    }

    remote function onChat(websocket:Caller caller, types:Chat message) returns types:Response|error {
        string callerId = caller.getConnectionId();
        if (!users.hasKey(callerId)) {
            return { message: "Please subscribe first to send messages"};
        }
        types:User sender = users.get(callerId);
        if (!users.hasKey(message.toUserId)) {
            return {message:"User not found"};
        }
        websocket:Caller? receiver = users.get(message.toUserId).caller;
        if (receiver is ()) {
            return {message:"User not found"};
        }
        _ = check receiver->writeMessage({message: sender.name + ": " + message.message, event:"subscribe"});
        return {message:"You: " + message.message, event: "chat"};
    }
  
}

function broadcast(string message) {
    users.forEach(function (types:User user) {
        websocket:Caller? caller = user.caller;
        if (caller is ()) {
            return;
        }
        types:Response response = {message: message, event: "subscribe"};
        error? err = caller->writeMessage(response);
        if (err is error) {
            io:println("Error broadcasting message: " + err.message());
        }
    });
}
