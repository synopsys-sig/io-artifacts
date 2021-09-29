#!/bin/bash

URL=https://bizdevhub.blackducksoftware.com

function fileExists() {
    if [ "$( find $2 -name "$1" | wc -l | sed 's/^ *//' )" == "0" ];
    then return 1;
    else return 0;
    fi
}

function installGo() {
    echo "Installing Go Handler"
    apt-get update -y && \
    wget https://dl.google.com/go/go1.15.2.linux-amd64.tar.gz -O go1.15.2.linux-amd64.tar.gz && \
    tar -xf go1.15.2.linux-amd64.tar.gz && \
    mv /go /usr/local && \
    rm /go1.15.2.linux-amd64.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    export GOROOT=/usr/local/go
}

function installNuget() {
    echo "Installing Nuget Handler"
    apt-get update -y && \
    apt-get install -y apt-transport-https && \
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    apt-get update -y && \
    apt-get install -y dotnet-sdk-3.1
#    apt-get install nuget -y
}

function installPython() {
    apt-get update -y && \
    apt-get install python3-pip idle3 -y && \
    pip3 install --no-cache-dir --upgrade pip && \
    \
    # delete cache and tmp files
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/cache/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/lib/apt/lists/* && \
    \
    # make some useful symlinks that are expected to exist
    cd /usr/bin && \
    ln -s idle3 idle && \
    ln -s pydoc3 pydoc && \
    ln -s python3 python && \
    ln -s python3-config python-config && \
    cd /

    wget https://repo.continuum.io/archive/Anaconda3-5.0.1-Linux-x86_64.sh && \
    bash Anaconda3-5.0.1-Linux-x86_64.sh -b && \
    rm Anaconda3-5.0.1-Linux-x86_64.sh

    # Set path to conda
    echo PATH=/root/anaconda3/bin:$PATH
}

function installNPM() {

    npm install --silent
}

for i in "$@"
do
case $i in
    -p=*|--project=*)
    PROJECT="${i#*=}"
    shift # past argument=value
    ;;
    -v=*|--version=*)
    VERSION="${i#*=}"
    shift # past argument=value
    ;;
    -k=*|--key=*)
    KEY="${i#*=}"
    shift # past argument=value
    ;;
    -s=*|--source=*)
    SOURCE="${i#*=}"
    shift # past argument=value
    ;;
    -b=*|--build=*)
    BUILD="${i#*=}"
    shift # past argument=value
    ;;
    -c=*|--config=*)
    CONFIG="${i#*=}"
    shift # past argument=value
    ;;
    -e=*|--extra=*)
    EXTRA="${i#*=}"
    shift # past argument=value
    ;;
    *)
        # unknown option
    ;;
esac
done

if [[ -z "$SOURCE" ]]
then
    echo "No source parameter specified."
    exit 1
fi
if [[ -z "$KEY" ]]
then
    echo "No API Key specified."
    exit 1
fi

OPTIONS="--blackduck.api.token=$KEY --blackduck.url=$URL"

if [[ -z "$PROJECT" ]]
then
#   Project not specified, so use the default
    PROJECT="DEFAULT"
else
    OPTIONS="${OPTIONS} --detect.project.name=${PROJECT}"
fi

if [[ -z "$VERSION" ]]
then
#   Version not specified, so use the default
    VERSION="DEFAULT"
else
    OPTIONS="${OPTIONS} --detect.project.version.name=${VERSION}"
fi

# Handle Extra Black Duck options
if [[ ! -z "$EXTRA" ]]
then
    OPTIONS="${OPTIONS} ${EXTRA}"
fi

if [[ $SOURCE == "LOCAL" ]]
then
    FOLDER="/source"
else
    FOLDER="/source/${PROJECT}-${VERSION}"

    # Delete source folder if it already exists
    if [[ -d $FOLDER ]]
    then
        rm -Rf $FOLDER
    fi

    mkdir $FOLDER

    if [[ $SOURCE == *.git ]]
    then
        git clone $SOURCE $FOLDER
        if [[ $? -ne 0 ]]; then
            echo "Error cloning $SOURCE"
            exit 2
        fi
    else
        FILENAME="${SOURCE##*/}"
        wget --directory-prefix=/source/ -q $SOURCE > /dev/null
        if [[ $? -ne 0 ]]; then
            echo "Error downloading file $SOURCE"
            exit 2
        else
            if [[ $FILENAME == *.zip ]]
            then
                unzip /source/$FILENAME -d $FOLDER > /dev/null
                rm /source/$FILENAME
            fi
        fi
    fi
fi

# Check if any Python files and install Python if there are
if fileExists "Pipfile" $FOLDER || fileExists "Pipfile.lock" $FOLDER || fileExists "setup.py" $FOLDER || fileExists "requirements.txt" $FOLDER || fileExists "environment.yml" $FOLDER;
then installPython;
fi

if fileExists "NuGet.Config" $FOLDER
then installNuget;
fi

if fileExists "package.json" $FOLDER
then cd $FOLDER && installNPM;
fi

if fileExists "Gopkg.lock" $FOLDER || fileExists "gogradle.lock" $FOLDER || fileExists "go.mod" $FOLDER || fileExists "vendor.conf" $FOLDER;
then installGo;
fi

cd $FOLDER

if [ -n "$CONFIG" ]; then
    eval "$CONFIG"
fi

if [ -n "$BUILD" ]; then
    eval "$BUILD"
fi

#bash <(curl -s -L https://detect.synopsys.com/detect.sh) $OPTIONS --detect.source.path=$FOLDER
java -jar /tools/detect.jar $OPTIONS --detect.source.path=$FOLDER ----detect.force.success=true
STATUS=$?

# Clean up
if [[ $SOURCE != "LOCAL" ]]
then
    rm -Rf $FOLDER
fi

exit $STATUS
