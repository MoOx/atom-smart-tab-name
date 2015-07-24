pkg = "smart-tab-name"
describe "SmartTabName", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    atom.devMode = true
    atom.config.set("#{pkg}.debug",2)
    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise ->
      atom.packages.activatePackage("tabs")
      .then ->
        atom.workspace.open('sample.js')
      .then ->
        atom.packages.activatePackage(pkg)

  describe "when the smart-tab-name:toggle event is triggered", ->
    it "adjust path in tabs", ->
      runs ->
        expect(workspaceElement.querySelector('.tab-bar')).toExist()
        fntElement = workspaceElement.querySelector('div.smart-tab-name')
        expect(fntElement).toExist()
        expect(fntElement.querySelector("span.folder").innerHTML)
          .toEqual "/"
        expect(fntElement.querySelector("span.file").innerHTML)
          .toEqual "sample.js"
        atom.commands.dispatch workspaceElement, 'smart-tab-name:toggle'
        expect(workspaceElement.querySelector('div.smart-tab-name')).not
          .toExist()
        expect(workspaceElement.querySelector('.tab-bar div.title').innerHTML)
          .toEqual("sample.js")
