# Description:
#   Installs external scripts from NPM
#
# Commands:
#   hubot install <script> - Installs <script> saving to external-scripts.json and killing the hubot process. Requires
# a process monitor like PM2 or Forever to restart the process.
#
# Author:
#   justMiles
#

"use strict"

async = require 'async'
cp = require 'child_process'
fs = require 'fs'

module.exports = (robot) ->

  robot.respond /install (.*)/i, (msg) ->
    x = msg.match[1]

    async.waterfall [

      (cb) ->
        spawn = cp.spawn('npm', [ 'install', x ])

        resp = ''
        spawn.stdout.on 'data', (data) ->
          resp += data;

        spawn.on 'close', (code) ->
          if code == 0
            cb()
          else
            cb "npm install failed for `#{x}`"

      (cb) ->
        externalScripts = require '../external-scripts.json'
        externalScripts.push x
        console.log externalScripts
        fs.writeFileSync  'external-scripts.json', JSON.stringify(externalScripts, null, 2)
        msg.send "Package #{x} has been installed"
        msg.send "Rebooting.."
        cb()

      (cb) ->
        process.exit()

    ], (err, res) ->
      if err
        msg.send "Install failed: #{err}"

