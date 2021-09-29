# Docker Image for Synopsys IO Execution Environment
# Dockerfile for io-env:latest

FROM ubuntu:20.04
MAINTAINER SynopsysSIG Team, https://gitlab.com/synopsys/IO/intelligent-security-scan
RUN apt-get update && \
    apt-get upgrade -y && \
	apt-get install apt-utils && \
    apt-get update && apt-get install wget jq openjdk-11-jre-headless -y && \
    apt-get clean
# RUN rm -rf /usr/local/share/ca-certificates/io.prodsec.prod.use.torq.dev*
# RUN wget -O /usr/local/share/ca-certificates/io.prodsec.prod.use.torq.dev.crt https://gitlab.corp.wabtec.com/get-devops/synopsys-integration/-/raw/ master/io.prodsec.prod.use.torq.dev.crt
# RUN update-ca-certificates
RUN wget -O /usr/bin/curl https://github.com/moparisthebest/static-curl/releases/download/v7.77.0/curl-amd64 && chmod 0755 /usr/bin/curl
RUN mkdir /home/devops
RUN wget -O /home/devops/io_onboarding.sh https://raw.githubusercontent.com/synopsys-sig/io-artifacts/2021.8.1/io_onboarding.sh
RUN sed -i -e 's/\r$//' /home/devops/io_onboarding.sh
RUN chmod +x /home/devops/io_onboarding.sh
RUN wget -O /home/devops/prescription.sh https://raw.githubusercontent.com/synopsys-sig/io-artifacts/2021.8.1/prescription.sh
RUN sed -i -e 's/\r$//' /home/devops/prescription.sh
RUN chmod +x /home/devops/prescription.sh
RUN wget -O /home/devops/WorkflowClient.jar https://github.com/synopsys-sig/io-artifacts/releases/download/2021.8.1/WorkflowClient.jar
