# **Pi-hole** for docker
A black hole for Internet advertisements

This build was first base off https://github.com/diginc/docker-pi-hole, 
but that has many customizations added and bit too complicated, seems like a whole new project.

This build pulls the latest version of pihole https://github.com/pi-hole/pi-hole,
pre configure and install the unattended way to run under Docker.

This build has Webmin http://www.webmin.com/ installed to easy update underlining image. 
It can be disable by passing `–e WEBMINPORT=off`

Additionally passing the following environment options at run time controls operations:
```
`–e IPV4=0.0.0.0`
`–e IPV6=::0`
`–e DNS1=8.8.8.8`
`–e DNS2=.8.4.4`
`–e DNSPORT=53`
`–e INTERFACE=eth0`
`–e WEBMINPORT=9000`
```
If nothing is pass the above are defaults.

```
docker run -d --name pihole \
-p 53:53/tcp -p 53:53/udp -p 4711-4720/tcp \
-v pihole-etc:/etc -v pihole-log:/var/log -v pihole-www:/var/www \
-e IPV4=123.123.123.123 \
-e WEBMINPORT=off \
--restart=always --hostname=host.pi.hole technoexpress/pihole
```

This build also assume reverse proxy is setup. 
This build setup to use https://github.com/adi90x/rancher-active-proxy

```
-v /nginx/rancher-active-proxy/letsencrypt/archive/host.pi.hole:/etc/letsencrypt/archive/host.pi.hole \
-l rap.host=host.pi.hole \
-l rap.le_host=host.pi.hole \
-l rap.https_method=noredirect \
```

### Docker Hub
https://hub.docker.com/r/technoexpress/pi-hole/builds/ automatically builds the latest changes into images which can easily be pulled and ran with a simple `docker run` command. 
