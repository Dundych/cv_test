FROM ubuntu:xenial

#install packages
RUN apt-get update -y && \
    apt-get install -y \
    curl \
    wget \
    jq \
    libjpeg-dev \
    libmagickwand-dev \
    libpng-dev \
    openjdk-8-jdk \
    p7zip \
    p7zip-full \
    python-pip \
    ruby \
    ruby-dev \
    sudo

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