# klack.cloud
 An example of a self-hosted, microservice based, replacement for iCloud, Google Photos, Evernote, Netflix and more. Secure and monitored. 
 
![](./assets/diagram.png)
### Goals
- Reduce your dependence on cloud services
- Eliminate subscription costs
- Increase your privacy
- Limit data collected by free services
- Limit your exposure to AI, advertisers, and scammers
- Own and control your data
- Prevent phone and vendor lock in

### Overview Dashboard
![](./assets/dashboard.png)
### System Dashboard
![](./assets/dashboard2.png)

# Features
- 📺 Video Server
  - [Plex](https://www.plex.tv/)
- 📷 Photo Gallery
  - [Immich](https://immich.app/)
- 🔄 Cloud storage, Note sync
  - [SFTPGo](https://sftpgo.com/)
- 🔐 SSL and Basic Auth
  - [Traefik](https://traefik.io/traefik/)
- ⛔ Ban bots and failed login attempts automatically
  - [Fail2ban](https://github.com/fail2ban/fail2ban/wiki)
- 🚨 📊 📃 Log aggregation, dashboards and alerts
  - [Grafana](https://grafana.com/), [Promtail](https://grafana.com/docs/loki/latest/send-data/promtail/), [loki](https://grafana.com/oss/loki/)
- 📈 HTTP Stats, System Stats
  - [Prometheus](https://prometheus.io/docs/visualization/grafana/), [Node Exporter](https://prometheus.io/docs/guides/node-exporter/)
- ♻️ Rotate logs to preserve hard disk space
  - [logrotate](https://github.com/logrotate/logrotate)
- 🍯 Honeypots for SSH, HTTP, SMB and more
  - [Cowrie](https://cowrie.readthedocs.io/en/latest/index.html), [Dionaea](https://dionaea.readthedocs.io/)
- 💾 Incremental Backups
  - [Duplicati](https://duplicati.com/)
- ⚙️ Auto update docker images
  - [Watchtower](https://containrrr.dev/watchtower/)
- 🌀 bittorrent with VPN killswitch
  - [qBittorrent-wireguard](https://github.com/tenseiken/docker-qbittorrent-wireguard)
- 📥 Download Managers
  - [Sonarr](https://sonarr.tv/) for TV
  - [Radarr](https://radarr.video/) for Movies
  - [Jackett](https://github.com/Jackett/Jackett) for searching
  - [Unpackerr](https://github.com/Unpackerr/unpackerr) to handle compressed files

# Setup
### Pre-requisites
- [ ] A Raspberry Pi 5 with 8GB of RAM
- [ ] A free domain configured with Dynamic DNS, such as one from [No-IP](https://noip.com)
- [ ] Port 443, 2283, and 32400 must be [forwarded to your machine](https://portforward.com/) from your router
- [ ] To use "Download Managers", a [paid VPN subscription](https://protonvpn.com/) is required
  - Login to your VPN provider and [download a wireguard.conf file](https://protonvpn.com/support/wireguard-configurations/)
  - Enable the "Port Forward" option when configuring

### Notes
- Since you are using a self-signed cert, you will need to accept a security exception in your browser for each service.

### Guides
[View the Raspberry Pi Guide](https://github.com/klack/klack.cloud/wiki/Raspberry-Pi-Guide)

## Home Page
Visit `http://192.168.1.x` to access your home page.

## Setup your Cloud Drive
Cloud Drive URL: `https://your-domain.com/files/`  
  - Windows
    - Click on the Start icon/Windows icon  
    - Go into "This PC"
    - In the toolbar choose the option "Computer"
    - Click on "Map Network drive"
    - Fill in the *Cloud Drive URL*
  - Mac
    - Open the Finder on your computer
    - Click on the "Go" menu and select "Connect to Server"
    - In the new window enter the *Cloud Drive URL* and click on "Connect"
  - Linux (Gnome Desktop)
    - Open Nautilus file manager
    - Choose "Other Locations" from the menu on the left
    - Type the *Cloud Drive URL* into "Connect to Server" field
    - Change https:// to davs://
  - Chromebook
    - `sudo mount -t davfs https://your-domain.com/files/ /home/localuser/klackcloud`
  - iPhone
    - Download [Documents: File Manager & Docs by Readdle](https://apps.apple.com/us/app/documents-file-manager-docs/id364901807)
    - [Setup WebDAV](https://support.readdle.com/documents/transfer-share-your-files/transfer-files-to-another-ios-device-with-webdav) using the *Cloud Drive URL*

## View and Sync your Photos
- View your photos from any device at https://your-domain.com:2283
- Use the Immich app from the appstore on your phone
- For your email address, use `username@your-domain.com`

## Sync your Notes
Setup notebook sync with [Joplin](https://joplinapp.org/help/install/)
  - Open the app
  - Navigate to Options > synchronization
  - Set "Synchronization target" to "WebDAV"
  - Enter `https://your-domain.com/files/Notes` for the "WebDAV URL"
  - Enter your username and password
  - Click "Check synchronization configuration"
  - Upon success click "Show Advanced Settings"
  - Click "Re-upload local data to sync target"

## Sync your Calendar, Contacts, and Reminders
  - [iPhone Guide](https://support.apple.com/guide/iphone/set-up-mail-contacts-and-calendar-accounts-ipha0d932e96/ios)
    - Enter `https://your-domain.com/planner/username` as your CardDAV and CalDAV server
## Alerts
You will receive alerts on the dashboard for the following:
- High CPU temp (or no temp reported)  
- Low Disk space  
- High Ram utilization  
- High CPU utilization  
- Backup failures  
- Honeypot activities  

## Backups
- You should add encryption to your backups in Duplicati by editing the backup job.  
- Videos are not backed up by default.  
- Documents, Notes and Photos are automatically backed up at 1:00PM.  
- If there is a backup failure, you will receive an alert on your dashboard.

# Service Directory
| Service       | Port     | Domain          | Hosted Path | URL                              | Service URL            | Auth Provider | Log Rotation  |
| ------------- | -------- | --------------- | ----------- | -------------------------------- | ---------------------- | ------------- | ------------- |
| Plex          | 32400    | your-domain.com | /           | https://your-domain.com:32400/   |                        | App           | Self          |
| Immich        | 2283     | your-domain.com | /           | https://your-domain.com:2283/    |                        | App           | Docker        |
| WebDav        | 443      | your-domain.com | /files      | https://your-domain.com/files/   |                        | Traefik       | Docker        |
| Radicale      | 443      | your-domain.com | /planner    | https://your-domain.com/planner/ |                        | Traefik       | Docker        |
| SFTPGo UI     | 8081     | 192.168.1.x     | /           | https://192.168.1.x:8081/        |                        | Traefik       | Docker        |
| Traefik UI    | 8082     | 192.168.1.x     | /           | https://192.168.1.x:8082/        |                        | Traefik       | logrotate     |
| Grafana       | 3000     | 192.168.1.x     | /           | https://192.168.1.x:3000/        |                        | App           | Docker        |
| Prometheus    | 9090     | 192.168.1.x     | /           | https://192.168.1.x:9090/        | http://prometheus:9090 | Traefk        | Docker        |
| Loki          |          |                 |             |                                  | http://loki:3100       |               | Docker        |
| Node Exporter | 9101     | 192.168.1.x     | /           | https://192.168.1.x:9101/metrics |                        | IPTABLES      | stdout        |
| Duplicati     | 8200     | 192.168.1.x     | /           | https://192.168.1.x:8200/        |                        | Traefik       | logrotate     |
| qBittorrent   | 8080     | 192.168.1.x     | /           | https://192.168.1.x:8080/        |                        | App           | logs disabled |
| Jackett       | 9117     | 192.168.1.x     | /           | https://192.168.1.x:9117/        | http://localhost:9117  | Traefik       | logs disabled |
| Sonarr        | 8989     | 192.168.1.x     | /           | https://192.168.1.x:8989/        |                        | App           | Self          |
| Radarr        | 7878     | 192.168.1.x     | /           | https://192.168.1.x:7878/        |                        | App           | Self          |
| Dionaea       | Multiple | 192.168.50.x    |             |                                  |                        |               | logrotate     |
| Cowrie        | 22,23    | 192.168.51.x    |             |                                  |                        |               | logrotate     |

# Notes
### Log Rotation
Is setup on the host machine due to permission issues and the requirement to send SIGHUP signals  

### Honeypots
Honeypot's cannot be accessed by localhost due to macvlan network

### Custom CA Cert
To use your own ca-signed certificates rename `config/traefik/dynamic/certs.yml.example` to `config/traefik/dynamic/certs.yml` and place `ca.crt`,`server.crt`, and `server.key` in `config/traefik/certs`

# Uninstall
- Move the `backups` and `cloud` folders to a safe location to preserve your data  
- Run `./setup.sh --clean`  
- Remove entries from `/etc/hosts` on your local machine
