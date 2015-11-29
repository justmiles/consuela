app = require '../package.json'

module.exports = (robot) ->

  robot.respond /what'?s your package (\S*)/i, (msg) ->
    res = app[msg.match[1]]
    return msg.send "I've got nothing for `#{msg.match[1]}`" unless res?
    if typeof res == 'object'
      msg.send "```#{JSON.stringify(res, null, 2)}```"
    else
      msg.send res