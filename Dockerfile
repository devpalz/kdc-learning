FROM alpine:latest

RUN apk add krb5-libs krb5-server krb5 gettext
COPY default.krb5.conf /tmp/
COPY default.kdc.conf /tmp/

COPY init.sh /

RUN chmod 775 init.sh

ENTRYPOINT ["./init.sh"]