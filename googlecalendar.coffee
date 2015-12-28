module.exports = (env) ->

  #Version 0.1.0

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'

  google = require 'googleapis'

  fs = require 'fs'
  readline = require 'readline'

  # GoogleCalendar class
  class GoogleCalendar extends env.plugins.Plugin

  	init: (app, @framework, @config) =>
      clientId     = @config.clientid
      clientSecret = @config.clientsecret

      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass("CalendarListDevice", {
        configDef: deviceConfigDef.CalendarListDevice,
        createCallback: (config) => new CalendarListDevice(config, @framework)
      })

      env.logger.debug "Plugin"

      @pendingAuth = new Promise ( (resolve, reject) =>
        redirectUrl = "urn:ietf:wg:oauth:2.0:oob"
        #start Auth
        OAuth2 = google.auth.OAuth2
        oauth2Client = new OAuth2 clientId, clientSecret, redirectUrl
        # Check if we have previously stored a token.
        fs.readFile __dirname + '/json/tokens.json', (erro, token) ->
          if erro
            env.logger.debug "Creating a new Token Request because"
            env.logger.debug erro
            authUrl = oauth2Client.generateAuthUrl(
              access_type: 'offline'
              scope: 'https://www.googleapis.com/auth/calendar')
            #Replace with Popup if possible
            env.logger.info  'Authorize this app by visiting this url: ', authUrl
            rl = readline.createInterface(
              input: process.stdin
              output: process.stdout)
            rl.question 'Enter the code from that page here: ', (code) ->
              rl.close()
              oauth2Client.getToken code, (err, token) ->
              if err
                err = 'Error while trying to retrieve access token ' + err
                reject err
              else
                console.log "token" + token
                oauth2Client.credentials = token
                fs.writeFile __dirname + '/json/tokens.json', JSON.stringify(token), (er) ->
                  if er 
                    reject er
                  else
                    env.logger.info 'Token stored to ' + __dirname + '/json/tokens.json'
                    #env.logger.debug oauth2Client
                    resolve oauth2Client
          else
            oauth2Client.credentials = JSON.parse(token)
            #env.logger.debug oauth2Client
            resolve oauth2Client
      );      
      

  plugin = new GoogleCalendar

  #CalendarListDevice Class
  class CalendarListDevice extends env.devices.Device

    attributes:
      events:
        description: "Your google calendar events"
        type: "array"
    
    constructor: (@config, @framework) ->
      @id = @config.id
      @name = @config.name
      @auth = @getAuth()
      #events = @listEvents(@auth)
      console.log events
      #Run listEvents and then push events to frontend

      super()
    
    getAuth: ->      
      plugin.pendingAuth.then( (authInfo) =>
  		  env.logger.debug authInfo
        @auth = authInfo
        #return authInfo
      ).catch ((err) ->
        env.logger.error err
        #@auth = null
      )

    listEvents: (auth) ->
      calendar = google.calendar('v3')
      calendar.events.list {
        auth: auth
        calendarId: 'primary'
        timeMin: (new Date).toISOString()
        maxResults: 10
        singleEvents: true
        orderBy: 'startTime'
      }, (err, response) ->
        if err
          env.logger.error 'The API returned an error: ' + err
  
        #events = response.items 
        return response.items
        ###
        if events.length == 0
          env.logger.debug 'No upcoming events found.'
        else
          env.logger.debug 'Upcoming 10 events:'
          i = 0
          while i < events.length
            event = events[i]
            start = event.start.dateTime or event.start.date
            env.logger.debug start + " - " + event.summary
            #console.log event
            i++
        ###

    getEvents: (events) -> Promise.resolve(events)

  #CalendarListDevice End
  return plugin
  