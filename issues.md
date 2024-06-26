## Identified issues in websocket
- websocket server cannot return a an open-ended `stream` response and listen to any other requests at the same time from the same client. ie, the server cannot handle multiple requests from the same client at the same time if the first request returns an open-ended `stream` response.

## Identified issues in AsyncAPI client generation
- `dispatcherKey` value for responses are assumed to be the same as the request's return type, which is not always the case
- When `dispatcherStreamId` is a required field, the user needs to provide a dummy value for it before the client replaces it with the actual value. This is not user-friendly. Since the client will automatically replace the dummy value with the actual value, we can make either provide a default value or make it optional.