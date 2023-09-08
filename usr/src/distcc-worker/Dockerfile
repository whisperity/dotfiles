FROM ubuntu:22.04

# The tiny init should be used to reap the processes in case of a container
# shutdown.
# Pull 'tini' (tiny but valid init script) to the current image so that the
# daemon can be run in the background properly.
COPY --from=krallin/ubuntu-tini:latest /usr/bin/tini /sbin/tini

# (As of 2022. 12. 20.)
# Ubuntu 18.04: GCC 7 , Clang 6.0
# Ubuntu 20.04: GCC 9 , Clang 10.0
# Ubuntu 22.04: GCC 11, Clang 14.0

RUN echo "deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse" >> /etc/apt/sources.list && \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install --yes \
        distcc \
        gcc-7  g++-7   clang-6.0 \
        gcc-9  g++-9   clang-10  \
        gcc-11 g++-11  clang-14  \
    && \
    apt-get install --yes \
        cron \
    && \
    apt-get autoremove --purge --yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY srv/distcc-server /srv/distcc-server
COPY etc/cron.hourly/clear-temp /etc/cron.hourly/clear-temp

RUN chmod +x /srv/distcc-server /sbin/tini && \
    chmod +x /etc/cron.hourly/clear-temp && \
    touch /var/log/cron.log

# DistCC listens on a TCP socket.
EXPOSE 3632/tcp

ENTRYPOINT ["/sbin/tini", "--", "/srv/distcc-server"]
