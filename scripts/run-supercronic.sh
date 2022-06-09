#!/bin/sh
gomplate -f "/etc/supercronic/crontab.tmpl" -o "/etc/supercronic/crontab" --verbose
exec supercronic /etc/supercronic/crontab