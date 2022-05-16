#!/bin/bash

set -euo pipefail

export firebase_port_database=${FIREBASE_PORT_DATABASE:-9000}
export firebase_port_auth=${FIREBASE_PORT_AUTH:-9099}
export firebase_port_ui=${FIREBASE_PORT_UI:-4000}
export firebase_project_id=${FIREBASE_PROJECT_ID:-demo-project}

cd /firebase/

export firebase_port_auth_proxy=$(( $firebase_port_auth + 100 ))

cat > firebase.json <<JSON
{
    "emulators": {
        "database": {
            "host": "0.0.0.0",
            "port": $firebase_port_database
        },
        "auth": {
            "host": "0.0.0.0",
            "port": $firebase_port_auth_proxy
        },
        "ui": {
            "enabled": true,
            "host": "0.0.0.0",
            "port": $firebase_port_ui
        }
    }
}
JSON

data_file=database.json
rules_file=database.rules.json

database_support=on
if [[ ! -f $data_file ]]; then
    echo "!! no $data_file data file located in $(pwd) dir"
    echo "!! database emulaator will be disabled"

    database_support=
fi

(
    firebase emulators:start 2>&1 \
        --project "$firebase_project_id" \
        --only auth${database_support:+,database} \
            | sed -ur 's/^/:: [firebase] /'
) &
firebase_pid=$!

envsubst '$firebase_port_auth $firebase_port_auth_proxy' \
    < /etc/nginx/nginx.conf.template \
    > /etc/nginx/nginx.conf

( nginx | sed -ur 's/^/:: [nginx] /' ) &
nginx_pid=$!

:wait:port() {
    while ! echo >/dev/tcp/localhost/$1; do
        sleep 0.1
    done 2>/dev/null
}

[[ "$database_support" ]] &&
    echo ":: waiting for firebase to start up — database" &&
    :wait:port $firebase_port_database &&
    echo ":: ok"

echo ":: waiting for firebase to start up — auth"
:wait:port $firebase_port_auth
echo ":: ok"

:curl() {
    local path=$1
    shift

    curl -s -H "Authorization: Bearer owner" \
        localhost:$firebase_port_database/$path "$@"
}

[[ "$database_support" ]] &&
    echo ":: importing $data_file into firebase" &&
    :curl ".json" -XPUT -d@$data_file > /dev/null

[[ "$database_support" && -f $rules_file ]] &&
    echo ":: importing rules from $rules_file into firebase" &&
    :curl ".settings/rules.json" -XPUT -d@$rules_file > /dev/null

echo ":: ready"

:stop() {
    echo
    echo ":: stopping"

    [[ "$database_support" ]] &&
        :curl ".json" > $data_file
}

trap :stop INT TERM

wait $firebase_pid $nginx_pid
