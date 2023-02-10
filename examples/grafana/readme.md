### Example Using Grafana
Grafana can be leveraged to build a statistics dashboard for transcoded media.

#### Steps Required
1. Add Grafana to your docker-compose file.
```yml
version: "3.8"
services:
  Docker-TranscodeAutomation:
    image: ghcr.io/thetaylorlee/docker-transcodeautomation:latest
    container_name: Docker-TranscodeAutomation
    environment:
      - BACKUPPROCESSED=true
      - BACKUPRETENTION=14
      - MEDIAMOVIEFOLDERS=/media/test/movies, /media/test/movies02
      - MEDIASHOWFOLDERS=/media/test/shows
      - MOVIESCRF=21
      - SHOWSCRF=23
    volumes:
      - /home/user/docker/appdata/docker-transcodeautomation/data:/docker-transcodeautomation/data
      - /home/user/docker/appdata/docker-transcodeautomation/transcoding:/docker-transcodeautomation/transcoding
      - /media:/media
    restart: unless-stopped
  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana
    privileged: true
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Chicago/Illinois
    ports:
      - "3000:3000"
    volumes:
      - /home/user/docker/appdata/grafana-data:/var/lib/grafana
      - /home/user/docker/appdata/docker-transcodeautomation/data/MediaDB.SQLite:/mydb/MediaDB.SQLite
```
2. Navigate to Grafana http://localhost:3000
3. In Configuration > Data Sources > Plugins, install the SQLite plugin
4. In Datasources add a new sqlite datasource with the path /mydb/MediaDB.SQLite and a name of MediaDB (Leave the other options untouched)
5. Go to Dashboards > Import, [paste the json from here](https://raw.githubusercontent.com/TheTaylorLee/docker-transcodeautomation/master/examples/grafana/grafana-dashboard.json), and then click import
6. You now have a dashboard for displaying statistics. If you haven't been running docker-transcodeautomation previously, no statistics will exist yet for the dashboard to display.
![Grafana Dashboard](https://raw.githubusercontent.com/TheTaylorLee/docker-transcodeautomation/master/examples/grafana/dashboard-grafana.png)