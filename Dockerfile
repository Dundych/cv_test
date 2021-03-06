FROM ubuntu:xenial

#install packages
RUN apt-get update -y && \
    apt-get install -y \
    vim \
    nano \
    curl \
    wget \
    jq \
    libjpeg-dev=8c-2ubuntu8 \
    libmagickwand-dev=8:6.8.9.9-7ubuntu5.13 \
    libpng-dev \
    openjdk-8-jdk=8u191-b12-2ubuntu0.16.04.1 \
    p7zip \
    p7zip-full \
    python-pip=8.1.1-2ubuntu0.4 \
    ruby=1:2.3.0+1 \
    ruby-dev=1:2.3.0+1 \
    sudo=1.8.16-0ubuntu1.5

#Install bundler gem
RUN gem install bundler

#Open ports
EXPOSE 5037 5555

# Download and install Android SDK
# https://developer.android.com/studio/#downloads

ENV ANDROID_SDK_VERSION 4333796
RUN mkdir -p /opt/android-sdk && cd /opt/android-sdk && \
    wget -q https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_VERSION}.zip && \
    unzip *tools*linux*.zip && \
    rm *tools*linux*.zip

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV ANDROID_HOME /opt/android-sdk
ENV ANDROID_SDK /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools:${ANDROID_HOME}/tools/bin:${JAVA_HOME}

#The next command prevent error during instalation Android SDK
# Warning: File /home/xxxx/.android/repositories.cfg could not be loaded.
RUN mkdir -p ~/.android && touch ~/.android/repositories.cfg

# Install Android SDK components
ENV ANDROID_COMPONENTS "platform-tools build-tools;27.0.3 platforms;android-27"
RUN for component in ${ANDROID_COMPONENTS}; do echo y | sdkmanager "${component}"; done

# Add none root user admin with home dir and sudo available
RUN useradd -m admin && echo "admin:admin" | chpasswd && adduser admin sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER admin

#Generate a key to resign apk (for admin user)
RUN mkdir -p ~/.android
RUN keytool -genkey -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
    -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"