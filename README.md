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
server to auth with the upstream service. The proxy assumes that the upstream server uses tls and uses [https] to forward. This can be changed in
the conf file.
Also the instructions are for Linux and MacOS, I have not tried running it on Windows, but it should
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
asap audience as ```myservice``` that is the frist part of the domain or the service name. So basically the proxy will initiate a new request to
```https://myservice.mycompany.com/api/home/1``` with the generated asap token in header.

## How does resty-asap-proxy work?

Request flow:

![Unable to load request flow image](resources/resty-asap.jpg?raw=true "Request flow")

I will use the request url ```http://127.0.0.1:8080/proxy/myservice.mycompany.com/api/home/1``` for running through the request flow.

- On receiving the request, resty-asap-proxy will execute the lua-resty-asap module lua script by calling the desired module function.

- The lua script will capture the request_uri and will extract the following things from it:
    - the upstream service host name - myservice.mycompany.com
    - The upstream service uri - /api/home/1
    - The asap audience which is basically the first part of the host name (pqdn) as of now - myservice

- The lua script then invokes a python script which uses ```asap-authentication-python``` library to generate the asap token. The required asap private
  key, asap issuer and audience is passed to the py script from lua via stdin. The lua script itself gets the asap issuer and asap private key from env
  vars.
 
- The py script sends the generated asap token to stdout.

- The lua script reads the asap token from the stdout and injects it as the ```Authorization``` header in the request.

- It is to be noted that the lua-resty-asap lua module uses the shell module provided by openresty to invoke the py script via non blocking IO.

- Next the lua script populates the predefined nginx var ```target_host``` with the extracted upstream service host name. This var is used by
  proxy_pass as the remote host. This is how we are able to dynamically decide the upstream service host per request on the fly. The target
  service can be anything and the request will be accordingly proxied with correct asap token.
  
- Lastly the lua module sets the uri to the extracted target uri - ```/api/home/1```

- Nginx finally will forward the request with proper uri to the desired target host via proxy_pass. The final outgoing request will be
  ```https://myservice.mycompany.com/api/home/1```


## NOTES

- The lua-resty-asap module can be extracted from this repo and used with any openresty configuration.

- Right now the proxy considers the upstream service name as the asap audience. The proxy needs a way to override this.

- It always assumes the upstream service is behind tls.

- The nginx conf is very minimalistic, it does not use server names etc. Thats done intentionally, please edit the conf as required. My primary focus
  was the lua module.
