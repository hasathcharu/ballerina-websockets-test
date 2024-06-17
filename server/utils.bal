import websocket_test.types;
// import ballerina/lang.runtime;

public isolated service class ChatStream {
    private final UserChat userChat;

    public isolated function init(UserChat userChat) {
        self.userChat = userChat;
    }

    public isolated function next() returns record {|types:Response value;|}|error {
        types:Chat? chat;
        while true {
            chat = self.userChat.getChat();
            if chat is () {
                // runtime:sleep(1);
                continue;
            }
            return {value:{event: "chat", message: chat.message}};
        }
    }
}

public isolated service class UserChat {
    private final types:User user;
    private final types:Chat[] inbox;

    public isolated function init(types:User user) {
        self.user = {name: user.name, gender: user.gender, id: user.id, caller:user.caller};
        self.inbox = [];
    }

    public isolated function getUser() returns types:User {
        lock {
            return {name: self.user.name, gender: self.user.gender, id: self.user.id, caller: self.user.caller};
        }
    }

    public isolated function addChat(types:Chat message) {
        lock {
            self.inbox.push(message.clone());
        }
    }

    public isolated function getChat() returns types:Chat? {
        lock {
            if self.inbox.length() > 0 {
                return self.inbox.pop().clone();
            }
            return;
        }
    }

}