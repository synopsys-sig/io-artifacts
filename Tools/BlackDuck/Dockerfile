FROM ubuntu:18.04

ARG detect_ver=LATEST

ENV detect_base_url=https://sig-repo.synopsys.com

# Generic tools
RUN apt-get -y update
RUN apt-get -y install apt-utils
RUN apt-get -y install wget curl unzip git

# Install Make 

RUN apt-get -y install make

# Golang
RUN apt-get -y install less gdb

ENV PATH=/usr/lib/go-1.10/bin:$PATH

# Node
RUN apt-get -y install npm nodejs \
    && npm install -g yarn

# JAVA
RUN apt-get -y install openjdk-8-jdk

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
RUN apt-get install -y clang

# CPAN
RUN apt-get install -qy perl cpanminus \
    && rm -rf "/var/lib/apt/lists/*", "/tmp/*", "/var/tmp/*" \
    && cpanm Proc::ProcessTable Data::Dumper

#TZdata install
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install tzdata


# remove download archive files
RUN apt-get clean

RUN mkdir /tools
COPY run-detect.sh '/tools/run-detect.sh'
RUN chmod +x /tools/run-detect.sh

ENV download_source =

RUN if [ "$detect_ver" = "LATEST" ] ; then \
  wget --no-verbose -O /tools/detect.jar `curl --silent --header \"X-Result-Detail: info\" ${detect_base_url}/api/storage/bds-integrations-release/com/synopsys/integration/synopsys-detect?properties=DETECT_LATEST | grep \"DETECT_LATEST"" | sed 's/[^[]*[^\"]*\"\([^\"]*\).*/\1/'""` ; \
else \
  wget --no-verbose -O /tools/detect.jar ${detect_base_url}/bds-integrations-release/com/synopsys/integration/synopsys-detect/${detect_ver}/synopsys-detect-${detect_ver}.jar ; \
fi

# Define Docker Image entrypoint
#ENTRYPOINT ["/bin/bash"]
ENTRYPOINT ["/tools/run-detect.sh"]
