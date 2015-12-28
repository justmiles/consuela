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

module.exports = (robot) ->

  client = new qBittorrent
    username: process.env.QBITTORRENT_USERNAME
    password: process.env.QBITTORRENT_PASSWORD
    host: process.env.QBITTORRENT_HOST
    port: process.env.QBITTORRENT_PORT

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
