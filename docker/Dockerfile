FROM ubuntu:20.04
ARG INSTALL_CPP
ARG INSTALL_TEX

# We do not set DEBIAN_FRONTEND as an 'ENV' because the container will
# evenually be used interactively.
RUN export DEBIAN_FRONTEND=noninteractive; \
    yes | unminimize && \
    apt-get update && \
    apt-get install -y \
        curl \
        htop \
        less \
        locales \
        man \
        software-properties-common \
        sudo \
        tzdata \
        unzip \
        wget \
    && \
    apt-get install -y --no-install-recommends \
        git \
        python \
        python3 \
        python3-distutils \
        python3-pip \
        python3-tabulate \
        python3-yaml \
    && \
    add-apt-repository -y ppa:jonathonf/vim && \
    apt-get install -y --no-install-recommends \
        vim-nox \
        zsh \
    && \
    if [ ! -z ${INSTALL_CPP} ]; then \
        apt-get install -y --no-install-recommends \
            clang-format; \
    fi && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set proper locale like a real system.
RUN export DEBIAN_FRONTEND=noninteractive; \
    sed -i -e "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# Set the timezone.
ARG TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} >/etc/timezone

# Install Dotfiles inside the image, together with a wrapper.
RUN cd /opt && \
    git clone http://github.com/whisperity/Dotfiles-Framework.git \
        --depth 1 \
        --origin upstream \
        Dotfiles \
    && \
    cd ./Dotfiles && \
    ./bootstrap.sh
COPY Dotfiles /usr/local/sbin/Dotfiles
RUN chmod +x /usr/local/sbin/Dotfiles

# Copy some of the helper stuff into the image too.
COPY start-server.sh /usr/local/sbin/start-webserver
RUN chmod +x /usr/local/sbin/start-webserver

# Create a new user that isn't root.
ARG LOCAL_USER="username"
RUN echo "Creating local user ${LOCAL_USER}..." >&2 && \
    useradd -m -s /bin/bash ${LOCAL_USER} && \
    echo "${LOCAL_USER}:password" | chpasswd && \
    usermod -aG sudo ${LOCAL_USER} && \
    echo "${LOCAL_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Allow the webservers run by the inner local user to write the log directory.
RUN mkdir /var/log/httpd && \
    chown ${LOCAL_USER} /var/log/httpd

# Set up the Dotfiles sources inside the image.
RUN mkdir -p /home/${LOCAL_USER}/.config/Dotfiles && \
    chown -R ${LOCAL_USER}:${LOCAL_USER} /home/${LOCAL_USER}/.config && \
    chmod -R 0700 /home/${LOCAL_USER}/.config

COPY sources.yaml /home/${LOCAL_USER}/.config/Dotfiles/sources.yaml
RUN chown ${LOCAL_USER}:${LOCAL_USER} \
        /home/${LOCAL_USER}/.config/Dotfiles/sources.yaml && \
    chmod 0700 /home/${LOCAL_USER}/.config/Dotfiles/sources.yaml

# Need to install Python libraries and a C++ compiler so vim.ycm builds.
# But it is only needed for compiling these, so let's run in a shell for
# root but wrapped in `su`.
#
# The packages not needed for *running* YCM will also be removed, but
# everything else that was installed by Dotfiles shouldn't be.
ENV PATH="/home/${LOCAL_USER}/bin:${PATH}"
ARG GIT_USERNAME="Git User"
ARG GIT_EMAIL="git-user@localhost"
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    su "${LOCAL_USER}" /bin/bash -c 'echo -e "${GIT_USERNAME}\n${GIT_EMAIL}\n" | Dotfiles basic bash githooks tools.fancy vim vim.airline vim.comments vim.fzf vim.git vim.markdown vim.nerdtree vim.polyglot vim.rainbow vim.surround vim.syntastic vim.undo zsh.__ALL__' && \
    if [ ! -z ${INSTALL_TEX} ]; then \
        su "${LOCAL_USER}" /bin/bash -c "Dotfiles texlive vim.tex" && \
        su "${LOCAL_USER}" /bin/bash -c "Dotfiles --uninstall vim.markdown vim.polyglot vim.syntastic"; \
    fi && \
    if [ ! -z ${INSTALL_CPP} ]; then \
        curl -sL http://deb.nodesource.com/setup_12.x | bash - && \
        apt-get install -y nodejs && \
        su "${LOCAL_USER}" /bin/bash -c "Dotfiles gdb vim.clang-format vim.coc"; \
    fi \
    && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Back to the local user's scope and finish setting up.
USER ${LOCAL_USER}
RUN echo "export TZ=${TZ}" >> /home/${LOCAL_USER}/.bashrc && \
    echo "export TZ=${TZ}" >> /home/${LOCAL_USER}/.zshrc

# Use a *login* shell as the entrypoint, we're meant to work actively inside
# the container anyways.
ENTRYPOINT ["/bin/bash", "-l"]
