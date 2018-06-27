FROM alpine:3.7

ARG OVPN_VERSION=2.4.4-r1

WORKDIR /vol/openvpn

# Install OpenVPN
RUN apk add --update openvpn=${OVPN_VERSION} iptables && rm -rf /var/cache/apk/*
RUN mkdir -p /vol/openvpn

# Copy configuration
ADD openvpn.conf /vol/openvpn/openvpn.conf
COPY config/server.tgz /vol/openvpn/
COPY run-openvpn.sh /vol/openvpn/
RUN chmod +x run-openvpn.sh

RUN tar -zxvf server.tgz && rm server.tgz

# Configuration to launch the server
CMD ["./run-openvpn.sh"]
EXPOSE 1194/udp
