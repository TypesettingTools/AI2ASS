`#targetengine session`
win = new Window "palette", "Export ASS" , undefined, {resizeable: true}
input = win.add "group"
input.orientation = "row"
label = input.add 'statictext', undefined, 'Scale Factor: '
label.graphics.font = "Comic Sans MS:12"
value = input.add 'edittext {text: 1, characters: 2, justify: "center", active: true}'
value.graphics.font = "Comic Sans MS:12"
slider = input.add 'slider', undefined, 1, 1, 11 # {minValue: 1, maxValue: 11, value: 1}')
slider.onChanging = () ->
  value.text = Math.round(slider.value)
value.onChanging = () ->
  slider.value = Number(value.text)
textCtrl = win.add "edittext", [0, 0, 250, 80], "", {multiline: true}
textCtrl.graphics.font = "Comic Sans MS:12"
textCtrl.text = "have ass will travel"
gobutton = win.add "button", undefined, "Export Active Layer"
gobutton.graphics.font = "Comic Sans MS:12"
gobutton.onClick = ->
  bt = new BridgeTalk
  bt.target = "illustrator"
  bt.body = "(#{fuckThis.toString()})(#{value.text});"
  bt.onResult = (result) ->
    textCtrl.text = result.body.replace /\\\\/g, "\\"
  bt.onError = (err) ->
    alert "#{err.body} (#{a.headers["Error-Code"]})"
  bt.send()

fuckThis = ( scl ) ->
  app.userInteractionLevel = UserInteractionLevel.DISPLAYALERTS # This should be the default, but CAN'T BE TOO CAREFUL
  doc = app.activeDocument
  currLayer = doc.activeLayer
  alert "your colorspace needs to be RGB if you want colors." if doc.documentColorSpace == DocumentColorSpace.CMYK
  drawStr = ""
  drawCom = 0

  fixCoords = (coordArr) ->
    org = doc.rulerOrigin
    coordArr[0] = Math.round((coordArr[0] + org[0])*Math.pow(2,scl-1))
    coordArr[1] = Math.round((doc.height - (org[1] + coordArr[1]))*Math.pow(2,scl-1))
    coordArr.join(" ")

  checkLinear = (currPoint, prevPoint) ->
    p1 = (prevPoint.anchor[0] == prevPoint.rightDirection[0] && prevPoint.anchor[1] == prevPoint.rightDirection[1])
    p2 = (currPoint.anchor[0] == currPoint.leftDirection[0] && currPoint.anchor[1] == currPoint.leftDirection[1])
    (p1 && p2)

  linear = (currPoint) ->
    drawing = ""
    if drawCom != 1
      drawCom = 1
      drawing = " l"
    drawing += " "+fixCoords(currPoint.anchor)

  cubic = (currPoint, prevPoint) ->
    drawing = ""
    if drawCom != 2
      drawCom = 2
      drawing = " b"
    drawing += " "+fixCoords(prevPoint.rightDirection,scl)+" "+fixCoords(currPoint.leftDirection,scl)+" "+fixCoords(currPoint.anchor,scl)

  zeroPad = (num) ->
    return "0"+num.toString(16) if num < 16
    num.toString(16)

  handleGray = (theColor) ->
    pct = theColor.gray
    pct = Math.round (100-pct)*255/100
    ("&H"+zeroPad(pct)+zeroPad(pct)+zeroPad(pct)+"&").toUpperCase()

  handleRGB = (theColor) ->
    r = Math.round theColor.red # why am I rounding these?
    g = Math.round theColor.green
    b = Math.round theColor.blue
    ("&H"+zeroPad( b )+zeroPad( g )+zeroPad( r )+"&").toUpperCase( )

  manageColor = ( currPath, field, ASSField ) ->
    fmt = ""
    switch currPath[field].typename
      when "RGBColor"
        fmt = handleRGB currPath[field]
      when "GrayColor"
        fmt = handleGray currPath[field]
      when "NoColor"
        switch field
          when "fillColor"
            return "\\#{ASSField}a&HFF&"
          when "strokeColor"
            return ""#\\bord0"
      else
        return ""
    return "\\#{ASSField}c#{fmt}"
    # "GradientColor"
    # "LabColor"
    # "PatternColor"
    # "SpotColor"

  collectPaths = ->
    alert "#{doc.pathItems.length}"
    for currPath in doc.pathItems
      if currPath.layer.name is currLayer.name
        if drawStr.length is 0
          fgc = manageColor currPath, "fillColor", 1
          sc = manageColor currPath, "strokeColor", 3
          drawStr = "{"+fgc+sc+"\\p"+scl+"}"
        points = currPath.pathPoints
        if points.length > 0
          drawCom = 0
          drawStr += "m "+fixCoords(points[0].anchor,scl)
          for j in [1...points.length] by 1
            currPoint = points[j]; prevPoint = points[j-1]
            if checkLinear(currPoint,prevPoint)
              drawStr += linear currPoint
            else
              drawStr += cubic currPoint,prevPoint
          prevPoint = points[points.length-1]
          currPoint = points[0]
          unless checkLinear(currPoint, prevPoint)
            drawStr += cubic currPoint,prevPoint
    drawStr

  collectPaths() # because it looks clever

win.show()
