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
        createCallback: (config) => new CalendarListDevice(config)
      })

      @framework.on "after init", =>
        # Check if the mobile-frontent was loaded and get a instance
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-googlecalendar/devices/CalendarListDevice.coffee"
          mobileFrontend.registerAssetFile 'css', "pimatic-googlecalendar/devices/CalendarListDevice.css"
          mobileFrontend.registerAssetFile 'html', "pimatic-googlecalendar/devices/CalendarListDevice.html"
        else
          env.logger.warn "pimatic-googlecalendar could not find the mobile-frontend. No gui will be available"
    

      @pendingAuth = new Promise ( (resolve, reject) =>
        redirectUrl = "urn:ietf:wg:oauth:2.0:oob"
        #start Auth
        OAuth2 = google.auth.OAuth2
        oauth2Client = new OAuth2 clientId, clientSecret, redirectUrl
        # Check if we have previously stored a token.
        ###        fs.readFile __dirname + '/json/tokens.json', (erro, token) ->
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
                console.log "token: " + token
                o auth2Client.credentials = token
                fs.writeFile __dirname + '/json/tokens.json', JSON.stringify(token), (er) ->
                  if er 
                    reject er
                  else
                    env.logger.info 'Token stored to ' + __dirname + '/json/tokens.json'
                    #env.logger.debug oauth2Client
                    resolve oauth2Client
          else###
        oauth2Client.credentials = token
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

    template: 'CalendarListDeviceTemplate'
    
    constructor: (@config) ->
      @id = @config.id
      @name = @config.name    

      super()
    
    getEvents: -> 
      return plugin.pendingAuth.then( (authInfo) ->
        calendar = google.calendar('v3', auth: authInfo)
        unless calendar.events.listAsync?
          Promise.promisifyAll(calendar.events)
        return calendar.events.listAsync({
          calendarId: 'primary'
          timeMin: (new Date).toISOString()
          maxResults: 5
          singleEvents: true
          orderBy: 'startTime'
        }).then( (response) =>
          events = response.items
          @emit 'events', events
          Promise.resolve events # wohin wird übergeben
        )
      )


  #CalendarListDevice End
  return plugin
  