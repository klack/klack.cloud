# klack.cloud
A self-hosted replacement for iCloud, Google Photos, Evernote, Netflix and more.  Secure and monitored.

# Features
- Photo hosting to replace iCloud
- Joplin to replace Evernote
- Plex to replace all streaming services
- VPN with killswitch
- SSL signed by Let's Encrypt
- Automatic IP banning
- Automatic updates
- Logging, monitoring, and alerts

# Services
- Plex
	- Video Server
- PhotoPrism
	- Photo Gallery
- SFTPGo
  	- Webdav is used for PhotoSync from mobile devices and Joplin Sync
- qBittorrent-wireguard
	- Combined bitorrent and wireguard image with VPN killswitch
- Traefik
    - For acme SSL and Basic Auth
- Fail2Ban
    - Ban by IP
- Watchtower
    - To auto update docker images
- Grafanda
	- Log aggrigation, visualization and alerts
- File search
	- Sonarr for TV
	- Radarr for Movies
	- Jackett for searching torrent websites
	- Unpackerr to handle compressed files

# Endpoints
| Service | Port | Domain | Path | Link |
| --- | --- | --- | --- | --- |
| PhotoPrism | 443 | klack.cloud | /photos | https://klack.cloud/photos |
| WebDav | 443 | klack.cloud | /dav | https://klack.cloud/dav/ |
| Plex | 32400 | klack.cloud | /   | https://klack.cloud:32401/ |
| qBittorrent | 4443 | qbittorrent.klack.internal | /   | https://qbittorrent.klack.internal:4443/ |
| Jackett | 4443 | jackett.klack.internal | /   | https://jackett.klack.internal:4443/ |
| Sonarr | 4443 | sonarr.klack.internal | /   | https://sonarr.klack.internal:4443/ |
| Ronarr | 4443 | radarr.klack.internal | /   | https://radarr.klack.internal:4443/ |
| traefik UI | 4443 | traefik.klack.internal | /   | https://traefik.klack.internal:4443/ |
| SFTPGo UI | 4443 | sftpgo.klack.internal | /   | https://sftpgo.klack.internal:4443/ |
| Grafana | 4443 | grafana.klack.internal | /   | https://grafana.klack.internal:4443/ |
| Prometheus | 4443 | prometheus.klack.internal | /   | https://prometheus.klack.internal:4443/ |
| Node Exporter | 4443 | node-exp.klack.internal | /   | https://node-exp.klack.internal:4443/ |
| Duplicati | 44443 | duplicati.klack.internal | /   | https://duplicati.klack.internal:4443/ |

# Deployment
- Rename `.env.example` to `.env` and fill in credentials
- All `.internal` addresses need modifications to your hosts file or router dns pointed to the correct IP.
- `docker network create klack`
- Edit plex.yml and place file if you need to reuse an existing Plex server id
- Create `/var/log/sonarr` and `/var/log/radarr` owned by 1000:1000
- Create a new server key and certificate signed by a self trusted ca.  
- Place `ca.crt`,`server.crt`, and `server.key` in `/config/traefik/certs` for `.internal` certificates
- Create `htpasswd` at `./config/traefik/htpasswd` for Trafik basic auth
- Place `wg0.conf` at `./config/wireguard/wg0.conf` for Wireguard
- Run `docker compose up` to start up core apps
- If there are directory to file mapping errors, there should of been a config file in a place, but docker did not find it so it created a volume folder.  Delete the volume folder.
- Add Loki connection to Grafana `http://loki:3100`
- Add prometheus connecto to Grafanan `http://prometheus:9090`
- `docker compose up --profile downloaders`
- Log into qBittorrent with user: `admin` pass: `adminadmin`
- Change admin password
- Turn off qBittorrent logging
- Change qBittorrent download path to `/data/downloads` and incomplete torrrents to `/data/downloads/temp`
- Set password in sonarr and radarr and disable authentication for localhost
- Enable file renaming in sonarr and radarr
- Set `QB_WEBUI_USER, QB_WEBUI_PASS, UN_SONARR_0_API_KEY, UN_RADARR_0_API_KEY` in `.env`file 
- `docker compose up --profile downloaders` again.  Verify port number is updated in qBittorent to a random one.
- Use `http://localhost:9117` for that Jackett address when creating a torznab indexer
- `sudo chown -R 1000:1000 ./config`
- `sudo chown -R 1000:1000` klack.tv, photos, joplin, and other data folders
- Use `/data/library/tv/` as a path when adding a series in sonarr
- Use `/data/library/movies/` as a path when adding a movie on radarr
- Install node exporter on the host machine to `/usr/local/bin/node_exporter`
  - Create a cronjob so that it is run on reboot
  - setup IPTables to block non-docker containers from it
    - `sudo iptables -A INPUT -p tcp -s 172.17.0.0/16 --dport 9100 -j ACCEPT`
    - `sudo iptables -A INPUT -p tcp --dport 9100 -j DROP`

# Metrics
Node exporter is run on the host machine and read by the prometheus docker instance.  IPTable rules should be created so that only this docker container can talk to node exporter

# Logs
Promtail cannot get logs from containers using another container's network (Jackett, Sonnarr, Radarr), so they are volume linked out of each container to the host's `/var/log/*` and then back into promtail.

## Rotation
Must be setup on the host machine due to permission issues and the requirement to send SIGHUP signals.  
Copy `./config/logrotate.d/*` to `/etc/logrotate.d/` on your host  
Copy `./config/docker/daemon.json` to `/etc/docker/daemon.json`  
Cowrie needs 999:999 on `/var/log/crowie` to be able to create log files.
Sonarr and Radarr have their own log rotation

# Backups
Backups are accomplished through a seperate duplicati docker instance

# Other Notes
Honeypot's cannot be accessed by localhost due to macvlan network