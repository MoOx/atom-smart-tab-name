sep = require("path").sep
basename = require("path").basename
ellipsis = "…"
log = require("atom-simple-logger")(pkg:"smart-tab-name",nsp:"core")


{CompositeDisposable} = require 'atom'
paths = {}

parsePath = (path) ->
  result = {}
  relativePath = atom.project.relativizePath path

  if relativePath?[0]?
    splitted = relativePath[1].split(sep)
    result.filename = splitted.pop()
    projectPaths = atom.project.getPaths()
    pathIdentifier = ""

    if projectPaths.length > 1
      pathIdentifier += "#{basename(projectPaths[projectPaths.indexOf(relativePath[0])])}"
      pathIdentifier += sep if splitted.length > 0

    last = ""
    if splitted.length > 0
      last = splitted.pop()

    if splitted.length > 0
      if pathIdentifier != ""
        result.foldername = pathIdentifier + ellipsis + sep + last + sep
      else
        result.foldername = last + sep
        # rtl trick
        result.ellipsis = "#{sep}#{ellipsis}"
    else
      result.foldername = pathIdentifier + last + sep

  else
    splitted = path.split(sep)
    result.filename = splitted.pop()
    if splitted.length
      result.foldername = splitted.pop() + sep
      # rtl trick
      result.ellipsis = "#{sep}#{ellipsis}"

  return result

processAllTabs = (revert=false)->
  log "processing all tabs, reverting:#{revert}"
  paths = []
  paneItems = atom.workspace.getPaneItems()
  for paneItem in paneItems

    if paneItem.getPath?
      path = paneItem.getPath()

      if path? and paths.indexOf(path) == -1
        paths.push path

  log "found #{paths.length} different paths of
    total #{paneItems.length} paneItems",2
  for path in paths
    tabs = atom.views.getView(atom.workspace).querySelectorAll "ul.tab-bar>
      li.tab[data-type='TextEditor']>
      div.title[data-path='#{path.replace(/\\/g,"\\\\")}']"
    log "found #{tabs.length} tabs for #{path}",2
    for tab in tabs
      container = tab.querySelector "div.smart-tab-name"
      if container? and revert
        log "reverting #{path}",2
        tab.removeChild container
        tab.innerHTML = path.split(sep).pop()
      else if not container? and not revert
        log "applying #{path}",2
        paths[path] ?= parsePath path
        tab.innerHTML = ""
        container = document.createElement("div")
        container.classList.add "smart-tab-name"

        if paths[path].foldername and paths[path].foldername != "/"
          foldernameElement = document.createElement("span")
          foldernameElement.classList.add "folder"
          foldernameElement.innerHTML = paths[path].foldername
          container.appendChild foldernameElement

        if paths[path].foldername == ""
          filenameElement.classList.add "file-only"

        filenameElement = document.createElement("span")
        filenameElement.classList.add "file"
        filenameElement.innerHTML = paths[path].filename
        container.appendChild filenameElement

        if paths[path].filename.match(/^index\.[a-z]+/)
          filenameElement.classList.add "index-filename"

        if paths[path].ellipsis
          ellipsisElement = document.createElement("span")
          ellipsisElement.classList.add "ellipsis"
          ellipsisElement.innerHTML = paths[path].ellipsis
          container.appendChild ellipsisElement

        tab.appendChild container
  return !revert

module.exports =
class SmartTabName
  disposables: null
  processed: false
  constructor:  ->
    @processed = processAllTabs()
    unless @disposables?
      @disposables = new CompositeDisposable
      @disposables.add atom.workspace.onDidAddTextEditor ->
        setTimeout processAllTabs, 10
      @disposables.add atom.workspace.onDidDestroyPaneItem ->
        setTimeout processAllTabs, 10
      @disposables.add atom.workspace.onDidAddPane (event) =>
        @disposables.add event.pane.onDidMoveItem ->
          setTimeout processAllTabs, 10
      @disposables.add atom.commands.add 'atom-workspace',
      'smart-tab-name:toggle': @toggle

      for pane in atom.workspace.getPanes()
        @disposables.add pane.onDidMoveItem ->
          setTimeout processAllTabs, 10
    log "loaded"
  toggle: =>
    @processed = processAllTabs(@processed)
  destroy: =>
    @processed = processAllTabs(true)
    @disposables?.dispose()
    @disposables = null
