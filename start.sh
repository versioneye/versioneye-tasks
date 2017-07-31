#!/bin/bash

sudo update-ca-certificates;

/usr/bin/supervisord -c /etc/supervisord.conf
