// import ballerina/websocket;

// # Representation of a user.
// #
// # + name - name of the user
// # + gender - gender of the user
// public type User record {|
//     string name;
//     string gender;
// |};

// # Representation of a basic event.
// #
// # + event - type of event
// # + id - id of the event
// public type ClientData record {|
//     string event;
//     string id;
// |};

// websocket:Caller[] clients = [];

// @websocket:ServiceConfig{dispatcherKey: "event"}
// service / on new websocket:Listener(9091) {

//     # Allows clients to get real-time data on users.
//     # + return - User status
//     resource function get .() returns websocket:Service|websocket:UpgradeError {
//         return new WsService();
//     }
    
// }
        
// service class WsService {
//   *websocket:Service;
//   private map<User> users = {};
// //   remote function onOpen(websocket:Caller caller) returns websocket:Error? {
// //       clients.push(caller);
// //       foreach var webclient in clients {
// //           check webclient->writeTextMessage(string `New user connected with id: ${caller.getConnectionId()}`);
// //       }
// //       io:println(clients);
// //   }

// //   remote function onClose(websocket:Caller caller) returns websocket:Error? {
// //         clients = clients.filter(webclient => webclient.getConnectionId() != caller.getConnectionId());
// //   }

//   remote function onRequest(ClientData clientData) returns User[] {
//         return self.users.toArray();
//   }
  
// }
