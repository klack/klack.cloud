# klack.cloud
A secure, monitored, self-hosted replacement for iCloud, Google Photos, Dropbox, Evernote, Netflix and more.

![](./assets/diagram.png)
## Goals
- Reduce your dependence on cloud services
- Eliminate subscription costs
- Increase your privacy
- Limit data collected by free services
- Limit your exposure to AI, advertisers, and scammers
- Own and control your data
- Prevent phone and vendor lock in
## Dashboards
![](./assets/dashboard.png)
![](./assets/dashboard2.png)
![](./assets/dashboard3.png)

## Features
- Photo hosting to replace iCloud and Google Photos
- Note syncing to replace Evernote
- Media server to replace streaming services
- WebDav to replace Dropbox
- Download Managers with VPN killswitch
- SSL certificates signed by Let's Encrypt
- Automatic IP banning
- Automatic updates
- Honeypots 
- Logging, monitoring, and alerts


## Pre-requisites
- A [registered domain name](https://www.namecheap.com/) forwarded to your IP
- A paid VPN subscription
- Port 443 must be allowed by your ISP

# Services
- Plex
  - Video Server
- PhotoPrism
  - Photo Gallery
- SFTPGo
  - Photo sync, Note sync, 
- Traefik
  - For SSL and Basic Auth
- Fail2Ban
  - Ban bots and failed login attempts automatically
- Grafanda, Promtail
  - Log aggregation, visualization and alerts
- Prometheus, Node Exporter
  - System Stats, HTTP stats
- logrotate
  - Rotate logs to preserve hard disk space
- Crowie, Dionaea
  - Honeypots for SSH, HTTP, SMB and more
- Duplicati
  - Incremental Backups
- Watchtower
  - To auto update docker images
- qBittorrent-wireguard
  - Combined bittorrent and wireguard image with VPN killswitch
- Download Managers
  - Sonarr for TV
  - Radarr for Movies
  - Jackett for searching
  - Unpackerr to handle compressed files

| Service | Port | Domain | Hosted Path | URL | Service URL | Auth Provider | Log Rotation
| --- | --- | --- | --- | --- | --- | --- | --- |
| Plex | 32400 | example.com | /   | https://example.com:32400/ | | App | Self
| PhotoPrism | 443 | example.com | /photos | https://example.com/photos | |App | Docker
| WebDav | 443 | example.com | /dav | https://example.com/dav/ | | Traefik | Docker
| SFTPGo UI | 4443 | sftpgo.klack.internal | /   | https://sftpgo.klack.internal:4443/ | | Traefik | Docker
| Traefik UI | 4443 | traefik.klack.internal | /   | https://traefik.klack.internal:4443/ | | Traefik | logrotate
| Grafana | 4443 | grafana.klack.internal | /   | https://grafana.klack.internal:4443/ | | App | Docker
| Prometheus | 4443 | prometheus.klack.internal | /   | https://prometheus.klack.internal:4443/ | http://prometheus:9090 | Traefk | Docker
| Loki | | | | | http://loki:3100 | | Docker
| Node Exporter | 9101 | node-exp.klack.internal | /   | https://node-exp.klack.internal:9101/metrics | | IPTABLES | stdout
| Duplicati | 4443 | duplicati.klack.internal | /   | https://duplicati.klack.internal:4443/ | | Traefik | logrotate
| qBittorrent | 4443 | qbittorrent.klack.internal | /   | https://qbittorrent.klack.internal:4443/ | | App | logs disabled
| Jackett | 4443 | jackett.klack.internal | /   | https://jackett.klack.internal:4443/ | http://localhost:9117 | Traefik | logs disabled
| Sonarr | 4443 | sonarr.klack.internal | /   | https://sonarr.klack.internal:4443/ | | App | Self
| Radarr | 4443 | radarr.klack.internal | /   | https://radarr.klack.internal:4443/ | | App | Self
| Cowrie | 22,23 | | | | | | logrotate
| Dionaea | ~ | | | | | | logrotate

# Deployment
- Rename `.env.example` to `.env` and fill in credentials
- All `.internal` addresses need modifications to your hosts file or router dns pointed to the correct IP.
- `docker network create klack`
- Create `/var/log/sonarr` and `/var/log/radarr` owned by 1000:1000
- Create a new server key and certificate signed by a self trusted ca.  
- Place `ca.crt`,`server.crt`, and `server.key` in `/config/traefik/certs` for `.internal` certificates
- Create `htpasswd` at `./config/traefik/htpasswd` for Trafik basic auth
- Place `wg0.conf` at `./config/wireguard/wg0.conf` for Wireguard
- Run `docker compose up` to start up core apps
- If there are directory to file mapping errors, there should of been a config file in a place, but docker did not find it so it created a volume folder.  Delete the volume folder.
- Add Loki connection to Grafana `http://loki:3100`
- Add prometheus connection to Grafana `http://prometheus:9090`
- `docker compose up --profile downloaders`
- Log into qBittorrent with user: `admin` pass: `adminadmin`
- Change admin password
- Turn off qBittorrent logging
- Change qBittorrent download path to `/data/downloads` and incomplete torrents to `/data/downloads/temp`
- Set password in sonarr and radarr and disable authentication for localhost
- Enable file renaming in sonarr and radarr
- Setting logging to `Info` on sonarr and radarr
- Use `/data/library/tv/` as a path when adding a series in sonarr
- Use `/data/library/movies/` as a path when adding a movie on radarr
- Set `QB_WEBUI_USER, QB_WEBUI_PASS, UN_SONARR_0_API_KEY, UN_RADARR_0_API_KEY` in `.env`file 
- `docker compose up --profile downloaders` again.  Verify port number is updated in qBittorent to a random one.
- Use `http://localhost:9117` for that Jackett address when creating a torznab indexer
- `sudo chown -R 1000:1000 ./config`
- `sudo chown -R 1000:1000` klack.tv, photos, joplin, and other data folders
- Login to sftpgo and create virtual folders for `/joplin` and `/photos`
- Create a new sftpgo user with mappings to these folders
- Install node exporter on the host machine to `/usr/local/bin/node_exporter`
  - Create a cronjob so that it is run on reboot
  - setup IPTables to block non-docker containers from it
    - `sudo iptables -A INPUT -p tcp -s 172.17.0.0/16 --dport 9100 -j ACCEPT`
    - `sudo iptables -A INPUT -p tcp --dport 9100 -j DROP`
- Map a local folder on your OS to webdav
- Setup photo syncing from your phone
- Setup Joplin sync
- Setup backups in duplicati

# Host Machine
Node exporter is run on the host machine and read by the prometheus docker instance.  IPTable rules should be created so that only this docker container can talk to node exporter

## Log Rotation
Must be setup on the host machine due to permission issues and the requirement to send SIGHUP signals.  
Copy `./config/logrotate.d/*` to `/etc/logrotate.d/` on your host  
Copy `./config/docker/daemon.json` to `/etc/docker/daemon.json`  
Cowrie needs 999:999 on `/var/log/crowie` to be able to create log files.

# Other Notes
Honeypot's cannot be accessed by localhost due to macvlan network
