FROM ubuntu:18.04
LABEL maintainer="Lucas de Souza"
# Based on https://github.com/yorickvanzweeden/android-ci

# Variables taken from variables.env
ARG AVD_NAME
ARG ANDROID_HOME
ARG VERSION_COMPILE_VERSION
ARG VERSION_SDK_TOOLS

# Expect requires tzdata, which requires a timezone specified
RUN ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

RUN apt-get -qq update && \
      apt-get install -qqy --no-install-recommends \
      locales \
      bridge-utils \
      bzip2 \
      curl \
      wget \
      # expect: Passing commands to telnet
      expect \
      git-core \
      html2text \
      lib32gcc1 \
      lib32ncurses5 \
      lib32stdc++6 \
      lib32z1 \
      libc6-i386 \
      libqt5svg5 \
      libqt5widgets5 \
      # libvirt-bin: Virtualisation for emulator
      libvirt-bin \
      openjdk-8-jdk \
      # qemu-kvm: Hardware acceleration for emulator
      qemu-kvm \
      # telnet: Communicating with emulator
      telnet \
      # ubuntu-vm-builder: Building VM for emulator
      ubuntu-vm-builder \
      unzip \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN locale-gen "en_US.UTF-8" && \
    update-locale LC_ALL="en_US.UTF-8"

# Configurating Java
RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

# Downloading SDK-tools (AVDManager, SDKManager, etc)
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget --output-document=/sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_SDK_TOOLS}_latest.zip && \
    unzip /sdk.zip -d ${ANDROID_HOME}/cmdline-tools && \
    rm -v /sdk.zip

ENV PATH /$ANDROID_HOME/cmdline-tools/tools/bin:$PATH

RUN echo yes | sdkmanager --licenses

RUN mkdir -p /root/.android && \
    touch /root/.android/repositories.cfg

# Download packages
ADD packages.txt ${ANDROID_HOME}
RUN sdkmanager --update
RUN sdkmanager --package_file=${ANDROID_HOME}/packages.txt

# Download system image for compiled version (separate statement for build cache)
RUN echo y | sdkmanager "system-images;android-${VERSION_COMPILE_VERSION};google_apis;x86_64"

RUN rm -rf /etc/ssl/certs/NetLock_Arany* && \
    rm -rf /usr/share/ca-certificates/mozilla/NetLock_Arany*

# Create AVD
RUN mkdir ~/.android/avd  && \
      echo no | avdmanager create avd -n ${AVD_NAME} -k "system-images;android-${VERSION_COMPILE_VERSION};google_apis;x86_64"

# Copy scripts to container for running the emulator and creating a snapshot
COPY scripts/* /
