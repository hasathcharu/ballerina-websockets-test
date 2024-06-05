// import ballerina/websocket;

// public type SayHello record {|
//     string message;
//     string event;
// |};

// @websocket:ServiceConfig{dispatcherKey: "event"}
// service / on new websocket:Listener(8080) {
//     # Allows clients to get real-time data on users.
//     # + return - User status
//     resource function get .() returns websocket:Service|websocket:UpgradeError {
//         return new WsService();
//     }
    
// }

// service class WsService {
//     *websocket:Service;

//     remote function onHi(SayHello clientData) returns string? {
//         return "Hello, " + clientData.message + "!";
//     }
  
// }
