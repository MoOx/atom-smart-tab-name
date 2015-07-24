SmartTabName = null
log = null
reloader = null

pkgName = "smart-tab-name"

module.exports = new class Main
  subscriptions: null
  SmartTabName: null
  config:
    debug:
      type: "integer"
      default: 0
      minimum: 0

  activate: ->
    setTimeout (->
      reloaderSettings = pkg:pkgName,folders:["lib","styles"]
      try
        reloader ?= require("atom-package-reloader")(reloaderSettings)
      catch

      ),500
    unless log?
      log = require("atom-simple-logger")(pkg:pkgName,nsp:"main")
      log "activating"
    unless @SmartTabName?
      log "loading core"
      load = =>
        try
          SmartTabName ?= require "./#{pkgName}"
          @SmartTabName = new SmartTabName
        catch
          log "loading core failed"
      if atom.packages.isPackageActive("tabs")
        load()
      else
        @onceActivated = atom.packages.onDidActivatePackage (p) =>
          if p.name == "tabs"
            load()
            @onceActivated.dispose()


  deactivate: ->
    log "deactivating"
    @onceActivated?.dispose?()
    @SmartTabName?.destroy?()
    @SmartTabName = null
    log = null
    SmartTabName = null
    reloader?.dispose()
    reloader = null
