# Features
- Download any movie or tv show by entering its name
- Automatically get new episodes
- Photo hosting to replace iCloud
- Joplin sync to replace Evernote
- Plex to replace all streaming services
- VPN with killswitch
- SSL signed by Letsencrypt
- Automatic IP banning
- Automatic updates
- Logging, monitoring, and alerts

# Docker Setup
- Plex
	- Video Server
- PhotoPrism
	- Photo Gallery
- SFTPGo
  	- Webdav is used for PhotoSync from mobile devices and Joplin Sync
- qBittorrent-wireguard
	- Combined bitorrent and wireguard image with VPN killswitch
- Downloaders
	- Sonarr for TV
	- Radarr for Movies
	- Jackett for searching torrent websites
	- Unpackerr to handle compressed files
- Traefik
    - For acme SSL and Basic Auth
- Fail2Ban
    - Ban by IP
- Watchtower
    - To auto update docker images
- Grafanda
	- Log aggriation, visualization and alerts

# Endpoints
| Service | Port | Domain | Path | Link |
| --- | --- | --- | --- | --- |
| PhotoPrism | 443 | klack.cloud | /photos | https://klack.cloud/photos |
| WebDav | 443 | klack.cloud | /dav | https://klack.cloud/dav/ |
| Plex | 32400 | klack.cloud | /   | https://klack.cloud:32401 |
| qBittorrent | 4443 | qbittorrent.klack.internal | /   | https://qbittorrent.klack.internal:4443 |
| Jackett | 4443 | jackett.klack.internal | /   | https://jackett.klack.internal:4443 |
| Sonarr | 4443 | sonarr.klack.internal | /   | https://sonarr.klack.internal:4443 |
| Ronarr | 4443 | radarr.klack.internal | /   | https://radarr.klack.internal:4443 |
| traefik UI | 4443 | traefik.klack.internal | /   | https://traefik.klack.internal:4443 |
| SFTPGo UI | 4443 | sftpgo.klack.internal | /   | https://sftpgo.klack.internal:4443 |
| Grafana | 4443 | grafana.klack.internal | /   | https://grafana.klack.internal:4443 |

# Backups
Backups are accomplished through a seperate duplicati docker instance

# Deployment
- Rename `.env.example` to `.env` and fill in credentials
- All .internal services need a hosts file or router dns pointed to the correct IP
- Create `/var/log/sonarr` and `/var/log/radarr`owned by 1000:1000
- Create a new server key and certificate signed by a self trusted ca.  Place `server.crt` and `server.key` in `/config/traefik/certs` for klack.internal certificates
- Create `htpasswd` at `./config/traefik/htpasswd` for Trafik basic auth
- Place `wg0.conf` at `./config/wireguard/wg0.conf` for Wireguard
- `allup.sh`
- Add Loki connection to Grafana `http://loki:3100`
- Set `QB_WEBUI_USER, QB_WEBUI_PASS, UN_SONARR_0_API_KEY, UN_RADARR_0_API_KEY` in `.env`file
- If there are directory to file mapping errors, open the volume and delete the folder inside

# Logs
- Promtail cannot get logs from containers using another container's network (Jackett, Sonnarr, Radarr), so they are volume linked out of each container to the host's `/var/log/*` and then back into promtail.

## Rotation
Must be setup on the host machine due to permission issues and the requirement to send SIGHUP signals.  
Copy `./config/logrotate.d/traefik` to `/etc/logrotate.d/traefik` on your host
Copy `./config/docker/daemon.json` to `/etc/docker/daemon.json`
