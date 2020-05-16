COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY supervisord.conf /etc/supervisord.conf
COPY supervisord.d /etc/supervisord.d/
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

ENTRYPOINT "/entrypoint.sh"

