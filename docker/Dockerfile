# Download a reasonably new version of `clangd` (will be needed by the Dotfiles script later)
FROM ubuntu:20.04 AS clang_download
ARG INSTALL_YCM
ENV DEBIAN_FRONTEND=noninteractive
RUN if [ ! -z ${INSTALL_YCM} ]; then \
        apt-get update && \
        apt-get install -y \
            wget \
            xz-utils && \
        rm -rf /var/lib/apt/lists/*; \
    fi
RUN if [ ! -z ${INSTALL_YCM} ]; then \
        cd tmp && \
        wget "http://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/clang+llvm-10.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz" -O llvm.tar.xz && \
        tar xJvf llvm.tar.xz && \
        rm llvm.tar.xz && \
        mv "$(ls)" llvm && \
        mv "llvm/bin/clangd" "/opt/clangd" && \
        cd / && \
        rm -rf "/tmp/llvm"; \
    else \
        echo "#!/bin/bash\n" > /opt/clangd \
        echo "\"Clangd was not installed.\" >&2\n" >> /opt/clangd \
        chmod +x /opt/clangd; \
    fi


# Build the real image.
FROM ubuntu:20.04
ARG INSTALL_YCM
ARG INSTALL_TEX

ENV DEBIAN_FRONTEND=noninteractive
RUN yes | unminimize && \
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
            libtinfo5; \
    fi && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set proper locale like a real system.
RUN sed -i -e "s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# Set the timezone.
ARG TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} >/etc/timezone

# Copy over `clangd`.
COPY --from=clang_download /opt/clangd /usr/local/bin/clangd
RUN if [ -z ${INSTALL_YCM} ]; then rm /usr/local/bin/clangd; fi

# Install Dotfiles inside the image.
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

# Have some useful tools pre-configured.
ARG GIT_USERNAME="Git User"
ARG GIT_EMAIL="git-user@localhost"

# Need to install Python libraries and a C++ compiler so vim.ycm builds.
# But it is only needed for these
USER root
ENV PATH="/home/${LOCAL_USER}/bin:${PATH}"
RUN apt-get update && \
    if [ ! -z ${INSTALL_YCM} ]; then \
        apt-get install -y \
            build-essential \
            python3-dev; \
    fi && \
    su "${LOCAL_USER}" /bin/bash -c 'echo -e "${GIT_USERNAME}\n${GIT_EMAIL}\n" | Dotfiles basic bash githooks tools.fancy vim.agsearch vim.airline vim.git vim.lastplace vim.markdown vim.nerdtree vim.rainbow vim.surround vim.syntastic vim.undo vim.unicodeletters zsh.__ALL__' && \
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

USER ${LOCAL_USER}
ENV PATH="/home/${LOCAL_USER}/bin:/opt/Dotfiles:${PATH}"

RUN echo "export TZ=${TZ}" >> /home/${LOCAL_USER}/.bashrc && \
    echo "export TZ=${TZ}" >> /home/${LOCAL_USER}/.zshrc

# Use a *login* shell as the entrypoint, we're meant to work actively inside the container anyways.
ENTRYPOINT ["/bin/bash", "-l"]
