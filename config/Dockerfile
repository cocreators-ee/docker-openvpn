FROM alpine:3.7
ARG OVPN_VERSION=2.4.4-r1

RUN apk add --update openvpn=${OVPN_VERSION}
RUN apk add easy-rsa
RUN rm -rf /var/cache/apk/*
RUN mkdir -p /etc/openvpn/keys
RUN mkdir -p /etc/openvpn/ssl
RUN cp -a /usr/share/easy-rsa/* /etc/openvpn

ADD . /etc/openvpn
RUN chmod +x /etc/openvpn/easyrsa
RUN chmod +x /etc/openvpn/package-server.sh
RUN chmod +x /etc/openvpn/gen-client.sh

WORKDIR /etc/openvpn
CMD ["/bin/sh"]
