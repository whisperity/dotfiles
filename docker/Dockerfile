FROM ubuntu:20.04
ARG INSTALL_YCM
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
        vim-nox \
        zsh \
    && \
    if [ ! -z ${INSTALL_YCM} ]; then \
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
    git clone http://github.com/whisperity/dotfiles.git \
        --depth 1 \
        --origin upstream \
        Dotfiles \
    && \
    cd ./Dotfiles && \
    ./bootstrap.sh
COPY Dotfiles /usr/local/sbin/Dotfiles
RUN chmod +x /usr/local/sbin/Dotfiles

# Create a new user that isn't root.
ARG LOCAL_USER="username"
RUN echo "Creating local user ${LOCAL_USER}..." >&2 && \
    useradd -m -s /bin/bash ${LOCAL_USER} && \
    echo "${LOCAL_USER}:password" | chpasswd && \
    usermod -aG sudo ${LOCAL_USER} && \
    echo "${LOCAL_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Need to install Python libraries and a C++ compiler so vim.ycm builds.
# But it is only needed for compiling these, so let's run in a shell for
# root but wrapped in `su`.
#
# The packages not needed for *running* YCM will also be removed, but
# everything else that was installed by Dotfiles shouldn't be.
USER root
ENV PATH="/home/${LOCAL_USER}/bin:${PATH}"
ARG GIT_USERNAME="Git User"
ARG GIT_EMAIL="git-user@localhost"
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    if [ ! -z ${INSTALL_YCM} ]; then \
        apt-get install -y \
            build-essential \
            python3-dev; \
    fi && \
    su "${LOCAL_USER}" /bin/bash -c 'echo -e "${GIT_USERNAME}\n${GIT_EMAIL}\n" | Dotfiles basic bash githooks tools.fancy vim.agsearch vim.airline vim.git vim.indentline vim.lastplace vim.markdown vim.nerdtree vim.rainbow vim.surround vim.syntastic vim.undo zsh.__ALL__' && \
    if [ ! -z ${INSTALL_TEX} ]; then \
        su "${LOCAL_USER}" /bin/bash -c "Dotfiles texlive vim.tex"; \
    fi && \
    if [ ! -z ${INSTALL_YCM} ]; then \
        su "${LOCAL_USER}" /bin/bash -c "Dotfiles vim.clang-format vim.ycm" && \
        apt-get purge -y \
            build-essential \
            python3-dev; \
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
