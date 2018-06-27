#!/bin/sh
set -e

CLIENT="$1"

shift
EXTRA="${@}"

if [ -z "${CLIENT}" ]; then
  echo "Usage: ./$0 <client-name> [nopass]"
  exit 1
fi

./easyrsa gen-req "${CLIENT}" $EXTRA
./easyrsa sign-req client "${CLIENT}"

cat client.conf | tail -n +1 > "${CLIENT}.ovpn"
echo -e "<ca>\n" >> "${CLIENT}.ovpn"
cat ./pki/ca.crt >> "${CLIENT}.ovpn"
echo -e "\n</ca>" >> "${CLIENT}.ovpn"

echo -e "<cert>\n" >> "${CLIENT}.ovpn"
cat "./pki/issued/${CLIENT}.crt" >> "${CLIENT}.ovpn"
echo -e "\n</cert>" >> "${CLIENT}.ovpn"

echo -e "<key>\n" >> "${CLIENT}.ovpn"
cat "./pki/private/${CLIENT}.key" >> "${CLIENT}.ovpn"
echo -e "\n</key>" >> "${CLIENT}.ovpn"

echo -e "<tls-auth>\n" >> "${CLIENT}.ovpn"
cat ./pki/ta.key >> "${CLIENT}.ovpn"
echo -e "\n</tls-auth>" >> "${CLIENT}.ovpn"

echo
echo
echo
echo "Generated ${CLIENT}.ovpn"
echo
echo
echo "Determining Docker ID..."
ID=$(cat /proc/self/cgroup | head -n1 | cut -d/ -f 3 | cut -c1-12)
echo
echo "To copy configuration off the container run this on the host:"
echo
echo "  docker cp ${ID}:/etc/openvpn/${CLIENT}.ovpn ."
echo
echo
echo
