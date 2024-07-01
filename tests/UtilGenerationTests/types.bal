# Path parameters as a record
#
# + version - Version Id 
# + versionName - Version Name 
public type PathParams record {|
    int version;
    string 'version\-name;
|};

public type Message readonly & record {string 'type;};

public type MessageWithId readonly & record {string 'type; string id;};

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
