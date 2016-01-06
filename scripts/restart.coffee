# Commands:
#	 hubot status - Displays the process and host hubot is running on.
#	 hubot restart - Restarts hubot (requires rundeck_ops role).
#	 hubot update - Updates hubot (requires rundeck_ops role).


{exec} = require 'child_process'
shell         = require './shell'
os            = require 'os'

secondsToString = (seconds) ->
  numyears = Math.floor(seconds / 31536000)
  numdays = Math.floor(seconds % 31536000 / 86400)
  numhours = Math.floor(seconds % 31536000 % 86400 / 3600)
  numminutes = Math.floor(seconds % 31536000 % 86400 % 3600 / 60)
  numseconds = (seconds % 31536000 % 86400 % 3600 % 60).toFixed(0)
  time = ''
  if numyears > 0
    time += numyears + ' Years '
  if numdays > 0
    time += numdays + ' Days '
  if numhours > 0
    time += numhours + 'h '
  if numminutes > 0
    time += numminutes + 'm '
  if numseconds > 0 or time == ''
    time += numseconds + 's'
  time

module.exports = (robot) ->

  robot.respond /restart/i, (msg) ->
    msg.emote 'rebooting...'
    robot.shell.execCommand './bin/hubot-plex.sh restart', msg

  robot.respond /update/i, (msg) ->
    msg.emote 'updating...'
    robot.shell.execCommand './bin/hubot-plex.sh update', msg

  robot.respond /status/i, (msg) ->
    msg.send "```Hostname: #{os.hostname()}\nUptime: #{secondsToString(os.uptime())}\nLoad Avg (1m, 5m, 15m): #{os.loadavg().map((x)-> "#{Math.floor(x * 100)}%").join(', ')}```"

  robot.router.post '/hubot-plex/update', (req, res) ->
    res.send('OK');
    robot.shell.execCommand './bin/hubot-plex.sh update', msg
