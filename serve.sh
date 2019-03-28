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

data_file=database.json
rules_file=database.rules.json

if [[ ! -f $data_file ]]; then
    echo "!! no $data_file data_file located in $(pwd) dir"
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
    local path=$1
    shift

    curl -s -H "Authorization: Bearer owner" \
        localhost:$firebase_port/$path "$@"
}

echo ":: importing $data_file into firebase"
:curl ".json" -XPUT -d@$data_file > /dev/null

if [[ -f $rules_file ]]; then
    echo ":: importing rules from $rules_file into firebase"
    :curl ".settings/rules.json" -XPUT -d@$rules_file > /dev/null
fi

echo ":: ready"

:stop() {
    echo ":: stopping"

    :curl ".json" > $data_file
}

trap :stop INT TERM

wait $firebase_pid $nginx_pid
