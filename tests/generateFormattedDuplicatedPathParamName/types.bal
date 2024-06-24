# Path parameters as a record
#
# + version - Version Id 
# + versionName - Version Name 
public type PathParams record {|
    int version;
    string 'version\-name;
|};

public type Message readonly & record {string event;};

public type MessageWithId readonly & record {string event; string id;};

public type Subscribe record {
    string id;
    string event;
};

public type UnSubscribe record {
    string 'type;
    record {} payload?;
    string event;
};
