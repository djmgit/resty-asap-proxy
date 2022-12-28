FROM python:3.10.8-slim-bullseye

#ENV VIRTUAL_ENV=/opt/venv
#ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt install -y --no-install-recommends wget gnupg ca-certificates dumb-init && \
    #python3 -m venv $VIRTUAL_ENV && \
    pip install atlassian-jwt-auth && \
    mkdir -p /usr/src/app && \
    cd /usr/src/app && \
    mkdir logs && \
    # begin installing openresty
    wget -O - https://openresty.org/package/pubkey.gpg | apt-key add - && \
    codename=`grep -Po 'VERSION="[0-9]+ \(\K[^)]+' /etc/os-release` && \
    echo "******************" && \
    echo $codename && \
    echo "deb http://openresty.org/package/debian $codename openresty" \
    | tee /etc/apt/sources.list.d/openresty.list && \
    echo "******************" && \
    cat /etc/apt/sources.list.d/openresty.list && \
    apt update && \
    apt install -y openresty

COPY . /usr/src/app
WORKDIR /usr/src/app
#ENV PYTHONPATH="/usr/src/app/lib/lua-resty-asap/lib/python"


CMD ["dumb-init", "/bin/sh", "./entrypoint.sh"]
