#!/bin/sh
SCRIPT_PATH=/opt/wallarm/ruby/usr/share/wallarm-common
${SCRIPT_PATH}/synccloud --one-time -l STDOUT
${SCRIPT_PATH}/sync-ip-lists --one-time -l STDOUT
${SCRIPT_PATH}/sync-ip-lists-source --one-time -l STDOUT
${SCRIPT_PATH}/export-environment -l STDOUT