FROM series_php-fpm
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY supervisord.conf /etc/supervisord.conf
COPY supervisord.d /etc/supervisord.d/

ENTRYPOINT "/entrypoint.sh"

