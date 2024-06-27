public type Message readonly & record {string event;};

public type MessageWithId readonly & record {string event; string id;};

# Representation of a subscription.
public type Subscribe record {
    # type of event
    string event;
    # name of the user
    string name;
    # gender of the user
    string gender;
    // # dispathcharStreamId of the message
    // string id;
};

# Representation of a response
public type Response record {
    # dispatcher key
    string event;
    # message to be sent
    string message;
    # dispathcharStreamId of the message
    string id;
};

# Representation of an unsubscribe message.
public type Unsubscribe record {
    # dispatcher key
    string event;
    # dispathcharStreamId of the message
    string id;
};

# Repersentation of a message.
public type Chat record {
    # message to be sent  
    string message;
    # dispatcher key
    string event;
    # user id to send the message
    string toUserId;
    # dispathcharStreamId of the message
    string id;
};
