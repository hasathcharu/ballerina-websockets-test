import ballerina/test;

UserClient baseClient = check new UserClient(serviceUrl = "ws://localhost:9092/user");

@test:Config {}
isolated function  testSubscribe() {
}

@test:Config {}
isolated function  testUnsubscribe() {
}

@test:Config {}
isolated function  testChat() {
}
