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

      SCOPES = ['https://www.googleapis.com/auth/calendar']
      JSONPATH = __dirname + '/json/'
      OAuth2  = google.auth.OAuth2

      env.logger.debug "Plugin"

      fs.readFile (JSONPATH + 'client_secret.json'), (err, content) ->
        if err
          env.logger.error "Error loading client secret " + err
        else
          #Reading Content from client secret json
          content = JSON.parse content
          clientSecret = content.installed.client_secret
          clientId = content.installed.client_id
          redirectUrl = content.installed.redirect_uris[0]

          #Auth Client erzeugen
          @oauth2Client = new OAuth2(clientId, clientSecret, redirectUrl);

      #Überprüfen ob Token vorhanden
      fs.readFile (JSONPATH + 'token.json'), (err, token) -> 
        if err 
          #Wenn Nein neuen erzeuge
          #URL für USER erzeugen um token zu erhalten
          authUrl = @oauth2Client.generateAuthUrl(
            access_type: 'offline'
            scope: SCOPES)
          #Loggen in Console
          env.logger.info 'Authorisation URL:'
          env.logger.info authUrl
          #Öffnen eines Popups im mobile frontend
          #Wie ?
          
          #Termplösung über Readline
          rl = readline.createInterface(
            input: process.stdin
            output: process.stdout)
          rl.question 'Enter the code from that page here: ', (code) ->
            rl.close()

            #Holen des Tokens
            @oauth2Client.getToken code, (err, tokens) ->
              if err
                env.logger.err "No Token received " + err
              else
                @oauth2Client.credentials = tokens
                fs.writeFile JSONPATH + 'token.json', JSON.stringify tokens
                env.logger.debug "Stored Token to " + JSONPATH + 'token.json'
        else
          #Wenn Ja diesen verwenden
          @oauth2Client.credentials = JSON.parse token

      #Device erzeugen
      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass("CalendarListDevice", {
        configDef: deviceConfigDef.CalendarListDevice,
        createCallback: (config, oauth2Client) => new CalendarListDevice(config, @oauth2Client)
      })
   
  #CalendarListDevice Class
  class CalendarListDevice extends env.devices.Device

    constructor: (@config, @oauth2Client) ->
      @id = @config.id
      @name = @config.name

      env.logger.debug "Device"

      console.log @oauth2Client

      super()

      getEventList: (auth) ->
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
            env.logger.error "API returned error " + err
          else
            events = response.items

            #List events on mobile frontend
            if events.length == 0
              #Keine Termien
            else
              #Termine als Liste darstellen

  #CalendarListDevice End

  plugin = new GoogleCalendar
  return plugin
  