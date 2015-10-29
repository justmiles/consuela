# Commands:
#	 hubot status - Displays the process and host hubot is running on.
#	 hubot restart - Restarts hubot (requires rundeck_ops role).
#	 hubot update - Updates hubot (requires rundeck_ops role).


exec = require('child_process').exec
shell = require('./shell')

module.exports = (robot) ->

  robot.respond /restart/i, (msg) ->
    msg.emote 'rebooting...'
    robot.shell.execCommand './bin/hubot-plex.sh restart', msg

  robot.respond /update/i, (msg) ->
    msg.emote 'updating...'
    robot.shell.execCommand './bin/hubot-plex.sh update', msg

  robot.respond /status/i, (msg) ->
    robot.shell.execCommand 'hostname', msg

  robot.router.post '/hubot-plex/update', (req, res) ->
    res.send('OK');
    robot.shell.execCommand './bin/hubot-plex.sh update', msg
