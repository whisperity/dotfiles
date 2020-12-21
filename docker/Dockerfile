FROM ubuntu:20.04

ENV USER=root

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
        curl \
        htop \
        less \
        locales \
        sudo \
        tzdata \
        wget \
    && \
    apt-get install -y --no-install-recommends \
        git \
        python \
        python3 \
        python3-distutils \
        python3-tabulate \
        python3-yaml \
        unzip \
    && \
    apt-get install -y --no-install-recommends \
        vim \
        zsh

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

ENV TZ=Europe/Budapest
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ >/etc/timezone

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

ARG GIT_USERNAME="Git User"
ARG GIT_EMAIL="git-user@localhost"
RUN echo "$GIT_USERNAME\n$GIT_EMAIL\n" | Dotfiles basic \
        bash \
        tools.fancy \
        vim.__ALL__ \
        zsh.__ALL__

