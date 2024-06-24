public type Message readonly & record {string 'type;};

public type MessageWithId readonly & record {string 'type; string id;};

public type Error record {
    string 'type;
};

public type PingMessage record {
    string 'type;
    record {} payload?;
};

public type SubscribeMessage record {
    string id;
    string 'type;
    record {string? operationName?; string query; anydata? variables?; anydata? extensions?;} payload;
};

public type NextMessage record {
    string id;
    string 'type;
    json payload;
};

public type CompleteMessage record {
    string id;
    string 'type;
};

public type ErrorMessage record {
    string id;
    string 'type;
    json payload;
};

public type PongMessage record {
    string 'type;
    record {} payload?;
};

public type ConnectionInitMessage record {
    string 'type;
    record {} payload?;
};

public type ConnectionAckMessage record {
    string 'type;
    record {} payload?;
};
