module.exports = (env) ->

  Promise = env.require 'bluebird'
  t = env.require('decl-api').types
  Request = require 'request'

  api = "https://creativecommons.tankerkoenig.de/json/prices.php?ids={idPlaceholder}&apikey={apiKeyPlaceholder}"
  detailApi = "https://creativecommons.tankerkoenig.de/json/detail.php?id={idPlaceholder}&apikey={apiKeyPlaceholder}"

  mockIds = "446bdcf5-9f75-47fc-9cfa-2c3d6fda1c3b,60c0eefa-d2a8-4f5c-82cc-b5244ecae955,4429a7d9-fb2d-4c29-8cfe-2ca90323f9f8"
  mockResponse = {    "ok": true,    "license": "CC BY 4.0 -  https:\/\/creativecommons.tankerkoenig.de",    "data": "MTS-K",    "prices": {        "446bdcf5-9f75-47fc-9cfa-2c3d6fda1c3b": {            "status": "open",            "e5": 1.234,            "e10": 1.234,            "diesel": 1.234        },        "60c0eefa-d2a8-4f5c-82cc-b5244ecae955": {            "status": "open",            "e5": false,            "e10": false,            "diesel": 1.234        },        "4429a7d9-fb2d-4c29-8cfe-2ca90323f9f8": {            "status": "open",            "e5": 1.234,            "e10": 1.234,            "diesel": 1.234        }    }}

  stationNames = {}

  class TankerkoenigPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("TankerkoenigDevice",{
        prepareConfig: TankerkoenigDevice.prepareConfig,
        configDef : deviceConfigDef.TankerkoenigDevice,
        createCallback : (config, lastState) => new TankerkoenigDevice(config, lastState, this)
      })

      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-tankerkoenig/app/tankerkoenigTempl-page.coffee"
          mobileFrontend.registerAssetFile 'html', "pimatic-tankerkoenig/app/tankerkoenigTempl-template.html"
          mobileFrontend.registerAssetFile 'css', "pimatic-tankerkoenig/app/css/tankerkoenig.css"

        return

  class TankerkoenigDevice extends env.devices.Device
    attributes:
      prices:
        description: 'the prices data'
        type: t.string
      e5Min:
        description: 'the cheapest e5 price'
        type: t.number
      e10Min:
        description: 'the cheapest e10 price'
        type: t.number
      dieselMin:
        description: 'the cheapest diesel price'
        type: t.number

    template: 'tankerkoenig'

    ###
    @prepareConfig: (config) =>
      numericAttributes = ['e5Min', 'e10Min', 'dieselMin']

      if config.xAttributeOptions?
        xAttributeOptions = config.xAttributeOptions
      else
        xAttributeOptions = []

      keys = []
      for i in xAttributeOptions
        keys.push(i.name)

      # set displaySparkline to false initially
      for attr in numericAttributes
        if attr not in keys
          xAttributeOptions.push(
            {
              name: attr,
              displaySparkline: false
            }
          )

      config.xAttributeOptions = xAttributeOptions
    ###

    constructor: (@config, @plugin, lastState) ->
      # create getter function for attributes

      for attributeName of @attributes
        do (attributeName) =>
          @_createGetter(attributeName, =>
            @initialized.then => Promise.resolve @[attributeName]
          )

      @id = @config.id
      @name = @config.name
      @apiKey = @config.apiKey
      @ids = @config.ids or ""
      @interval = @config.interval or 10
      @type = @config.type or "all"
      @prices = ""

      @e5_min = lastState?["e5_min"]?.value or -1
      @e10_min = lastState?["e10_min"]?.value or -1
      @diesel_min = lastState?["diesel_min"]?.value or -1

      if @interval < 5
        reloadInterval = 300000
      else
        reloadInterval = @interval * 60000

      @initialized = new Promise (resolve) =>
        @retrieveStationNames()
        resolve()

      @timerId = setInterval ( =>
        @reloadPrices()
      ), reloadInterval

      super()


    _setAttribute: (attributeName, value) ->
      @emit attributeName, value
      @[attributeName] = value

    destroy: () ->
      if @timerId?
        clearInterval @timerId
        @timerId = null
      super()

    getApiKey: -> Promise.resolve(@apiKey)

    setApiKey: (value) ->
      if @apiKey is value then return
      @apiKey = value

    getIds: -> Promise.resolve(@ids)

    setIds: (value) ->
      if @ids is value then return
      @ids = value

    getInterval: -> Promise.resolve(@interval)

    setInterval: (value) ->
      if @interval is value then return
      @interval = value

    getType: -> Promise.resolve(@type)

    setType: (value) ->
      if @type is value then return
      @type = value

    reloadPrices: ->
      env.logger.info "reloading prices..."

      url = api.replace('{idPlaceholder}', @ids).replace('{apiKeyPlaceholder}', @apiKey)

      Request.get url, (error, response, body) =>
        if error
          env.logger.warn "Cannot connect to :" + url
          env.logger.error error.code
          placeholder = "<div class=\"tankerkoenig\">Server not reachable at the moment.</div>"

          @_setAttribute "prices", placeholder

          return

        try
          data = JSON.parse(body)
        catch err
          env.logger.warn err
          placeholder = "<div class=\"tankerkoenig\">Error on parsing server response.</div>"

          @_setAttribute "prices", placeholder

          return

        placeholderContent = "<div class=\"tankerkoenig\">"

        if data? and data.prices?
          prices = data.prices

          e5Min = 10.0
          e10Min = 10.0
          dieselMin = 10.0

          for id in @ids.split(',')
            price = prices[id]

            if price? and price.status?
              placeholderContent = placeholderContent + '<div class="caption">' + stationNames[id] + '</div><div class="table"><div class="row"><div class="col-1">Status</div><div class="col-2">' + price.status + '</div></div>'

              if (@type.indexOf('e5') > -1 or @type.indexOf('all') > -1) and price.e5
                placeholderContent = placeholderContent + '<div class="row"><div class="col-1">Super E5</div><div class="col-2">' + price.e5 + ' EUR</div></div>'
                if price.e5 < e5Min and price.status
                  e5Min = price.e5

              if (@type.indexOf('e10') > -1 or @type.indexOf('all') > -1) and price.e10
                placeholderContent = placeholderContent + '<div class="row"><div class="col-1">Super E10</div><div class="col-2">' + price.e10 + ' EUR</div></div>'
                if price.e10 < e10Min and price.status
                  e10Min = price.e10

              if (@type.indexOf('diesel') > -1 or @type.indexOf('all') > -1) and price.diesel
                placeholderContent = placeholderContent + '<div class="row"><div class="col-1">Diesel</div><div class="col-2">' + price.diesel + ' EUR</div></div>'
                if price.diesel < dieselMin and price.status
                  dieselMin = price.diesel


              placeholderContent = placeholderContent + '</div><div class="clear">&nbsp;</div>'

          if e5Min < 10.0
            @_setAttribute "e5Min", e5Min

          if e10Min < 10.0
            @_setAttribute "e10Min", e10Min

          if dieselMin < 10.0
            @_setAttribute "dieselMin", dieselMin

        else
          if data.message
            placeholderContent = placeholderContent + data.message
          else
            placeholderContent = placeholderContent + "NO DATA"

        placeholderContent = placeholderContent + "</div>"


        @_setAttribute "prices", placeholderContent


    retrieveStationNames: ->

      stationIds = @ids.split(',');
      numIds = stationIds.length
      counter = 0

      for id in stationIds
        detailUrl = detailApi.replace('{idPlaceholder}', id).replace('{apiKeyPlaceholder}', @apiKey)
        Request.get detailUrl, (error, response, body) =>

          counter++
          if error
            env.logger.warn "Cannot connect to :" + url
            env.logger.error error.code
            return

          try
            detailData = JSON.parse(body)
          catch err
            env.logger.warn err
            return

          if detailData? and detailData.station? and detailData.station.name?
            stationName = detailData.station.name

            if detailData.station.street?
              stationName = stationName + " (" + detailData.station.street + ")"

            stationNames[detailData.station.id] = stationName

          if counter == numIds
            @reloadPrices()



    destroy: ->
      super()

  return new TankerkoenigPlugin