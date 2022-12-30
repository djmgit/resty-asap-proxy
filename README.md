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
