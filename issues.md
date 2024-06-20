## Identified issues in workers
- `default` worker doesn't return until all other workers are done.

## Identified issues in websocket
- websocket server stops responding (need to investigate)
- websocket server cannot return a an open-ended `stream` response and listen to any other requests at the same time from the same client. ie, the server cannot handle multiple requests from the same client at the same time if the first request returns an open-ended `stream` response.

## Identified issues in AsyncAPI client generation
- `dispatcherKey` value for responses are assumed to be the same as the request's return type, which is not always the case
- Unused pipes should be removed from the `pipes` map