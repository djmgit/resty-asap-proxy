# resty-asap-proxy

resty-asap-proxy is a openresty based proxy which can generate asap tokens on the fly and inject them as headers into a request in order to
auth with a asap authenticated service. This can be used as a middle man when a service which does not know/use asap needs to communnicate with
a service that uses asap as its primary auth framework. The upstream service must allow/whitelist the proxy and its asap issuer.
It goes without saying that the when using such a middle man proxy, the upstream service must have a way to verify the client service at application
level to make sure the client is trusted.

## What is ASAP?

ASAP stands for Atlassian service to service authentication Protocol, a mechanism used by a resource server to authenticate requests from the
client in a client-server communication scenario between software services. Its based on JWT. You can read the full specification <a href="https://s2sauth.bitbucket.io/spec/">here</a>.

## What is Openresty?

Openresty is a server platform based on top of Nginx and comes bundled nginx-lua module. With Openresty you get the power of lua scripting with
nginx out of the box. You can find more about it <a href="https://openresty.org/en/">here</a>.

## Getting started

resty-asap-proxy can be run directly on your system using openresty or via docker. I assume that you have already generated your asap keys. The public
key has been uploaded to the key server and the key and issuer is trusted by the upstream service. The private key will be used by the proxy
server to auth with the upstream service. Also the instructions are for Linux and MacOS, I have not tried running it on Windows, but it should
not be much different.

### Running resty-asap-proxy on system without docker

- First you need to make sure you have openresty installed on your system. You follow the instructions given on their official <a href="https://openresty.org/en/">site</a>.

- Clone this repo and open it in your terminal.

- Export your asap issuer - ```export ASAP_ISSUER=<your asap issuer>```. This is a issuer trusted by your targeted upstream service.
- Export your asap private key - ```export ASAP_PRIVATE_KEY=<the asap private key>```.

- Create a directory for logs named logs using ```mkdir logs```. Nginx conf is configured to dump http access logs and error into logs/http.log.
  You can modify the conf file if you want.
  
- Now you can run the server using ```openresty -p `pwd`/ -c conf/nginx.conf```. Additionally you can do a ```tail -f logs/http.log``` to keep
  a watch on the logs.
  
- The proxy should be running on port 8080.

### Running via Docker

- Make sure you have Docker installed on your system.

- Clone this repo and open it in your terminal.

- Build the docker image using ```docker build -t resty-asap-proxy:v1 .```

- Create and run the container using ```docker run -p 8080:8080 -e ASAP_ISSUER=<asap issuer> -e ASAP_PRIVATE_KEY=<asap private key> resty-asap-proxy:v1```

- The proxy should be runing on port 8080. The access and error logs will be streamed to stdout.

## Sending requests to upstream services using resty-asap-proxy

The proxy server expects you to send requests in a specific format. This format makes sure that the proxy is able to extract target service host, the
target uri and the desired asap issuer form the request itself and generate the asap token.
The request format is -

```http://127.0.0.1:8080/proxy/upstream_service_host/remaining_uri```

In short the uri should begin with **/proxy** then the upstream service host (fqdn) then the uri for the upstream host and url params if any.

Exmaple:
```http://127.0.0.1:8080/proxy/myservice.mycompany.com/api/home/1```

If we use the above request url, resty-asap-proxy will use myservice.mycompany.com as the upstream service host, /api/home/1 as the target uri and
asap_issuer as ```myservice``` that is the frist part of the domain or the service name.

## How does resty-asap-proxy work?

Request flow:
