public type Ping record {
    string event;
    Reqid reqid?;
};

public type Heartbeat record {
    string event;
};

public type Pong record {
    string event;
    Reqid reqid?;
};

public type SystemStatus record {
    string event;
    # The ID of the connection
    int connectionID?;
    Status status?;
    string version?;
};

public type Status string;

public type Subscribe record {
    string event;
    Reqid reqid?;
    Pair pair?;
    record {Depth depth?; Interval interval?; Name name; Ratecounter ratecounter?; Snapshot snapshot?; Token token?;} subscription?;
};

public type Unsubscribe record {
    string event;
    Reqid reqid?;
    Pair pair?;
    record {Depth depth?; Interval interval?; Name name; Token token?;} subscription?;
};

public type SubscriptionStatus SubscriptionStatusError|SubscriptionStatusSuccess;

public type SubscriptionStatusError record {
    string errorMessage;
    *SubscriptionStatusCommon;
};

public type SubscriptionStatusSuccess record {
    # ChannelID on successful subscription, applicable to public messages only.
    int channelID;
    # Channel Name on successful subscription. For payloads 'ohlc' and 'book', respective interval or depth will be added as suffix.
    string channelName;
    *SubscriptionStatusCommon;
};

public type SubscriptionStatusCommon record {
    string event;
    Reqid reqid?;
    Pair pair?;
    Status status?;
    record {Depth depth?; Interval interval?; Maxratecount maxratecount?; Name name; Token token?;} subscription?;
};

# Time interval associated with ohlc subscription in minutes.
public type Interval int;

# The name of the channel you subscribe too.
public type Name string;

# base64-encoded authentication token for private-data endpoints.
public type Token string;

# Depth associated with book subscription in number of levels each side.
public type Depth int;

# Max rate-limit budget. Compare to the ratecounter field in the openOrders updates to check whether you are approaching the rate limit.
public type Maxratecount int;

# Whether to send rate-limit counter in updates (supported only for openOrders subscriptions)
public type Ratecounter boolean;

# Whether to send historical feed data snapshot upon subscription (supported only for ownTrades subscriptions)
public type Snapshot boolean;

# client originated ID reflected in response message.
public type Reqid int;

# Array of currency pairs.
public type Pair string[];
