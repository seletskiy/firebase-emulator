#!/bin/bash

set -euo pipefail

export firebase_port_database=${FIREBASE_PORT_DATABASE:-9000}
export firebase_port_auth=${FIREBASE_PORT_AUTH:-9099}
export firebase_port_ui=${FIREBASE_PORT_UI:-4000}
export firebase_project_id=${FIREBASE_PROJECT_ID:-demo-project}
export firebase_auth_accounts=${FIREBASE_AUTH_ACCOUNTS:-}

:curl() {
    curl -vs -H "Authorization: Bearer owner" "$@"
}

:curl:accounts() {
    :curl "http://localhost:$firebase_port_auth_proxy/identitytoolkit.googleapis.com/v1/projects/$firebase_project_id/accounts" \
        -HContent-Type:application/json \
        "$@"
}

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

database_support=on

data_dir=emulators.data

(
    firebase emulators:start 2>&1 \
        $([ -d $data_dir ] && echo "--import $data_dir") \
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
:wait:port $firebase_port_auth_proxy
echo ":: ok"

[[ ! -d $data_dir && "$firebase_auth_accounts" ]] && {
    while read entry; do
        [[ ! "$entry" ]] && break
        :curl:accounts -X POST --data-raw "$entry"
    done <<< "$firebase_auth_accounts"
}

echo ":: ready"

:stop() {
    echo
    echo ":: stopping"
    firebase emulators:export --project "$firebase_project_id" -f $data_dir
}

trap :stop INT TERM

wait $firebase_pid $nginx_pid
