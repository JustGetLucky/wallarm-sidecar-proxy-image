#!/bin/sh
/usr/local/run-addnode.sh
exec supervisord -c /etc/supervisor/supervisord.node.conf