#!/bin/bash

if [ ! -f /etc/stunnel/pki/cert.pem ]; then
    openssl genrsa -out /etc/stunnel/pki/key.pem 2048
    openssl req -new -x509 -key /etc/stunnel/pki/key.pem -out /etc/stunnel/pki/cert.pem -days 1095 -subj "/C=XX/CN=cpitman.github.io"
fi

if [ -z CONNECT_PORT ]; then
    sed -i -e "s/5001/${CONNECT_PORT}/" /etc/stunnel/config/config
fi

stunnel /etc/stunnel/config/config