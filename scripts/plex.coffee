# Commands:
#	 hubot add magnet <magnet> - Adds the supplied magnet to uTorrent
#	 hubot list downloads - Shows a list of currently pending downloads.
#	 hubot clean torrents - Cleans finished torrents from the server
#	 hubot search movies for <query> - Returns a list of available downloads

uTorrent    = require '../lib/utorrent.coffee'
jsonQuery   = require 'json-query'
scrape      = require 'scrape-url'
async       = require 'async'

tpb = 'https://thepiratebay.cr'

searchResource = (url, max_results,  cb) ->
  scrape url, ['#searchResult a'], (error, matches) ->
    results = []
    for match in matches
      href = match[0].attribs.href
      if href.match /^magnet/
        result =
          title: match[0].parent.children[1].children[1].children[0].data
          magnet: href
          seeders: match[0].parent.next.next.children[0].data
          leechers: match[0].parent.next.next.next.next.children[0].data
        results.push result
        if results.length > max_results
          return cb results
    return cb results

searchMovies = (query, max_results,  cb) ->
  searchResource "#{tpb}/search/#{query}/0/7/207", max_results, (res) ->
    cb res

searchTVShows = (query, max_results,  cb) ->
  searchResource "#{tpb}/search/#{query}/0/7/208", max_results, (res) ->
    cb res

formatSizeUnits = (bytes) ->
  if bytes >= 1000000000
    bytes = (bytes / 1000000000).toFixed(2) + ' GB'
  else if bytes >= 1000000
    bytes = (bytes / 1000000).toFixed(2) + ' MB'
  else if bytes >= 1000
    bytes = (bytes / 1000).toFixed(2) + ' KB'
  else if bytes > 1
    bytes = bytes + ' bytes'
  else if bytes == 1
    bytes = bytes + ' byte'
  else
    bytes = '0 byte'
  return bytes

Number::toHHMMSS = ->
  sec_num = parseInt(this, 10)
  # don't forget the second param
  hours = Math.floor(sec_num / 3600)
  minutes = Math.floor((sec_num - (hours * 3600)) / 60)
  seconds = sec_num - (hours * 3600) - (minutes * 60)
  if hours < 10
    hours = '0' + hours
  if minutes < 10
    minutes = '0' + minutes
  if seconds < 10
    seconds = '0' + seconds
  time = hours + ' hours, ' + minutes + ' minutes'
  return time

module.exports = (robot) ->

  uTorrentClient = new uTorrent()

  uTorrentClient.listTorrents (err, res) ->
    if (err)
      robot.logger.error 'Failed to listTorrents'
    else
      robot.logger.info 'Successfully loaded torrents'
      robot.brain.data.torrents = res


  robot.respond /(add url|add magnet) (.*)/i, (msg) ->
    uTorrentClient.addUrl msg.match[2], (err, res) ->
      if (err)
        msg.send 'Failed to add magnet link'
      else
        msg.send 'Successfully added magnet'

  robot.respond /what is plex downloading/i, (msg) ->
    query = jsonQuery("[torrentQueueOrder=1].name", {data: robot.brain.data.torrents})
    console.log query
    msg.send query.value

  robot.respond /list (torrents|downloads)/i, (msg) ->
    uTorrentClient.listTorrents (err, res) ->
      if (err)
        robot.logger.error 'Failed to listTorrents'
      else
        for torrent in res
          attachment =
            color: "#f0faf3",
            title: "#{torrent.name}",
            title_link: "http://www.imdb.com/find?q=#{torrent.name}",
            "author_icon": "http://flickr.com/icons/bobby.jpg",
            text: "#{Math.floor(torrent.downloaded / (torrent.downloaded + torrent.remaining) * 100)}% Downloaded. About #{torrent.eta.toHHMMSS()} remaining",
            fields: [
              {
                title: "Remaining",
                value: "#{formatSizeUnits(torrent.remaining)}",
                short: true
              },
              {
                title: "Peers Connected",
                value: "#{torrent.peersConnected}",
                short: true
              },
              {
                title: "uploadSpeed",
                value: "#{formatSizeUnits(torrent.uploadSpeed)}s",
                short: true
              },
              {
                title: "downloadSpeed",
                value: "#{formatSizeUnits(torrent.downloadSpeed)}s",
                short: true
              }
            ]

          robot.emit 'slack-attachment',
            message:
              room: msg.message.room
            content: attachment

  robot.respond /clean torrents/i, (msg) ->
    num = 0
    uTorrentClient.listTorrents (err, res) ->
      return msg.send 'Failed to get torrents' if err
      async.forEachOf res, ((torrent, key, callback) ->
        return callback() unless torrent.remaining > 0 #TODO: remove these based on status
        uTorrentClient.removedataTorrent torrent.hash, (err, res) ->
          msg.send err if err
          num += 1 unless err
          callback()
        ), (err) ->
          msg.send "Cleaned up #{num} torrents!"


  robot.respond /search (movies|shows) for (.*)/i, (msg) ->
    processResults = (movies) ->
      if movies.length > 0
        robot.brain.data.movies = movies
        for movie,i in movies
          attachment =
            fallback: movie.title,
            color: "#f0faf3",
            title: movie.title,
            title_link: "#{process.env.SITE_URI}/start/#{i}",
            fields: [
              {
                title: "Seeders",
                value: "#{movie.seeders}",
                short: true
              },
              {
                title: "Leechers",
                value: "#{movie.leechers}",
                short: true
              }
            ]

          robot.emit 'slack-attachment',
            message:
              room: msg.message.room
            content: attachment

      else
        msg.send 'No results'

    switch msg.match[1]
      when 'shows'
        searchTVShows msg.match[2], 5, processResults
      when 'movies'
        searchMovies msg.match[2], 5, processResults


  robot.router.get '/start/:id', (req, res) ->
    if robot.brain.data.movies[req.params.id].magnet?
      uTorrentClient.addUrl robot.brain.data.movies[req.params.id].magnet, ()->
        res.send 'Started.'
    else
      res.send 'Something failed.'
