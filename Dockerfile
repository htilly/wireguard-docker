FROM debian:buster

# Add debian unstable repo for wireguard packages
RUN echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list && \
 printf 'Package: *\nPin: release a=unstable\nPin-Priority: 90\n' > /etc/apt/preferences.d/limit-unstable
 
 
# Install wireguard packges
RUN apt update && \
 apt install -y --no-install-recommends ntp dnsutils whois curl vim wireguard-tools iptables openresolv net-tools procps && \
 apt clean

RUN  echo resolvconf resolvconf/linkify-resolvconf boolean false | debconf-set-selections && \
 echo "REPORT_ABSENT_SYMLINK=no" >> /etc/default/resolvconf && \
 apt-get -y install resolvconf && apt-get -y install debconf-utils && \
 apt clean

# Add main work dir to PATH
WORKDIR /scripts
ENV PATH="/scripts:${PATH}"

# Use iptables masquerade NAT rule
ENV IPTABLES_MASQ=1

# Copy scripts to containers
COPY install-module /scripts
COPY run /scripts
COPY genkeys /scripts
RUN chmod 755 /scripts/*

# Wirguard interface configs go in /etc/wireguard
VOLUME /etc/wireguard

# Normal behavior is just to run wireguard with existing configs
CMD ["run"]
