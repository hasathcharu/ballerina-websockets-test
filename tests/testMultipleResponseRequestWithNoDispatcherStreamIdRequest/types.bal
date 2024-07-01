public type Message readonly & record {string event;};

public type Subscribe record {
    string id;
    string event;
};

public type UnSubscribe record {
    string 'type;
    record {} payload?;
    string event;
};

public type Request record {
    string id;
    string event;
};

public type Response record {
    string 'type;
    record {} payload?;
    string event;
};
