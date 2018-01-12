# pi-hole for docker
A black hole for Internet advertisements

This build was first base off https://github.com/diginc/docker-pi-hole, 
but that has many customizations added and bit too complicated, seems like a whole new project.

This build pulls the latest version of pihole https://github.com/pi-hole/pi-hole,
pre configure and install the unattended way to run under Docker.

This build has webmin install to easy update underlining image. 
It can be disable by passing `–e WEBMINPORT=off`

```
docker run -d --name pihole \
-p 53:53/tcp -p 53:53/udp -p 4711-4720/tcp \
-v pihole-etc:/etc -v pihole-log:/var/log -v pihole-www:/var/www \
-e IPV4=192.187.122.117 \
-e WEBMINPORT=off \
--restart=always --hostname=host.pi.hole technoexpress/pihole
```
