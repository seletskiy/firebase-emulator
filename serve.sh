#!/bin/bash

set -euo pipefail

export server_name=${1:-local.firebaseio.com}
export firebase_port=9000

cd /firebase/

if [[ ! -f nginx.pem || ! -f nginx.crt ]]; then
    echo ":: generating self-signed certificate"

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx.pem -out nginx.crt -subj "/CN=$server_name"
fi

envsubst '$server_name $firebase_port' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf

file=database.json

if [[ ! -f $file ]]; then
    echo "!! no $file file located in $(pwd) dir"
    exit 1
fi

( firebase serve --only database >/dev/null || cat *.log ) &
firebase_pid=$!

( nginx ) &
nginx_pid=$!

echo -n ":: waiting for firebase to start up"

while ! echo >/dev/tcp/localhost/$firebase_port; do
    echo -n .
    sleep 0.1
done 2>/dev/null

echo " ok"

:curl() {
    curl -s -H "Authorization: Bearer owner" \
        localhost:$firebase_port/.json "$@"
}

echo ":: importing $file into firebase"

:curl -XPUT -d@$file > /dev/null

echo ":: ready"

:stop() {
    echo ":: stopping"

    :curl > $file
}

trap :stop INT TERM

wait $firebase_pid $nginx_pid
