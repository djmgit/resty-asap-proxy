#!/usr/bin/env bash
openresty -p `pwd` -c conf/nginx.conf && tail -f logs/http.log
