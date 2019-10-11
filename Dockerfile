FROM alpine:3.8

RUN apk --no-cache add jq curl ca-certificates

COPY entrypoint.sh /usr/local/bin

ENTRYPOINT ["entrypoint.sh"]

