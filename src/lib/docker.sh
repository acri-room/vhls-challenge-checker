build_docker_image() {
  local dockerfile=$(mktemp)
  cat << 'EOS' > $dockerfile
FROM ubuntu:18.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

# Timezone
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install packages
RUN apt-get update -y && apt-get install -y \
      build-essential \
      bzip2 \
      libc6-i386 \
      git \
      libfontconfig1 \
      libglib2.0-0 \
      sudo \
      nano \
      locales \
      libxext6 \
      libxrender1 \
      libxtst6 \
      libgtk2.0-0 \
      build-essential \
      unzip \
      ruby \
      ruby-dev \
      pkg-config \
      libprotobuf-dev \
      protobuf-compiler \
      python-protobuf \
      python-pip \
      bc \
      time \
      && apt autoclean -y \
      && apt autoremove -y \
      && rm -rf /var/lib/apt/lists/*
EOS

  docker build $* -f $dockerfile .
  rm $dockerfile
}
