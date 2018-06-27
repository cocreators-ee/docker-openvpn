#!/bin/sh

TARGET="server.tgz"
SERVER_NAME="Server"

tar -zcvf "${TARGET}" pki/ca.crt pki/issued/* pki/private/${SERVER_NAME}.key pki/crl.pem pki/dh.pem pki/ta.key pki/dh.pem
