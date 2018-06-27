#!/bin/sh

VPN_CIDR="172.27.124.0/24"

setup_iptables() {
  # Flushing all rules
  iptables -F FORWARD
  iptables -F INPUT
  iptables -F OUTPUT
  iptables -X

  # Setting default filter policy
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT ACCEPT

  # Allow loopback
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT

  # Accept inbound TCP packets
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

  # Allow incoming OpenVPN
  iptables -A INPUT -p udp --dport 1194 -m state --state NEW -s 0.0.0.0/0 -j ACCEPT

  # Enable NAT for the VPN
  iptables -t nat -A POSTROUTING -s "${VPN_CIDR}" -o eth0 -j MASQUERADE

  # Allow TUN interface connections to OpenVPN server
  iptables -A INPUT -i tun0 -j ACCEPT

  # Allow TUN interface connections to be forwarded through other interfaces
  iptables -A FORWARD -i tun0 -j ACCEPT
  iptables -A OUTPUT -o tun0 -j ACCEPT
  iptables -A FORWARD -i tun0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A FORWARD -i eth0 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT

  # Allow outbound access to all networks on the Internet from the VPN
  iptables -A FORWARD -i tun0 -s "${VPN_CIDR}" -d 0.0.0.0/0 -j ACCEPT
}

disable_ipv6() {
  cat >> /etc/sysctl.d/99-disable-ipv6.conf <<END
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.eth0.disable_ipv6 = 1
END
  sysctl -p
}

setup_devices() {
  modprobe tun

  mkdir -p /dev/net
  if [ ! -c /dev/net/tun ]; then
      mknod /dev/net/tun c 10 200
  fi

}

setup_iptables
disable_ipv6
setup_devices

openvpn --config /vol/openvpn/openvpn.conf \
  --remap-usr1 SIGTERM \
  --script-security 2 \
  --up /etc/openvpn/up.sh \
  --down /etc/openvpn/down.sh
