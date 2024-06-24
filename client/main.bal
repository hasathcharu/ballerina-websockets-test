import ballerina/io;

UserClient chatClient = check new ();

public function main() returns error? {
    // io:println("Hello, World!");
    stream<Response,error?> subscription = check chatClient->doSubscribe({"event":"subscribe","name":"Ballerina","gender":"Female"}, 10);
    while true {
        record {|Response value;|}|error? message = check subscription.next();
        if message !is error? {
            io:println(message.value);
        } else if message is error {
            io:println("Error occurred: " + message.message());
        } else {
            io:println("NILL");
        }
    }
    // io:println("Subscribe Response:");
    // io:println(doSubscribe);
    // Response doChat = check chatClient->doChat({event:"chat", message:"Hello, World!", toUserId: "cc6b1efffe42ea75-0010249f-00000001-99c1dfd842c2d7b3-162c5280"}, 10);
    // io:println("Chat Response:");
    // io:println(doChat);
    // error? close = check chatClient->connectionClose();


    // websocket:Client wsClient = check new ("ws://localhost:9092/user");
    // check wsClient->writeMessage({"event":"subscribe","name":"Ballerina","gender":"Female"});
    // while true {
    //     stream<Message|error?>? message = check wsClient->readMessage();
    //     io:println("Received message: " + message.next().toString());
    // }


}
