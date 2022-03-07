A simple example of using `worker_bee` to offload base64 computation to a worker thread.

## Running

On desktop, run `dart bin/example.dart <string to encode>`. On Web, run `webdev build && cd build && dhttpd`<sup>*</sup>.

<sup>*</sup> Only dart2js is currently supported in this example. `webdev serve` will not work.
