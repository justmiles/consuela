module.exports = (robot) ->

  robot.router.get '/_ah/health', (req, res) ->
    res.send 'OK'

  robot.router.get '/_ah/start', (req, res) ->
    res.send 'OK'

  robot.router.get '/_ah/stop', (req, res) ->
    res.send 'OK'
    process.exit()

  robot.router.get '/', (req, res) ->
    res.send 401
