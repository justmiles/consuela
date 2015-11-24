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
    cp.exec command, (error, stdout, stderr) ->
      msg.send "```#{error}```" if error?

      if stdout? && stdout != ''
        strlen = stdout.toString().length
        if strlen > 3000
          msg.send 'Splitting lines'
          lines = stdout.toString().split('\n')
          for splitter in [0..(Math.ceil(strlen/3000))]
            last = splitter
            msg.send "```#{lines.slice(last, lines.length / splitter).join('\n')}```"
          msg.send "```#{lines.slice(lines.length / 2, lines.length + 1).join('\n')}```"

        msg.send "```#{stdout.toString().length}```"
        msg.send "```#{stdout.toString()}```"

      if stderr? && stderr != ''
        msg.send "```STDERR: #{stderr.toString()}```"

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
