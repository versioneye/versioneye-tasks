#!/bin/bash

# Mount your site certificate into
# /usr/local/share/ca-certificates as *.crt file
# if you want to make self signed certificates
# available

sudo update-ca-certificates;

/usr/bin/supervisord -c /etc/supervisord.conf
