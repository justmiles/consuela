class Logger
  constructor: (@slackMsg, @robot, @enableDebugging) ->

  log: (message) ->
    if @slackMsg?
      @slackMsg.send message

    else if @robot
      @robot.logger.info message

    else
      console.log "INFO: #{message}"

  debug: (message) ->
    if @enableDebugging
      console.log "DEBUG: #{message}"

module.exports = Logger