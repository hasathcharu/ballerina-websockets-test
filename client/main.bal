import ballerina/io;
import ballerina/lang.runtime;

UserClient chatClient = check new ();

public function main() returns error? {
        worker subscribe returns error? {
        io:println("Subscribing to the chat service");
        stream<Response,error?> subscription = check chatClient->doSubscribe({"event":"subscribe","name":"Ballerina","gender":"Female"}, 10);
        while true {
            record {|Response value;|}|error? message = subscription.next();
            if message !is error? {
                io:println(message.value);
            } else if message is error {
                io:println("Error occurred at worker: " + message.message());
            } else {
                io:println("NILL");
            }
        }
    } 
    runtime:sleep(5);
    io:print("Enter your message: ");
    string message = io:readln();
    io:print("Enter to whom you want to send the message: ");
    string toUser = io:readln();
    Response|error response = chatClient->doChat({"event":"chat","message":message, "toUserId": toUser}, 10);
    if response is error {
        io:println("Error occurred: " + response.message());
    }
    io:println("RESPONSE: ", response);
    check wait subscribe;

}
