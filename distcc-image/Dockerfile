FROM ubuntu:18.04

RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install --yes \
        clang \
        distcc \
        gcc \
        g++ \
    && \
    apt-get install --yes \
        cron \
    && \
    apt-get autoremove --purge --yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY start-distcc.sh /bin/start-distcc.sh
COPY cleartemp.sh /etc/cron.hourly/cleartemp

RUN chmod +x /bin/start-distcc.sh && \
    chmod +x /etc/cron.hourly/cleartemp && \
    touch /var/log/cron.log

# DistCC listens on a TCP socket.
EXPOSE 3632/tcp

# The tiny init should be used to reap the processes in case of a container
# shutdown.
# Pull 'tini' (tiny but valid init script) to the current image so that the
# daemon can be run in the background properly.
COPY --from=krallin/ubuntu-tini:latest /usr/bin/tini /sbin/tini
ENTRYPOINT ["/sbin/tini", "--", "/bin/start-distcc.sh"]

