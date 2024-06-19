# Header parameters as a record
#
public type HeaderParams record {|
    # offset
    int offset;
    # Latitude
    string lat;
    # Longtitude
    string lon;
    # exclude
    string exclude;
    # units description
    int units = 12;
|};

public type Subscribe record {
    string id;
    string event;
};

public type UnSubscribe record {
    string 'type;
    record {} payload?;
    string event;
};
