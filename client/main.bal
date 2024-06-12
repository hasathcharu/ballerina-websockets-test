import ballerina/io;

UserClient chatClient = check new ();

public function main() returns error? {
    io:println("Hello, World!");
    Response doSubscribe = check chatClient->doSubscribe({"event":"subscribe","name":"Ballerina","gender":"Female"}, 5);
    io:println("Response:");
    io:println(doSubscribe);
}
