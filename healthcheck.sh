#!/bin/bash

set -euo pipefail

export firebase_port_ui=${FIREBASE_PORT_UI:-4000}

curl -sf http://localhost:$firebase_port_ui/ > /dev/null
