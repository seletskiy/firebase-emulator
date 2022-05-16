#!/bin/bash

:curl() {
    mkdir -p $(dirname "$2")
    set -x
    curl -qLH "User-Agent: Firefox 36.0" "$1" -o "$2"
    set +x
}

:curl+() {
    :curl "$1" "$2"

    grep -Po 'url\(\Khttps://[^)]+' "$2" | while read url; do
        filename=$(sed -e 's#https://#/firebase/static/#' <<< "$url")
        :curl "$url" "$filename"
    done
}

:curl 'https://unpkg.com/material-components-web@10/dist/material-components-web.min.js' \
    '/firebase/static/unpkg.com/material-components-web@10/dist/material-components-web.min.js'

:curl 'https://unpkg.com/material-components-web@10/dist/material-components-web.min.css' \
    '/firebase/static/unpkg.com/material-components-web@10/dist/material-components-web.min.css'

:curl 'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg' \
    '/firebase/static/www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg'

:curl+ 'https://fonts.googleapis.com/icon?family=Material+Icons' \
    '/firebase/static/fonts.googleapis.com/material-icons.css'

:curl+ 'https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700' \
    '/firebase/static/fonts.googleapis.com/roboto.css'

:curl 'https://apis.google.com/_/scs/abc-static/_/js/k=gapi.lb.en.iTmf4rxOyWc.O/m=gapi_iframes/rt=j/sv=1/d=1/ed=1/rs=AHpOoo-LTnDn-AS2QlMWYZdnaV1OuFR7Iw/cb=gapi.loaded_0' \
    '/firebase/static/apis.google.com/gapi.js'

:curl 'https://apis.google.com/js/api.js' \
    '/firebase/static/apis.google.com/js/api.js'

:curl 'https://apis.google.com/_/scs/abc-static/_/js/k=gapi.lb.en.iTmf4rxOyWc.O/m=gapi_iframes/rt=j/sv=1/d=1/ed=1/rs=AHpOoo-LTnDn-AS2QlMWYZdnaV1OuFR7Iw/cb=gapi.loaded_0?le=scs' \
    '/firebase/static/apis.google.com/js/gapi.js'
