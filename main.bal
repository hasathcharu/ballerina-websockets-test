import ballerina/websocket;
import websocket_test.types;

listener websocket:Listener websocketListener = check new(9091);
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

    remote function onHi(types:Hello clientData) returns string? {
        return "You sent: " + clientData.message;
    }

}

service class WsServiceUser {
    *websocket:Service;
    
    remote function onSubscribe(websocket:Caller caller, types:User user) returns types:User[]|error? {
        user.caller = caller;
        user.id = caller.getConnectionId();
        users[caller.getConnectionId()] = user;
        broadcast("User " + user.name + " (" + caller.getConnectionId() + ")" + " has joined the chat");
        return users.toArray();
    } 

    remote function onUnsubscribe(websocket:Caller caller, types:Unsubscribe unsubscribe) returns error? {
        broadcast("User " + users.get(caller.getConnectionId()).name + " has left the chat");
        _ = users.remove(caller.getConnectionId());
    }

    remote function onClose(websocket:Caller caller) returns error? {
        broadcast("User " + users.get(caller.getConnectionId()).name + " has left the chat");
        _ = users.remove(caller.getConnectionId());
    }

    remote function onMessage(websocket:Caller caller, types:Message message) returns string|error {
        types:User? sender = users.get(caller.getConnectionId());
        if (sender is ()) {
            return "Please subscribe first to send messages";
        }
        websocket:Caller? receiver = users.get(message.toUserId).caller;
        if (receiver is ()) {
            return "User not found";
        }
        _ = check caller->writeTextMessage("Message from " + sender.name + ": " + message.message);
        return "Message sent";
    }
  
}

function broadcast(string message) {
    users.forEach(function (types:User user) {
        websocket:Caller? caller = user.caller;
        if (caller is ()) {
            return;
        }
        websocket:Error? err = caller->writeTextMessage(message);
    });
}
