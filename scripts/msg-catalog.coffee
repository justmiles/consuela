# Description:
#   Catalogs messages to the hubot brain
#
# Commands:
#   None
#
# Author:
#   justMiles

Firebase                = require 'firebase'
FirebaseTokenGenerator  = require 'firebase-token-generator'


module.exports = (robot) ->

  client = new Firebase(process.env.FIREBASE_URL + '-msgCatalog')

  if process.env.FIREBASE_SECRET?
    robot.logger.info "msg-catalog: Attempting to authenticate using FIREBASE_SECRET"

    tokenGenerator = new FirebaseTokenGenerator process.env.FIREBASE_SECRET
    token = tokenGenerator.createToken({ "uid": "custom:hubot", "hubot": true });
    client.authWithCustomToken token, (error, authData) ->
      if error
        robot.logger.warning 'msg-catalog: Login Failed!', error
      else
        robot.logger.info 'msg-catalog: Authenticated successfully'

  robot.hear /.*/i, (msg) ->
    return unless msg.message.rawText?
    date = new Date()
    yyyyMM = "#{date.getFullYear()}-#{("0" + (date.getMonth() + 1)).slice(-2)}"
    bucket = client.child(msg.message.room + '/' + yyyyMM)
    bucket.push
      user: msg.message.user.real_name
      text: msg.message.text
      epoch: Math.round(msg.message.id)

#  robot.respond /gtest/i, (msg) ->
#    x = client.child(msg.message.room)
#    x.orderByChild('epoch').startAt(Math.round((new Date()).getTime() / 1000)).once "child_added", (snapshot) ->
#      console.log(snapshot.val())
