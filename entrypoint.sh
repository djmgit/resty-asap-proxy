#!/usr/bin/env bash
#export PYTHONPATH="${PYTHONPATH}:`pwd`/lib/lua-resty-asap/lib/python"
openresty -p `pwd` -c conf/nginx.conf && tail -f logs/http.log
