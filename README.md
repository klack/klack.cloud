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
- A [registered domain](https://www.namecheap.com/) name forwarded to your IP
- A [paid VPN subscription](https://protonvpn.com/) for "Download Managers"
- Port 443 must be allowed by your ISP

# Services
- Plex
  - Video Server
- PhotoPrism
  - Photo Gallery
- SFTPGo
  - Photo sync, Note sync, Cloud storage
- Traefik
  - For SSL and Basic Auth
- Fail2Ban
  - Ban bots and failed login attempts automatically
- Grafanda, Promtail
  - Log aggregation, dashboards and alerts
- Prometheus, Node Exporter
  - HTTP Stats, System Stats
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
|
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
## Pre-requisites  
- Configure your router to [update your external domain](https://www.namecheap.com/support/knowledgebase/subcategory/11/dynamic-dns/) via Dynamic DNS.
- Configure your router to forward port 443 and 32400 to your machine.
- Login to your VPN provider and [download a wireguard.conf file](https://protonvpn.com/support/wireguard-configurations/).
- Place it at `./config/wireguard/wg0.conf`
- Make sure your ISP does not block port 443.

## Setup
```bash
git clone https://github.com/klack/klack.cloud.git
cd klack.cloud
./setup.sh
```
### Dashboard setup
#### System Resource Monitor
- [Add a prometheus connection](https://grafana.klack.internal:4443/connections/datasources/prometheus) to Grafana  
  Click "Add new data source" at the upper right  
  Fill in  `http://prometheus:9090` for URL and then click "Save & test" at the bottom  
  Close the page
- [Add a Loki connection](https://grafana.klack.internal:4443/connections/datasources/loki) to Grafana  
  Click "Add new data source" at the upper right  
  Fill in `http://loki:3100` for URL and then click "Save & test" at the bottom.  
  Close the page.  
- [Import the dashboard](https://grafana.klack.internal:4443/dashboard/import) for Node Exporter  
  Paste `1860` for dashboard ID  
  Click "Load" to the right  
  At the bottom under "Prometheus" select the "Prometheus" data source  
  Click "Import"  
- [Import the dashboard](https://grafana.klack.internal:4443/dashboard/import) for Traefik  
  Paste `4475` for dashboard ID  
  Click "Load" to the right  
  At the bottom under "Prometheus" select the "Prometheus" data source  
  Click "Import"
- [Import the Overview dashboard](https://grafana.klack.internal:4443/dashboard/import)  
  Click "Upload dashboard JSON file"  
  Choose the `./config/grafana/overview-dashboard.json` file  
  Click "Import"  
- Save a bookmark to [your Dashboards page](https://grafana.klack.internal:4443/dashboards).
- TODO Create Alerts

### Cloud Setup
- Login to the [SFTPGo WebAdmin](https://sftpgo.klack.internal:4443/web/admin/)
- Visit the [Server Manager - Maintenance](https://sftpgo.klack.internal:4443/web/admin/maintenance) page
- Click "Browse" and choose `./config/sftpgo/settings.json`
- Click "Restore"
- Login to the [SFTPGo WebClient](https://sftpgo.klack.internal:4443/web/client/login) with username `cloud` and password `cloud`
- [Set your cloud password](https://sftpgo.klack.internal:4443/web/client/changepwd)
- Map a local folder on your OS to webdav
- Setup photo syncing from your phone
- Setup Joplin sync

### Download Managers setup
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

### Security
- setup IPTables to block non-docker containers from node exporter?
    - `sudo iptables -A INPUT -p tcp -s 172.17.0.0/16 --dport 9100 -j ACCEPT`
    - `sudo iptables -A INPUT -p tcp --dport 9100 -j DROP`
  

- Setup backups in duplicati

# Host Machine
Node exporter is run on the host machine and read by the prometheus docker instance.  IPTable rules should be created so that only this docker container can talk to node exporter

## Log Rotation
Must be setup on the host machine due to permission issues and the requirement to send SIGHUP signals.  


# Other Notes
Honeypot's cannot be accessed by localhost due to macvlan network
