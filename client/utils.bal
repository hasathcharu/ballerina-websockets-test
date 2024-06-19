import xlibb/pipe;

# PipesMap class to handle generated pipes
public isolated class PipesMap {
    private final map<pipe:Pipe> pipes;

    public isolated function init() {
        self.pipes = {};
    }

    public isolated function addPipe(string id, pipe:Pipe pipe) {
        lock {
            self.pipes[id] = pipe;
        }
    }

    public isolated function getPipe(string id) returns pipe:Pipe {
        lock {
            if (self.pipes.hasKey(id)) {
                return self.pipes.get(id);
            }
            pipe:Pipe pipe = new (1000);
            self.addPipe(id, pipe);
            return pipe;
        }
    }

    public isolated function removePipes() returns error? {
        lock {
            foreach pipe:Pipe pipe in self.pipes {
                check pipe.gracefulClose();
            }
            self.pipes.removeAll();

        }
    }
}

public client isolated class ResponseStreamGenerator {
    *Generator;
    private final pipe:Pipe pipe;
    private final decimal timeout;

    # StreamGenerator
    #
    # + pipe - Pipe to hold stream messages 
    # + timeout - Waiting time 
    public isolated function init(pipe:Pipe pipe, decimal timeout) {
        self.pipe = pipe;
        self.timeout = timeout;
    }

    public isolated function next() returns record {|Response value;|}|error {
        while true {
            anydata|error? message = self.pipe.consume(self.timeout);
            if message is error? {
                continue;
            }
            Response response = check message.cloneWithType();
            return {value: response};
        }
    }

    public isolated function close() returns error? {
        check self.pipe.gracefulClose();
    }
}

public isolated class StreamGeneratorsMap {
    private final Generator[] streamGenerators;

    public isolated function init() {
        self.streamGenerators = [];
    }

    public isolated function addStreamGenerator(Generator streamGenerator) {
        lock {
            self.streamGenerators.push(streamGenerator);
        }
    }

    public isolated function removeStreamGenerators() returns error? {
        lock {
            foreach Generator streamGenerator in self.streamGenerators {
                check streamGenerator.close();
            }
        }
    }
}

public type Generator isolated object {

    public isolated function next() returns record {|anydata value;|}|error?;

    public isolated function close() returns error?;
};
