#!/bin/sh

set -e 

PORT=$(netstat -lntp | grep python3 | awk '{gsub(".*:","",$4);print $4}')
RESPONSE=$(curl -fsL -w '%{http_code}' -o /dev/null http://localhost:${PORT:-8001})
if [[ "${RESPONSE}x" != "x" ]]; then
    if [[ "${RESPONSE}" == "200" ]]; then
        return 0
    fi
fi

return 1
