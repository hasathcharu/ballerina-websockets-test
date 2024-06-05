import ballerina/websocket;
import websocket_test.types;

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

    remote function onHello(types:Hello clientData) returns string? {
        return "You sent: " + clientData.message;
    }

}

service class WsServiceUser {
    *websocket:Service;
    
    remote function onSubscribe(websocket:Caller caller, types:Subscribe sub) returns string? {
        types:User user = {caller: caller, gender: sub.gender, name: sub.name, id: caller.getConnectionId()};
        users[caller.getConnectionId()] = user;
        broadcast("User " + user.name + " (" + caller.getConnectionId() + ")" + " has joined the chat");
        return users.toArray().toBalString();
    } 

    remote function onUnsubscribe(websocket:Caller caller, types:Unsubscribe unsubscribe) returns error? {
        broadcast("User " + users.get(caller.getConnectionId()).name + " has left the chat");
        _ = users.remove(caller.getConnectionId());
    }

    // remote function onClose(websocket:Caller caller) returns websocket:Error? {
    //     broadcast("User " + users.get(caller.getConnectionId()).name + " has left the chat");
    //     _ = users.remove(caller.getConnectionId());
    // }

    remote function onChat(websocket:Caller caller, types:Chat message) returns string|error {
        if (!users.hasKey(caller.getConnectionId())) {
            return "Please subscribe first to send messages";
        }
        types:User sender = users.get(caller.getConnectionId());
        if (!users.hasKey(message.toUserId)) {
            return "User not found";
        }
        websocket:Caller? receiver = users.get(message.toUserId).caller;
        if (receiver is ()) {
            return "User not found";
        }
        _ = check receiver->writeTextMessage(sender.name + ": " + message.message);
        return "You: " + message.message;
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
