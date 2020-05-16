FROM auto-schedule_workspace
USER laradock

USER root
COPY cron.sh /etc/my_init.d/11_cron.sh
RUN chmod +x /etc/my_init.d/11_cron.sh
RUN ip -4 route list match 0/0 | awk '{print $3 "host.docker.internal"}' >> /etc/hosts
