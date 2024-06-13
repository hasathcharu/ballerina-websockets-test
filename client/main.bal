import ballerina/io;

UserClient chatClient = check new ();

public function main() returns error? {
    io:println("Hello, World!");
    Response doSubscribe = check chatClient->doSubscribe({"event":"subscribe","name":"Ballerina","gender":"Female"}, 10);
    io:println("Subscribe Response:");
    io:println(doSubscribe);
    Response doChat = check chatClient->doChat({event:"chat", message:"Hello, World!", toUserId: "cc6b1efffe42ea75-0010249f-00000001-99c1dfd842c2d7b3-162c5280"}, 10);
    io:println("Chat Response:");
    io:println(doChat);
    error? close = check chatClient->connectionClose();
}
