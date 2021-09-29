FROM ubuntu:18.04

# Note: Each project can set it's own POLARIS_ACCESS_TOKEN which will overwrite this below
ENV POLARIS_SERVER_URL=https://csprod.polaris.synopsys.com
ENV POLARIS_ACCESS_TOKEN=erbsrhcmj513j678hil89j5nsesqfvventnj8o9gin0l9stmjv20

RUN apt-get -qy update \
    && apt-get install -q -y --no-install-recommends wget unzip ca-certificates git curl

# Install Make

RUN apt-get -y install make
# Golang
RUN apt-get -y --no-install-recommends install less gdb
ENV PATH=/usr/lib/go-1.10/bin:$PATH

# Node
RUN apt-get -y install npm nodejs \
    && npm install -g yarn

# JAVA
RUN apt-get -y --no-install-recommends install openjdk-8-jdk

# Download and install Gradle
RUN cd /usr/local \
    && curl -L https://services.gradle.org/distributions/gradle-2.5-bin.zip -o gradle-2.5-bin.zip \
    && unzip gradle-2.5-bin.zip \
    && rm gradle-2.5-bin.zip

# Export some environment variables
ENV GRADLE_HOME=/usr/local/gradle-2.5 PATH=$PATH:$GRADLE_HOME/bin JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64


# get maven 3.3.9, verify checksum & install maven
RUN wget --no-verbose -O /tmp/apache-maven-3.3.9.tar.gz http://archive.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
    && echo "516923b3955b6035ba6b0a5b031fbd8b /tmp/apache-maven-3.3.9.tar.gz" | md5sum -c \
    && tar xzf /tmp/apache-maven-3.3.9.tar.gz -C /opt/ \
    && ln -s /opt/apache-maven-3.3.9 /opt/maven \
    && ln -s /opt/maven/bin/mvn /usr/local/bin \
    && rm -f /tmp/apache-maven-3.3.9.tar.gz

# Export some environment variables
ENV MAVEN_HOME /opt/maven

# Clang
RUN apt-get -y --no-install-recommends install clang

# CPAN
RUN apt-get install -qy perl cpanminus \
    && rm -rf "/var/lib/apt/lists/*", "/tmp/*", "/var/tmp/*" \
    && cpanm Proc::ProcessTable Data::Dumper

# Polaris download
RUN wget -q --no-check-certificate $POLARIS_SERVER_URL/api/tools/v2/downloads/polaris_cli-linux64.zip && \
  mkdir -p /home/gradle/.gradle && \
  unzip -j polaris_cli-linux64.zip -d /usr/bin && \
  rm polaris_cli-linux64.zip  && \
  mkdir -p /usr/share/ca-certificates/extra && \
  wget https://web.entrust.com/root-certificates/entrust_ev_ca.cer > /usr/share/ca-certificates/extra/entrust_ev_ca.cer

RUN update-ca-certificates

COPY init.gradle /home/gradle/.gradle/init.gradle

RUN polaris install
