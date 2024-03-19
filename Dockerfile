FROM alpine:latest

RUN apk update \
    && apk add --no-cache \
    curl openssl jq

ADD purge.sh /purge.sh

RUN chmod +x /purge.sh

ENTRYPOINT ["/bin/sh", "/purge.sh"]
