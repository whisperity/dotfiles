Custom tools to install manually
================================

There are some tools that are not installed automatically on Ubuntu 16.04 LTS
systems. These packages are described here.

Installed from package manager
------------------------------

    sudo apt-get install --no-install-recommends \
        cpufreq-utils \
        htop \
        iotop \
        smartmontools \
        tree

To be installed manually
------------------------

### Alternative `find`: `fd`

To be downloaded and manually installed with `dpkg --install` from here:
[https://github.com/sharkdp/fd](https://github.com/sharkdp/fd).