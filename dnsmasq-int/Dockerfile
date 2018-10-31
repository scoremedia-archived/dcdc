FROM alpine:latest
MAINTAINER Kevin Jalbert "kevin.j.jalbert@gmail.com"

RUN apk update
RUN apk --no-cache add \
    dnsmasq \
    openssl

ENV DOCKER_HOST unix:///tmp/docker.sock

# Install docker-gen
ENV DOCKER_GEN_VERSION 0.7.4
RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

# Needed so that the /tmp/hosts/internal.host file can exist with correct permissions for dnsmasq to read it
RUN mkdir /tmp/hosts
RUN touch /tmp/hosts/internal.host
RUN chmod 755 /tmp/hosts/internal.host

ADD entrypoint /usr/local/bin/entrypoint

VOLUME /var/run

EXPOSE 53/udp
EXPOSE 53/tcp

ENTRYPOINT ["entrypoint"]
