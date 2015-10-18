`#target illustrator`
`#targetengine main`

dlgRes = "Group { orientation:'column', alignChildren: ['fill', 'fill'], \
  output: Panel { orientation:'column', text: 'ASS Output', \
    edit: EditText {text: 'have ass, will typeset', properties: {multiline: true}, alignment: ['fill', 'fill'], preferredSize: [-1, 100] } \
  }, \
  outputFormat: Panel { orientation:'column', text: 'Output Format', \
    clip: Group {orientation: 'row', alignChildren: ['fill', 'fill'], spacing: 5, \
      noclip: RadioButton {text: 'Drawing', value: true}, \
      clip: RadioButton {text: '\\\\clip'}, \
      iclip: RadioButton {text: '\\\\iclip'}, \
      bare: RadioButton {text: 'Bare'}, \
      line: RadioButton {text: 'Line'} \
    }, \
  }, \
  settings: Panel {orientation: 'column', alignChildren: ['left','fill'], text: 'Settings', \
    collectionTarget: DropDownList {title: 'Collection Target:'}, \
    pathCombining: DropDownList {title: 'Path Combining:'} \
  }, \
  export: Button {text: 'Export'} \
}"


win = new Window "palette", "Export ASS" , undefined, {}
dlg = win.add dlgRes

outputFormats = {
  "Drawing:": "noclip"
  "\\clip": "clip"
  "\\iclip": "iclip"
  "Bare": "bare"
  "Line": "line"
}

exportMethods = {
  "Active Layer": "collectActiveLayer"
  "Non-Empty Layers": "collectAllLayers"
  "All Layers": "collectAllLayersIncludeEmpty"
}
dlg.settings.collectionTarget.add "item", k for k, v of exportMethods
dlg.settings.collectionTarget.selection = 0

pathCombiningStrategies = {
  "Disabled": "off"
  "Safe (Maintain Order)": "safe"
  "Ignore Blending Order": "any"
}
dlg.settings.pathCombining.add "item", k for k, v of pathCombiningStrategies
dlg.settings.pathCombining.selection = 1

bt = new BridgeTalk
bt.target = "illustrator"
backendScript = ai2assBackend.toString()

radioString = ( radioGroup ) ->
  for child in radioGroup.children
    if child.value
      return outputFormats[child.text]

objToString = (obj) ->
  fragments = ("#{k}: \"#{v}\"" for k, v of obj).join ", "
  return "{#{fragments}}"

dlg.export.onClick = ->
  dlg.output.edit.active = false
  options = objToString {
    method: exportMethods[dlg.settings.collectionTarget.selection.text]
    wrapper: radioString dlg.outputFormat.clip
    combineStrategy: pathCombiningStrategies[dlg.settings.pathCombining.selection.text]
  }

  bt.body = "(#{backendScript})(#{options});"

  bt.onResult = ( result ) ->
    dlg.output.edit.text = result.body.replace( /\\\\/g, "\\" ).replace /\\n/g, "\n"
    dlg.output.edit.active = true

  bt.onError = ( err ) ->
    alert "#{err.body} (#{a.headers["Error-Code"]})"

  bt.send( )

win.show( )
