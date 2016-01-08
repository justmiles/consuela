# Description:
#   Script to interact with qBittorrent server
#
# Commands:
#   hubot get torrents - Returns full list of torrents
#
#
# Configuration:
#   QBITTORRENT_USERNAME - Username for qBittorrent Web UI
#   QBITTORRENT_PASSWORD - Password for qBittorrent Web UI
#   QBITTORRENT_HOST - qBittorrent Web UI hostname
#   QBITTORRENT_PORT - qBittorrent Web UI port
#
# Author:
#   justMiles
#

async             = require 'async'
cp                = require 'child_process'
fs                = require 'fs'
qBittorrent       = require 'qbittorrent-client'
fixedWidthString  = require 'fixed-width-string'
jsonQuery   = require 'json-query'
scrape      = require 'scrape-url'
async       = require 'async'
uuid        = require 'node-uuid'

module.exports = (robot) ->
  return unless process.env.QBITTORRENT_HOST
  client = new qBittorrent
    username: process.env.QBITTORRENT_USERNAME
    password: process.env.QBITTORRENT_PASSWORD
    host: process.env.QBITTORRENT_HOST
    port: process.env.QBITTORRENT_PORT

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

  slackObj = (msg, obj) ->
    if obj instanceof Array
      for child in obj
        slackObj(msg, child)
      return

    fields = []
    for key, value of obj
      fields.push
          title: key,
          value: value,
          short: true

    robot.emit 'slack-attachment',
      message:
        room: msg.message.room
      content:
        color: "#f0faf3",
        fields: fields

  slackArray = (msg, arr) ->
    headerRow = {}
    body = ''

    for child in arr
      return slackArrayAsTable msg, child if child instanceof Array

    for child in arr
      for key, val of child
        headerRow[key] or= 0
        if val.length > key.length
          newLength = val.length
        else
          newLength = key.length
        if newLength > headerRow[key]
          headerRow[key] = newLength

    for key, val of headerRow
      body += fixedWidthString(key, headerRow[key]) + "    "
    body += "\n"


    for x in arr
      for key, val of x
        body += fixedWidthString(val, headerRow[key]) + "    "
      body += "\n"

    msg.send "```#{body}```"

  slackTorrents = (msg, torrents) ->
    response = "#{fixedWidthString('Name', 40)}  #{fixedWidthString('ETA', 5)}  #{fixedWidthString('State', 10)}  #{fixedWidthString('Size', 10)}  #{fixedWidthString('Ratio', 5)}  #{fixedWidthString('Seeders', 8)}  #{fixedWidthString('Leechers', 8)}  #{fixedWidthString('Hash', 40)}\n"

    async.eachSeries torrents, ((torrent, callback) ->
      response += "#{fixedWidthString(torrent.name, 40)}  #{fixedWidthString(torrent.eta, 5)}  #{fixedWidthString(torrent.state, 10)}  #{fixedWidthString(torrent.size, 10)}  #{fixedWidthString(torrent.ratio, 5)}  #{fixedWidthString(torrent.num_seeds, 8)}  #{fixedWidthString(torrent.num_leechs,8)}  #{fixedWidthString(torrent.hash,40)}\n"
      callback()

    ), () ->
      msg.send "```#{response}```"


  robot.respond /(get|list|show) torrents/i, (msg) ->
    client.getTorrents (err, res) ->
      slackTorrents msg, JSON.parse(res) if res

  robot.respond /get torrent contents for (.*)/i, (msg) ->
    client.getTorrentContents msg.match[1], (err, res) ->
      slackArray msg, JSON.parse(res) if res

  robot.respond /get torrent trackers for (.*)/i, (msg) ->
    client.getTorrentTrackers msg.match[1], (err, res) ->
      slackArray msg, JSON.parse(res) if res

  robot.hear /torrent (\S{40})/i, (msg) ->
    client.getTorrent msg.match[1], (err, res) ->
      slackObj msg, JSON.parse(res) if res

  robot.respond /pause all torrents/i, (msg) ->
    client.pauseAllTorrents (err, res) ->
      if err
        msg.send err
      else
        msg.send 'All torrents paused'

  robot.respond /resume all torrents/i, (msg) ->
    client.resumeAllTorrents (err, res) ->
      if err
        msg.send err
      else
        msg.send 'All torrents resumed'

  robot.respond /search (movies|shows) for (.*)/i, (msg) ->
    processResults = (movies) ->
      if movies.length > 0
        for movie,i in movies
          movieKey = uuid.v4()
          robot.brain.data.torrents or= {}
          robot.brain.data.torrents[movieKey] = movie

          attachment =
            fallback: movie.title,
            color: "#f0faf3",
            title: movie.title,
            title_link: "#{process.env.SITE_URI}/start/#{movieKey}",
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
    if robot.brain.data.torrents[req.params.id].magnet?
      console.log(client.addTorrentFromURL)
      client.addTorrentFromURL robot.brain.data.torrents[req.params.id].magnet, (err, response)->
        console.log err if err
        console.log response if response
        res.send 'Started.'
    else
      res.send 'Something failed.'