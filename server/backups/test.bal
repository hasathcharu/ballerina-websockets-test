// import ballerina/websocket;
// import websocket_test.types;

// @websocket:ServiceConfig{dispatcherKey: "event"}
// service /payloadV on new websocket:Listener(8080) {
//     # List all products
//     # + return - List of products
//     resource function get .() returns websocket:Service|websocket:UpgradeError {
//         return new ArrayChatServer();
//     }
// }


// service class ArrayChatServer { 
//     *websocket:Service;
//     private map<types:Product> products = {};

//     remote function onPrice(types:Price price) returns types:Product[] { 
//         return self.products.toArray();
//     }
// }