This is an application which I use as demo when testing k8s deployments of gogatekeeper and oauth2-proxy

    ./bin/http-echo [<port>]

Default port value is 8080

Metrics for prometheus are exposed on the route /metrics

Requests to route / are responded by simple page showing HTTP request type and the list of HTTP headers