#!/usr/bin/env coffee
pm2 		= require 'pm2'
app_package = require "#{__dirname}/package.json"
os 			= require 'os'
Path		= require 'path'
Fs			= require 'fs'

app =
  name: app_package.name
  script: "coffee"
  args: [ "#{__dirname}/node_modules/hubot/bin/hubot", "--name", app_package.name, '--adapter', 'slack']
  exec_mode: 'fork'
  watch: "#{__dirname}/scripts"
  merge_logs: true
  cwd: "#{__dirname}/"
  out_file: "#{__dirname}/logs/#{app_package.name}.log"
  error_file: "#{__dirname}/logs/#{app_package.name}.errors.log"
  log_date_format: "YYYY-MM-DD HH:mm"
  instances: 1
  max_memory_restart: '256M'
  env: require "#{__dirname}/config.json"

parameters = process.argv.map (arg,next)->
  if arg.match /-\S/
    switch arg
      when '-v'
        console.log app_package.version

startShell = () ->
  for envvar of app.env
    process.env[envvar] = app.env[envvar]
  Hubot = require 'hubot'
  Options =
    adapter:     'shell'
    alias:       false
    enableHttpd: true
    scripts:     []
    name:        app_package.name
    path:        "../"
    configCheck: false

  adapterPath = "#{__dirname}/node_modules/hubot/src/adapters/"
  robot = Hubot.loadBot adapterPath, Options.adapter, Options.enableHttpd, Options.name, Options.alias

  loadScripts = ->
    scriptsPath = "#{__dirname}/scripts"
    robot.load scriptsPath

    hubotScripts = Path.resolve ".", "hubot-scripts.json"
    if Fs.existsSync(hubotScripts)
      data = Fs.readFileSync(hubotScripts)
      if data.length > 0
        try
          scripts = JSON.parse data
          scriptsPath = Path.resolve "node_modules", "hubot-scripts", "src", "scripts"
          robot.loadHubotScripts scriptsPath, scripts
        catch err
          console.error "Error parsing JSON data from hubot-scripts.json: #{err}"
          process.exit(1)

    externalScripts = Path.resolve ".", "external-scripts.json"
    if Fs.existsSync(externalScripts)
      Fs.readFile externalScripts, (err, data) ->
        if data.length > 0
          try
            scripts = JSON.parse data
          catch err
            console.error "Error parsing JSON data from external-scripts.json: #{err}"
            process.exit(1)
          robot.loadExternalScripts scripts

    for path in Options.scripts
      if path[0] == '/'
        scriptsPath = path
      else
        scriptsPath = Path.resolve ".", path
      robot.load scriptsPath

  robot.adapter.on 'connected', loadScripts
  robot.run()

switch process.argv[2]

  when 'start'
    return startShell() if process.argv[3] == 'shell'
    pm2.connect ->
      pm2.start app, (err, apps) ->
        if err != null
          console.log err.msg
        else
          console.log app_package.name + ' started'
        pm2.disconnect()

  when 'stop'
    pm2.connect ->
      pm2.delete app_package.name, (err, proc) ->
        if err != null
          console.log err.msg
        else
          console.log app_package.name + ' stopped'
        pm2.disconnect()

  when 'restart'
    pm2.connect ->
      pm2.stop app_package.name, (err, proc) ->
        if err != null
          console.log err.msg
        else
          console.log app_package.name + ' stopped'

          pm2.flush (err, ret)->
            if err?
              console.log err
            pm2.start app, (err, apps) ->
              if err != null
                console.log err.msg
              else
                console.log app_package.name + ' started'
              pm2.disconnect()

  when 'status'
    pm2.connect ->
      return pm2.describe app_package.name, (err, proc) ->
        i = 0; len = proc.length
        while i < len
          process = proc[i]
          if process.name == app_package.name and process.pid != 0
            found = true
            console.log "#{app_package.name} is running on #{os.hostname()}, process #{process.pid}"
            console.log "   Uptime: #{millisecondsToString((new Date().getTime()) - process.pm2_env.created_at)}"
            console.log "   Restarts: #{process.pm2_env.restart_time}"
          i++
        if !found
          console.log "#{app_package.name} is not running"
        pm2.disconnect()

  when 'logs'
    console.log app.env
    cp = require 'child_process'
    console.log "Tailing #{app.out_file}"
    log = cp.spawn('tail', [
      '-f'
      app.out_file
    ])
    log.stdout.on 'data', (data) ->
      console.log data.toString()

    log.stderr.on 'data', (data) ->
      console.log 'stderr: ' + data

  else
    console.log("Usage: #{app_package.name} (start|start shell|stop|status|restart)")


millisecondsToString = (milliseconds) ->
  seconds = milliseconds / 1000
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