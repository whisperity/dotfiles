FROM ubuntu:20.04

ENV USER=root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
        curl \
        htop \
        less \
        locales \
        man \
        sudo \
        tzdata \
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
        unzip \
    && \
    apt-get install -y --no-install-recommends \
        vim \
        zsh \
    && \
    yes | unminimize

# Set proper locale like a real system.
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# Set the timezone.
ARG TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} >/etc/timezone

# Install Dotfiles inside the image.
RUN cd /opt && \
    git clone http://github.com/whisperity/dotfiles.git \
        --depth 1 \
        --origin upstream \
        Dotfiles \
    && \
    cd ./Dotfiles && \
    ./bootstrap.sh
COPY Dotfiles /opt/Dotfiles/Dotfiles
ENV PATH="/opt/Dotfiles:${PATH}"

# Create a new user that isn't root.
ARG LOCAL_USER="username"
RUN echo "Creating local user ${LOCAL_USER}..." >&2 && \
    useradd -m -s /bin/bash ${LOCAL_USER} && \
    echo "${LOCAL_USER}:password" | chpasswd && \
    usermod -aG sudo ${LOCAL_USER} && \
    echo "${LOCAL_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Now run in the context of the new user.
USER ${LOCAL_USER}

# Have some useful tools pre-configured.
ARG GIT_USERNAME="Git User"
ARG GIT_EMAIL="git-user@localhost"
RUN echo "${GIT_USERNAME}\n${GIT_EMAIL}\n" | Dotfiles basic \
        bash \
        tools.fancy \
        vim.__ALL__ \
        zsh.__ALL__

RUN echo "export TZ=${TZ}" >> /home/${LOCAL_USER}/.bashrc && \
    echo "export TZ=${TZ}" >> /home/${LOCAL_USER}/.zshrc

# Use a *login* shell as the entrypoint, we're meant to work actively inside the container anyways.
ENTRYPOINT ["/bin/bash", "-l"]
