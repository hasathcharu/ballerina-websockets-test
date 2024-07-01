import ballerina/io;
import ballerina/uuid;

UserClient chatClient = check new ();

public function main() returns error? {
    worker subscribe returns error? {
        io:println("Subscribing to the chat service");
        stream<Response,error?> subscription = check chatClient->doSubscribe({"event":"subscribe","name":"Ballerina","gender":"Female", "id":uuid:createType1AsString()}, 10);
        // the server will send two responses to the subscription request immediately
        printSingleResponse(subscription);
        printSingleResponse(subscription);
        //to notify the subscription is done
        true ->> function;
        while true {
            printSingleResponse(subscription);
        }
    }
    boolean waitForSubscribe = check <- subscribe;
    if waitForSubscribe is true {
        io:print("Enter your message: ");
        string message = io:readln();
        io:print("Enter to whom you want to send the message: ");
        string toUser = io:readln();
        Response|error response = chatClient->doChat({"event":"chat","message":message, "toUserId": toUser, "id":uuid:createType1AsString()}, 10);
        if response is error {
            io:println("Error occurred: " + response.message());
        }
        io:println("RESPONSE: ", response);
    }
    check wait subscribe;
}

function printSingleResponse(stream<Response,error?> subscription) {
    record {|Response value;|}|error? message = subscription.next();
    if message !is error? {
        io:println(message.value);
    } else if message is error {
        io:println("Error occurred at worker: " + message.message());
    } else {
        io:println("NILL");
    }
}
