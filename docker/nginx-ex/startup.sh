#!/bin/bash

# Start crond in background
crond -l 2 -b

if [ -z ${PHP_UPSTREAM+x} ]; then echo "PHP_UPSTREAM is unset"; else echo "upstream php-upstream { server ${PHP_UPSTREAM}; }" > /etc/nginx/conf.d/upstream.conf ; fi

# Start nginx in foreground
nginx


