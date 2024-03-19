#!/bin/sh

set -e

# Check for required inputs and determine authentication method.
if [ -n "$CLOUDFLARE_KEY" ] && [ -n "$CLOUDFLARE_EMAIL" ]; then
    API_METHOD=1
elif [ -n "$CLOUDFLARE_TOKEN" ]; then
    API_METHOD=2
else
    echo "Authentication credentials are not properly set. Please provide either a Global API Key and email or an API Token."
    exit 1
fi

# Ensure the Zone ID is provided.
if [ -z "$CLOUDFLARE_ZONE" ]; then
    echo "CLOUDFLARE_ZONE is required but not set."
    exit 1
fi

# Decide on purging specific URLs or everything.
if [ -n "$PURGE_URLS" ]; then
    PAYLOAD='{"files":'"${PURGE_URLS}"'}'
else
    PAYLOAD='{"purge_everything":true}'
fi

# Execute the appropriate Cloudflare API call based on authentication method.
if [ "$API_METHOD" -eq 1 ]; then
    HTTP_RESPONSE=$(curl -sS -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/purge_cache" \
                        -H "Content-Type: application/json" \
                        -H "X-Auth-Email: ${CLOUDFLARE_EMAIL}" \
                        -H "X-Auth-Key: ${CLOUDFLARE_KEY}" \
                        -d "${PAYLOAD}" \
                        -w "HTTP_STATUS:%{http_code}")
else
    HTTP_RESPONSE=$(curl -sS -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/purge_cache" \
                        -H "Content-Type: application/json" \
                        -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
                        -d "${PAYLOAD}" \
                        -w "HTTP_STATUS:%{http_code}")
fi

# Extract and process the response body and HTTP status.
HTTP_BODY=$(echo "${HTTP_RESPONSE}" | sed -E 's/HTTP_STATUS\:[0-9]{3}$//')
HTTP_STATUS=$(echo "${HTTP_RESPONSE}" | tr -d '\n' | sed -E 's/.*HTTP_STATUS:([0-9]{3})$/\1/')

# Parse JSON response using jq for a more detailed output.
SUCCESS=$(echo "${HTTP_BODY}" | jq -r '.success')

if [ "$SUCCESS" = "true" ]; then
    echo "Cache purge successful!"
    exit 0
else
    ERROR_MSG=$(echo "${HTTP_BODY}" | jq -r '.errors[] | .message')
    echo "Purge failed with HTTP status ${HTTP_STATUS}: ${ERROR_MSG}"
    exit 1
fi
