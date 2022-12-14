# Build and package the latest NeoVim for us.
FROM ubuntu:20.04 AS neovim_build
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get install -y \
        git \
        liblua5.3-0 \
        liblua5.3-dev \
        luajit \
        libluajit-5.1-dev \
        wget \
    && \
    apt-get install -y \
        autoconf \
        automake \
        build-essential \
        cmake \
        g++ \
        gettext \
        libtool \
        libtool-bin \
        ninja-build \
        pkg-config \
        unzip

ARG __CACHEBREAKER__NEOVIM
RUN mkdir neovim_install && \
    git clone http://github.com/neovim/neovim.git --depth 1 && \
    cd neovim && \
    USERNAME="whisperity/dotfiles" HOSTNAME="docker" \
        make CMAKE_INSTALL_PREFIX="/neovim_install" \
            CMAKE_BUILD_TYPE=RelWithDebInfo && \
    make install


# Build and create the environment image itself.
FROM ubuntu:20.04
ARG INSTALL_CPP
ARG INSTALL_TEX

MAINTAINER "Whisperity <whisperity-packages@protonmail.com>"

# Get our previously built Neovim installed here.
COPY --from=neovim_build /neovim_install "/usr/local/"
RUN update-alternatives --install /usr/bin/vi vi /usr/local/bin/nvim 60 && \
    update-alternatives --config vi && \
    update-alternatives --install /usr/bin/vim vim /usr/local/bin/nvim 60 && \
    update-alternatives --config vim && \
    update-alternatives --install /usr/bin/editor editor /usr/local/bin/nvim 60 && \
    update-alternatives --config editor

# We do not set DEBIAN_FRONTEND as an 'ENV' because the container will
# evenually be used interactively!
RUN export DEBIAN_FRONTEND=noninteractive; \
    yes | unminimize && \
    apt-get update && \
    apt-get install -y \
        curl \
        htop \
        less \
        locales \
        man \
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
    apt-get install -y --no-install-recommends \
        zsh \
    && \
    if [ ! -z ${INSTALL_CPP} ]; then \
        apt-get install -y --no-install-recommends \
            clang-format; \
    fi && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set proper locale like a real system...
RUN export DEBIAN_FRONTEND=noninteractive; \
    sed -i -e "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# Set the timezone.
ARG TZ=Europe/Budapest
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} >/etc/timezone

# Install Dotfiles inside the image, together with a wrapper.
ARG __CACHEBREAKER__DOTFILES_FRAMEWORK
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

# Copy some of the helper stuff into the image too. For example, we might want
# to be able to observe websites (e.g. rendered documentation HTML) from outside
# the container.
COPY start-server.sh /usr/local/sbin/start-webserver
RUN chmod +x /usr/local/sbin/start-webserver

# Create a new user that isn't root, but is able to unconditionally `sudo`.
ARG LOCAL_USER="username"
RUN echo "Creating local user ${LOCAL_USER}..." >&2 && \
    useradd -m -s /bin/bash ${LOCAL_USER} && \
    echo "${LOCAL_USER}:password" | chpasswd && \
    usermod -aG sudo ${LOCAL_USER} && \
    echo "${LOCAL_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chsh --shell "/bin/zsh" ${LOCAL_USER}

# Allow the webservers run by the inner local user to write the log directory.
RUN mkdir /var/log/httpd && \
    chown ${LOCAL_USER} /var/log/httpd

# Set up the Dotfiles sources inside the image.
RUN mkdir -p /home/${LOCAL_USER}/.config/Dotfiles && \
    chown -R ${LOCAL_USER}:${LOCAL_USER} /home/${LOCAL_USER}/.config && \
    chmod -R 0700 /home/${LOCAL_USER}/.config

COPY --chown=${LOCAL_USER}:${LOCAL_USER} sources.yaml /home/${LOCAL_USER}/.config/Dotfiles/sources.yaml
RUN chmod 0700 /home/${LOCAL_USER}/.config/Dotfiles/sources.yaml

ENV PATH="/home/${LOCAL_USER}/bin:${PATH}"
ARG GIT_USERNAME="Git User"
ARG GIT_EMAIL="git-user@localhost"
ARG DOTFILES_USE_SYMLINKS_INSTEAD_OF_COPIES
ARG __CACHEBREAKER__DOTFILES
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    su "${LOCAL_USER}" /bin/bash -c 'echo -e "${GIT_USERNAME}\n${GIT_EMAIL}\n" | Dotfiles ${DOTFILES_USE_SYMLINKS_INSTEAD_OF_COPIES} basic' && \
    su "${LOCAL_USER}" /bin/bash -c 'Dotfiles ${DOTFILES_USE_SYMLINKS_INSTEAD_OF_COPIES} direnv envprobe githooks tools.fancy vim vim.airline vim.comments vim.focus vim.fzf vim.git vim.markdown vim.nerdtree vim.polyglot vim.rainbow vim.surround vim.syntastic vim.undo zsh.__ALL__' && \
    if [ ! -z ${INSTALL_TEX} ]; then \
        su "${LOCAL_USER}" /bin/bash -c "Dotfiles ${DOTFILES_USE_SYMLINKS_INSTEAD_OF_COPIES} texlive vim.tex" && \
        su "${LOCAL_USER}" /bin/bash -c "Dotfiles --uninstall vim.syntastic"; \
    fi && \
    if [ ! -z ${INSTALL_CPP} ]; then \
        curl -sL http://deb.nodesource.com/setup_14.x | bash - && \
        apt-get install -y nodejs && \
        su "${LOCAL_USER}" /bin/bash -c "Dotfiles ${DOTFILES_USE_SYMLINKS_INSTEAD_OF_COPIES} clangd cmake gdb ninja vim.coc vim.vimspector" && \
        su "${LOCAL_USER}" /bin/bash -c "Dotfiles --uninstall vim.nerdtree vim.syntastic"; \
    fi \
    && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Back to the local user's scope and finish setting up.
USER ${LOCAL_USER}
RUN echo "export TZ=${TZ}" >> /home/${LOCAL_USER}/.bashrc && \
    echo "export TZ=${TZ}" >> /home/${LOCAL_USER}/.zshrc

# Use a *login* shell as the entrypoint, as we're meant to work actively inside
# the container anyways.
ENTRYPOINT ["/bin/bash", "-l"]
