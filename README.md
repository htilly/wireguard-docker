Fork from cmulk/wireguard-docker.
Modification done with focus on using the container as a WireGuard client. Primarily for allowing other container to route thru this one.

# Changes made:
- Implemented kill switch (make sure no traffic is passed thru without going thru the VPN). I.e. if the "wg show" endpoint IP doesn't match the peer endpoint in wg0.conf the container will shutdown.

- Implemented support for local routing. By default any container using this one as network won't be reachable from the local network. If applying "- LOCAL_NETWORK=x.x.x.x/x" the defined network will be routed back on eth0. Note: As for now this is "all or nothing". When applying a route back, all ports will be available from the selected network.

Example docker-compose:

´´´
version: '3.4'
services:
wireguard:
  container_name: wireguard
  image: beta_wireguard:local
  volumes:
    - /config/wireguard:/etc/wireguard
    - /lib/modules:/lib/modules
  ports:
    - 9929:9929/udp
    - 888:80
  restart: unless-stopped
  cap_add:
    - NET_ADMIN
    - SYS_MODULE
  security_opt:
    - label:disable
  sysctls:
    - net.ipv6.conf.all.disable_ipv6=0
    - net.ipv6.conf.default.forwarding=1
    - net.ipv6.conf.all.forwarding=1
    - net.ipv4.ip_forward=1
  environment:
    - LOCAL_NETWORK=192.168.200.0/16
  privileged: true
´´´

# wireguard-docker
Wireguard setup in Docker on Debian  kernel meant for a simple personal VPN
There are currently 2 branches, stretch and buster. Use the branch that corresponds to your host machine if the kernel module install feature is going to be used.

## Overview
This docker image and configuration is my simple version of a wireguard personal VPN, used for the goal of security over insecure (public) networks, not necessarily for Internet anonymity. The docker images uses debian stable, and the host OS must also use the debian stable kernel, since the image will build the wireguard kernel modules on first run. As such, the hosts /lib/modules directory also needs to be mounted to the container on the first run to install the module (see the Running section below). Thanks to [activeeos/wireguard-docker](https://github.com/activeeos/wireguard-docker) for the general structure of the docker image. It is the same concept just built on Ubuntu 16.04.

## Run
### First Run
If the wireguard kernel module is not already installed on the __host__ system, use this first run command to install it:
```
docker run -it --rm --cap-add sys_module -v /lib/modules:/lib/modules cmulk/wireguard-docker:buster install-module
```

### Normal Run
```
docker run --cap-add net_admin --cap-add sys_module -v <config volume or host dir>:/etc/wireguard -p <externalport>:<dockerport>/udp cmulk/wireguard-docker:buster
```
Example:
```
docker run --cap-add net_admin --cap-add sys_module -v wireguard_conf:/etc/wireguard -p 5555:5555/udp cmulk/wireguard-docker:buster
```

## Configuration


Sample client configuration:
```
[Interface]
Address = 192.168.20.2/24
DNS = 1.1.1.1, 8.8.8.8
PrivateKey = <client_private_key>
ListenPort = 0 #needed for some clients to accept the config

[Peer]
PublicKey = <server_public_key>
Endpoint = <server_public_ip>:5555
AllowedIPs = 0.0.0.0/0,::/0 #makes sure ALL traffic routed through VPN
PersistentKeepalive = 25
```
## Other Notes
- This Docker image also has a iptables NAT (MASQUERADE) rule already configured to make traffic through the VPN to the Internet work. This can be disabled by setting the environment varialbe IPTABLES_MASQ to 0.
- For some clients (a GL.inet router in my case) you may have trouble with HTTPS (SSL/TLS) due to the MTU on the VPN. Ping and HTTP work fine but HTTPS does not for some sites. This can be fixed with [MSS Clamping](https://www.tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.cookbook.mtu-mss.html). This is simply a checkbox in the OpenWRT Firewall settings interface.
- This image can be used as a client as well. If you want to forward all traffic through the VPN (`AllowedIPs = 0.0.0.0/0`), you need to use the `--privileged` flag when running the container

## docker-compose


## Build
Since the images are already on Docker Hub, you only need to do this if you want to change something
```
git clone https://github.com/htilly/wireguard-docker.git
cd wireguard-docker
git checkout stretch
##OR##
git checkout buster

docker build -t wireguard:local .
```
