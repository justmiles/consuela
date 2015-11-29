cp = require 'child_process'

class SlackShell

  run : (command, callback) ->
    args = command.split(' ')
    process = args.splice(0, 1)

    spawn = cp.spawn(process[0], args)

    spawn.stdout.on 'data', (data) ->
      callback '' + data

    spawn.stderr.on 'data', (data) ->
      callback 'stderr: ' + data

    spawn.on 'close', (code) ->
      if code != 0
        callback 'process exited with code ' + code

  spawnCommand : (command, msg) ->
    args = command.split(' ')
    process = args.splice(0, 1)
    @spawnCommandArgs process[0], args, msg

  spawnCommandArgs : (command, args, msg) ->
    spawn = cp.spawn(command, args)
    intervalId = setInterval (->
      if exports.data
        msg.send "```#{exports.data}```"
      exports.data = '';
    ), 1000

    spawn.stdout.on 'data', (data) ->
      exports.data += data;

    spawn.stderr.on 'data', (data) ->
      msg.reply "stderr for the command `#{command}`:"
      msg.send "```#{data.toString()}```"

    spawn.on 'close', (code) ->
      setTimeout (->
        clearInterval intervalId
      ), 2000

      if code != 0
        msg.reply "Command `#{command}` exited with exit code `#{code}`"

  execCommand : (command, msg) ->
    respond = (str, wrap = '```') ->
      len = 3000
      _size = Math.ceil(str.length / len)
      _ret = new Array(_size)
      _offset = undefined
      _i = 0
      while _i < _size
        _offset = _i * len
        _ret[_i] = str.substring(_offset, _offset + len)
        _i++

      x = 0
      setInterval (->
        msg.send "#{wrap}#{_ret[x]}#{wrap}"
        if _ret.length == x+1
          clearInterval this
        else
          x++

      ), 2000

    cp.exec command, (error, stdout, stderr) ->
      respond error if error?

      if stdout? && stdout != ''
        respond stdout

      if stderr? && stderr != ''
        msg.send "`STDERR:`"
        respond stdout, '`'

  execLogCommand : (command, logger) ->
    cp.exec command, (error, stdout, stderr) ->
      if error?
        logger "Command `#{command}` failed"

      if stdout?
        logger "```#{stdout.toString()}```"

      if stderr?
        logger "Received standard error when executing `#{command}`."
        logger "```STDERR: #{stderr.toString()}```"

  execSyncCommand : (command, msg) -> #requires node > v0.12.0
    try
      msg.send "Executing `#{command}`"
      data = cp.execSync command, { maxBuffer: 20000}
      if data
        msg.send "```#{data.toString()}```"

      else
        msg.send 'didnt get data'
    catch ex
      console.log ex
      msg.reply "Too much to buffer when executing `#{command}`."

module.exports = SlackShell
