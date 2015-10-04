`#target illustrator`
`#targetengine main`

win = new Window "palette", "Export ASS" , undefined, {}

win.outputBox = win.add "edittext", [0, 0, 280, 80], "", {multiline: true}
win.outputBox.graphics.font = "Comic Sans MS:12"
win.outputBox.text = "have ass, will typeset"

win.clip = win.add """
Group {orientation: 'row',
  noclip: RadioButton { text: 'drawing', value: true },
  clip: RadioButton { text: 'clip' },
  iclip: RadioButton { text: 'iclip' }, bare: RadioButton { text: 'bare' },
  line: RadioButton { text: 'line' }
}
"""
win.clip.noclip.graphics.font = "Comic Sans MS:12"
win.clip.clip.graphics.font = "Comic Sans MS:12"
win.clip.iclip.graphics.font = "Comic Sans MS:12"
win.clip.bare.graphics.font = "Comic Sans MS:12"

win.collectionMethod = win.add "dropdownlist", [0,0,280,20], ["collectActiveLayer","collectInnerShadow","collectAllLayers", "collectAllLayersIncludeEmpty"]
win.collectionMethod.graphics.font = "Comic Sans MS:12"
win.collectionMethod.selection = 0

win.goButton = win.add "button", undefined, "Export"
win.goButton.graphics.font = "Comic Sans MS:12"

radioString = ( radioGroup ) ->
  for child in radioGroup.children
    if child.value
      return child.text

win.goButton.onClick = ->
  win.outputBox.active = false
  bt = new BridgeTalk
  bt.target = "illustrator"
  bt.body = "(#{ai2assBackend.toString( )})({method:\"#{win.collectionMethod.selection.text}\",wrapper:\"#{radioString win.clip}\"});"

  bt.onResult = ( result ) ->
    win.outputBox.text = result.body.replace( /\\\\/g, "\\" ).replace /\\n/g, "\n"
    win.outputBox.active = true

  bt.onError = ( err ) ->
    alert "#{err.body} (#{a.headers["Error-Code"]})"

  bt.send( )

win.show( )
