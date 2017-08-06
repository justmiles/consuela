# Description:
#   Script to interact with qBittorrent server
#
# Commands:
#   hubot log <duration> hrs of <task> for <project> | <description of work> - Creates a timesheet entry for your described task
#   hubot list timesheet projects - returns a list of active Zoho projects
#   hubot show timesheet - returns timesheet details for this week
#   hubot show timesheet for this month - returns timesheet details for this month
#
#
# Configuration:
#   ZOHO_AUTHTOKEN - Auth token to authenticate to the Zoho API
#
# Author:
#   justMiles
#

ZohoSDK    = require 'zoho-sdk'
require 'datejs'

module.exports = (robot) ->
  unless process.env.ZOHO_AUTHTOKEN
    robot.logger.error 'ZOHO_AUTHTOKEN not set'
    process.exit(1)

  books = new ZohoSDK.Books()
  
  robot.respond /log (([0-9]+)?(\.[0-9]+)?) hrs? of (\S*) for (\S*)( \| ?(.*))?/i, (msg) ->
    ts = new Date(0)
    ts.setUTCSeconds(msg.message.id)
    
    query =
      hours: msg.match[1]
      task: msg.match[4]
      project: msg.match[5]
      notes: msg.match[7]
    
    books.getActiveProjectByName query.project, (err, project) ->
      return msg.send err if err
      query.project = project.project_name
      
      books.getTaskByName query.task, project.project_id, (err, task) ->
        return msg.send err if err
        query.task = task.task_name
      
        books.getProjectUserByEmail msg.message.user.name, project.project_id, (err, user) ->
          return msg.send err if err
          query.user = user.user_name
      
          books.logTimeEntry
            project_id: project.project_id
            task_id: task.task_id
            user_id: user.user_id
            log_date: ts.toString 'yyyy-MM-dd'
            log_time: (new Date).clearTime().addHours(query.hours).toString('HH:mm')
            notes: query.notes
          , (err, res) ->
              return msg.send err if err
              emitTimeEntry res.time_entry, msg
    
  robot.respond /list timesheet projects/i, (msg) ->
    msg.send 'nope'
    books.listProjects filter_by: 'Status.Active', (err, res) ->
      response = ''
      for project in res.projects
        response += "#{project.project_name}\n"
      msg.send response

  robot.respond /show timesheet( for this (week|month))?/i, (msg) ->
    if msg.match[2] == 'month'
      filter = 'Date.ThisMonth'
    else
      filter = 'Date.ThisWeek'
    
    books.listTimeEntries filter_by: filter, (err, res) ->

      res.time_entries.sort (a, b) ->
        new Date(b.created_time) - (new Date(a.created_time))

      for entry in res.time_entries
        emitTimeEntry entry, msg

  # Utilities
  emitTimeEntry = (entry, msg) ->
    robot.emit 'slack-attachment',
      message: msg.message
      content: 
        color: "#f0faf3",
        author_name: entry.user_name,
        title: entry.project_name,
        ts: (new Date(entry.created_time) / 1000 ),
        fields: [
          {
            title: "#{entry.log_time} hrs of #{entry.task_name}"
            value: entry.notes
            short: false
          }
        ]