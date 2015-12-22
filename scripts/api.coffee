
app = require '../package.json'

module.exports = (robot) ->
  robot.router.post '/message/:room', (req, res) ->
    robot.messageRoom req.params.room, req.body.message
    res.send 'OK'

  robot.router.get '/app', (req, res) ->
    res.json app

