if [ -z ${START_HORIZON_INSTEAD_OF_FPM+x} ];then
    echo "starting FPM"
    php-fpm
else
    echo "starting HORIZON"
    while [ ! -f /var/www/vendor/autoload.php ]
    do
        echo "waiting installing components via composer"
      sleep 2
    done
    /usr/bin/supervisord -n -c /etc/supervisord.conf
fi