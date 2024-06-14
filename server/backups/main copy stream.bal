import ballerina/websocket;
import websocket_test.types;
import ballerina/io;

listener websocket:Listener websocketListener = check new(9092);
// map<types:User> users = {};
isolated map<UserChat> users = {};

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
    isolated resource function get .() returns websocket:Service|websocket:UpgradeError {
        return new WsServiceUser();
    }

}

service class WsService {
    *websocket:Service;

    remote function onHello(types:Hello clientData) returns types:Response? {
        return {message:"You sent: " + clientData.message};
    }

}

isolated service class WsServiceUser {
    *websocket:Service;
    
    isolated remote function onSubscribe(websocket:Caller caller, types:Subscribe sub) returns stream<types:Response> {
        io:println("Subscribe: " + caller.getConnectionId());
        lock {
	        users[caller.getConnectionId()] = new ({caller: caller, gender: sub.gender, name: sub.name, id: caller.getConnectionId()});
            users.get(caller.getConnectionId()).addChat({message: "Welcome to the chat " + sub.name, event: "chat", toUserId: caller.getConnectionId()});
            return new (new ChatStream(users.get(caller.getConnectionId())));
        }
    }

    isolated remote function onUnsubscribe(websocket:Caller caller, types:Unsubscribe unsubscribe) returns error? {
        // broadcast("User " + users.get(caller.getConnectionId()).name + " has left the chat");
        lock {
            if (users.hasKey(caller.getConnectionId())) {
                _ = users.remove(caller.getConnectionId());
            }
        }
        check caller->close(0);
    }

    remote function onClose(websocket:Caller caller) returns websocket:Error? {
        lock {
            if (users.hasKey(caller.getConnectionId())) {
                _ = users.remove(caller.getConnectionId());
            }
        }
        _ = check caller->close(0);
    }

    isolated remote function onChat(websocket:Caller caller, types:Chat message) returns error? {
        // if (!users.hasKey(caller.getConnectionId())) {
        //     return { message: "Please subscribe first to send messages"};
        // }
        // types:User sender = users.get(caller.getConnectionId());
        // if (!users.hasKey(message.toUserId)) {
        //     return {message:"User not found"};
        // }
        // websocket:Caller? receiver = users.get(message.toUserId).caller;
        // if (receiver is ()) {
        //     return {message:"User not found"};
        // }
        // _ = check receiver->writeMessage({message: sender.name + ": " + message.message, event:"chat"});
        // return {message:"You: " + message.message, event: "chat"};

        lock {
            types:Chat fromChat = message.clone();
            fromChat.message = "You: " + message.message;
            types:Chat toChat = message.clone();
            toChat.message = users.get(caller.getConnectionId()).getUser().name + ": " + message.message;

            UserChat fromUser = users.get(caller.getConnectionId());
            UserChat toUser = users.get(message.toUserId);
            fromUser.addChat(fromChat);
            toUser.addChat(toChat);
        }
    }
  
}

// function broadcast(string message) {
//     users.forEach(function (types:User user) {
//         websocket:Caller? caller = user.caller;
//         if (caller is ()) {
//             return;
//         }
//         types:Response response = {message: message, event: "broadcast"};
//         error? err = caller->writeMessage(response);
//         if (err is error) {
//             io:println("Error broadcasting message: " + err.message());
//         }
//     });
// }
