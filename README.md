# consuela
A Hubot implementation


# configs

```
## Slack
 HUBOT_SLACK_TOKEN 

## Firebase Brain
 FIREBASE_URL
 
## Optional Configs
 FIREBASE_SECRET
 HUBOT_ANNOUNCE_ROOMS
 QBITTORRENT_PORT
 QBITTORRENT_PASSWORD
 QBITTORRENT_USERNAME
 QBITTORRENT_HOST
 SITE_URI
```

# development
Export configs
`pm2-dev start npm -- start`

# deployment
Ensure Node and PM2 are in your path.
`pm2 -n consuela start npm -- start`
You don't have to use PM2 - any process monitor will suffice.

