# Description:
#   Catalogs messages to the hubot brain
#
# Commands:
#   None
#
# Dependencies:
#   firebase-brain
# 
# Author:
#   justMiles

module.exports = (robot) ->

  robot.hear /.*/i, (msg) ->
    return unless msg.message.rawText?
    return unless robot.firebaseBrain?
      
    date = new Date()
    yyyyMM = "#{date.getFullYear()}-#{("0" + (date.getMonth() + 1)).slice(-2)}"
    bucket = robot.firebaseBrain.child('msg-catalog').child(msg.message.room + '/' + yyyyMM)
    bucket.push
      user: msg.message.user.real_name
      text: msg.message.text
      epoch: Math.round(msg.message.id)
