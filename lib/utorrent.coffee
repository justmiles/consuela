http = require("http")
util = require('util');



class uTorrent

# uTorrent WebAPI Calls
  addUrl: (magnetLink, callback) ->
    @XHR "GET", "/gui/?action=add-url&s=#{magnetLink}", null, callback

  listTorrents: (callback) ->
    @XHR 'GET', '/gui/?list=1', null, (err, res) ->
      if util.isArray(res.torrents)
        this.tor = []
        for torrent in res.torrents
          newTorrent =
            hash: torrent[0]
            status: torrent[1]
            name: torrent[2]
            size: torrent[3]
            percentProgress: torrent[4]
            downloaded: torrent[5]
            uploaded: torrent[6]
            ratio: torrent[7]
            uploadSpeed: torrent[8]
            downloadSpeed: torrent[9]
            eta: torrent[10]
            label: torrent[11]
            peersConnected: torrent[12]
            peersInSwarm: torrent[13]
            seedsConnected: torrent[14]
            seedsInSwarm: torrent[15]
            availability: torrent[16]
            torrentQueueOrder: torrent[17]
            remaining: torrent[18]
          this.tor.push newTorrent
        callback err, this.tor
      else
        callback err, res

  getSettings: (callback) ->
    @XHR "GET", "/gui/?action=getsettings", null, callback

  updateSetting: (setting, value, callback) ->
    @XHR "GET", "/gui/?action=setsetting&s=#{setting}&v=#{value}", null, callback

# Basic Actions
  startTorrent: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=start&hash=#{torrentHash}", null, callback

  stopTorrent: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=stop&hash=#{torrentHash}", null, callback

  pauseTorrent: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=pause&hash=#{torrentHash}", null, callback

  unpauseTorrent: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=unpause&hash=#{torrentHash}", null, callback

  forcestartTorrent: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=forcestart&hash=#{torrentHash}", null, callback

  recheckTorrent: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=recheck&hash=#{torrentHash}", null, callback

  removedataTorrent: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=removedata&hash=#{torrentHash}", null, callback

  setTorrentPriority: (torrentHash, priority, fileIndex, callback) ->
    @XHR "GET", "/gui/?action=setprio&hash=#{torrentHash}&p=#{priority}&f=#{fileIndex}", null, callback

# Queue Management
  queueBottom: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=queuebottom&hash=#{torrentHash}", null, callback

  queueUp: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=queueup&hash=#{torrentHash}", null, callback

  queueTop: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=queuetop&hash=#{torrentHash}", null, callback

  queueDown: (torrentHash, callback) ->
    @XHR "GET", "/gui/?action=queuedown&hash=#{torrentHash}", null, callback

#  Utils
  XHR: (method, api, params, callback) ->
    if params == null
      params = ""
    else
      params = uTorrent._toURL(params)


    options =
      host: process.env.UTORRENT_HOSTNAME
      port: process.env.UTORRENT_PORT
      path: api + params
      method: method
      auth: "#{process.env.UTORRENT_USERNAME}:#{process.env.UTORRENT_PASSWORD}"

    req = http.request options, (res) ->
      res.setEncoding "utf8"
      response = ""

      res.on "data", (data) ->
        response += data

      res.on "end", ->
        try
          jsonResponse = JSON.parse(response)
          return callback false, jsonResponse
        catch e
          console.error "Could not parse response. " + e
          console.error "Received: " + response
          return callback options, false

    req.on "error", (e) ->
      console.error "HTTPS ERROR: " + e
      return callback e, false

    req.write('')
    req.end()

  _toURL: (obj)->
    return "?" + Object.keys(obj).map((k) ->
        encodeURIComponent(k) + "=" + encodeURIComponent(obj[k])
      ).join("&")

module.exports = uTorrent

