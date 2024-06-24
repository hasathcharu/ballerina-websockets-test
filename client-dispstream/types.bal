public type Message readonly & record {string event;};

# Representation of a subscription.
public type Subscribe record {
    # type of event
    string event;
    # name of the user
    string name;
    # gender of the user
    string gender;
};

# Representation of a response
public type Response record {
    # dispatcher key
    string event;
    # message to be sent
    string message;
};

# Representation of an unsubscribe message.
public type Unsubscribe record {
    # dispatcher key
    string event;
};

# Repersentation of a message.
public type Chat record {
    # message to be sent  
    string message;
    # dispatcher key
    string event;
    # user id to send the message
    string toUserId;
};
