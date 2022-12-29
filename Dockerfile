FROM python:3.10.8-slim-bullseye

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt install -y --no-install-recommends wget gnupg ca-certificates dumb-init && \
    pip install atlassian-jwt-auth && \
    mkdir -p /usr/src/app && \
    cd /usr/src/app && \
    mkdir logs && \
    # begin installing openresty
    wget -O - https://openresty.org/package/pubkey.gpg | apt-key add - && \
    codename=`grep -Po 'VERSION="[0-9]+ \(\K[^)]+' /etc/os-release` && \
    echo $codename && \
    echo "deb http://openresty.org/package/debian $codename openresty" \
    | tee /etc/apt/sources.list.d/openresty.list && \
    cat /etc/apt/sources.list.d/openresty.list && \
    apt update && \
    apt install -y openresty

COPY . /usr/src/app
WORKDIR /usr/src/app

CMD ["dumb-init", "/bin/sh", "./entrypoint.sh"]
