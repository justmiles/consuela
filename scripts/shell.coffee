# Description:
#   Attaches node's child_process module to hubot for easy interaction with the host
#
# Dependencies:
#   None
#
# Configuration:
#   BASH_GROUP - Role authorized to execute bash commands from hubot
#
# Commands:
#   hubot (run|bash|exec) <command> = Executes the command on hubot's host
#   hubot (run|bash|exec) <command> on <hostname> = Executes the command on the supplied host using ssh. eg `ssh <hostname> -C "<command>"
#   hubot sh <command> = Executes a forked command on hubot's host, streaming the results back to chat.
#
# Author:
#  justmiles

Shell = require '../lib/SlackShell'

module.exports = (robot) ->
  robot.shell = new Shell()

  robot.respond /(sh) (.*)/i, (msg) ->
      robot.shell.spawnCommand msg.match[2], msg

  robot.respond /(run|bash|exec) (.*)/i, (msg) ->
      robot.shell.execCommand msg.match[2], msg

