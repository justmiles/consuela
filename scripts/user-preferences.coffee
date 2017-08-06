# Description:
#   Sets individual key/value pairs for users and saves them to the Hubot brain
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot set preference <key> = <value> - Sets the value for supplied preference
#   hubot show preference <key> = Returns the value for supplied preference
#   hubot delete preference <key> = Deletes the supplied preference
#   hubot show preferences = Returns a list of defined preferences
#
# Author:
#   Miles Maddox


module.exports = (robot) ->

  # Example: set preference MyValue = 5
  robot.respond /(set preference)([^=]*)( = )(.*)?/i, (msg) ->

    # Get the user from our brain
    user = robot.brain.userForName msg.message.user.name
    user.preferences or= {}
    # Clean up and define our key/value par to be saved.
    key = msg.match[2].replace ' ', ''
    value = msg.match[4].replace /\= /g, ''

    # Set the actual value (this saves automatically)
    user.preferences[key] = value
    msg.reply "Setting `#{key}` to `#{value}` for your account."
    robot.brain.save()

  # Example: show preference MyValue
  robot.respond /(show preference) (.*)/i, (msg) ->

    # Get the user from our brain
    user = robot.brain.userForName msg.message.user.name
    user.preferences or= {}

    # Find the key from the second matched group
    key = msg.match[2]

    # If the key exists, display it to the user
    if user.preferences[key]?
      value = user.preferences[key]
      msg.send "Your preference `#{key}` is set to `#{value}`"

    else
      msg.send "No value found for preference '#{key}'"

  # Example: delete preference MyValue
  robot.respond /(delete preference) (.*)/i, (msg) ->

    # Get the user from our brain
    user = robot.brain.userForName msg.message.user.name
    user.preferences or= {}

    # Find the key from the second matched group
    key = msg.match[2]

    # If the key exists, display it to the user
    if user.preferences[key]?
      value = user.preferences[key]
      delete user.preferences[key]
      msg.send "Your preference `#{key}` has been deleted"

    else
      msg.send "No value found for '#{key}'"

  robot.respond /show preferences/i, (msg) ->

    # Get the user from our brain
    user = robot.brain.userForName msg.message.user.name
    user.preferences or= {}

    if Object.keys(user.preferences).length > 0
      msg.send Object.keys(user.preferences).toString()

    else
      msg.send 'Good job, minimalist. You have no preferences.'
