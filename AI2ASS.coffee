`#targetengine session`
win = new Window "palette", "Export ASS" , undefined, {resizeable: true}

input = win.add "group"
input.orientation = "row"

label = input.add 'statictext', undefined, 'Scale Factor: '
label.graphics.font = "Comic Sans MS:12"

value = input.add 'edittext {text: 1, characters: 2, justify: "center", active: true}'
value.graphics.font = "Comic Sans MS:12"

value.onChanging = ->
  slider.value = Number value.text

slider = input.add 'slider', undefined, 1, 1, 11

slider.onChanging = ->
  value.text = Math.round slider.value

textCtrl = win.add "edittext", [0, 0, 250, 80], "", {multiline: true}
textCtrl.graphics.font = "Comic Sans MS:12"
textCtrl.text = "have ass will travel"

collectionMethod = win.add "dropdownlist", [0,0,250,20], ["collectActiveLayer","collectInnerShadow","collectAllLayers", "CG_collectActiveLayer"]
collectionMethod.graphics.font = "Comic Sans MS:12"
collectionMethod.selection = 0

goButton = win.add "button", undefined, "Export"
goButton.graphics.font = "Comic Sans MS:12"

goButton.onClick = ->
  textCtrl.active = false
  bt = new BridgeTalk
  bt.target = "illustrator"
  bt.body = "(#{fuckThis.toString()})({scale:#{value.text},method:\"#{collectionMethod.selection.text}\"});"

  bt.onResult = ( result ) ->
    textCtrl.text = result.body.replace( /\\\\/g, "\\" ).replace /\\n/g, "\n"
    textCtrl.active = true

  bt.onError = ( err ) ->
    alert "#{err.body} (#{a.headers["Error-Code"]})"

  bt.send()

fuckThis = ( options ) ->
  app.userInteractionLevel = UserInteractionLevel.DISPLAYALERTS # This should be the default, but CAN'T BE TOO CAREFUL
  doc = app.activeDocument
  org = doc.rulerOrigin
  currLayer = doc.activeLayer
  scaleFactor = Math.pow 2, options.scale - 1
  drawCom = 0
  alert "Your colorspace needs to be RGB if you want colors." if doc.documentColorSpace == DocumentColorSpace.CMYK

  # For ASS, the origin is the top-left corner
  ASS_fixCoords = ( coordArr ) ->
    coordArr[0] = Math.round (coordArr[0] + org[0])*scaleFactor
    coordArr[1] = Math.round (doc.height - (org[1] + coordArr[1]))*scaleFactor
    coordArr.join " "

  # for CoreGraphics, the origin is the bottom-left corner. Except on IOS
  # where it's the top-left corner. But I don't care about IOS.
  CG_fixCoords = ( coordArr ) ->
    coordArr[0] = Math.round( (coordArr[0] + org[0])*100 )/100
    coordArr[1] = Math.round( (coordArr[1] + org[1])*100 )/100
    coordArr.join ", "

  checkLinear = ( currPoint, prevPoint ) ->
    p1 = (prevPoint.anchor[0] == prevPoint.rightDirection[0] && prevPoint.anchor[1] == prevPoint.rightDirection[1])
    p2 = (currPoint.anchor[0] == currPoint.leftDirection[0] && currPoint.anchor[1] == currPoint.leftDirection[1])
    (p1 && p2)

  ASS_linear = ( currPoint ) ->
    drawing = ""

    if drawCom != 1
      drawCom = 1
      drawing = "l "

    drawing += "#{ASS_fixCoords currPoint.anchor} "

  CG_linear = ( currPoint ) ->
    "CGContextAddLineToPoint(ctx, #{CG_fixCoords currPoint.anchor});\n"

  ASS_cubic = ( currPoint, prevPoint ) ->
    drawing = ""

    if drawCom != 2
      drawCom = 2
      drawing = "b "

    drawing += "#{ASS_fixCoords prevPoint.rightDirection} #{ASS_fixCoords currPoint.leftDirection} #{ASS_fixCoords currPoint.anchor} "

  CG_cubic = ( currPoint, prevPoint ) ->
    "CGContextAddCurveToPoint(ctx, #{CG_fixCoords prevPoint.rightDirection}, #{CG_fixCoords currPoint.leftDirection}, #{CG_fixCoords currPoint.anchor});\n"

  zeroPad = ( num ) ->
    if num < 16
      "0#{num.toString 16}"
    else
      num.toString 16

  handleGray = ( theColor ) ->
    pct = theColor.gray
    pct = Math.round (100-pct)*255/100
    "&H#{zeroPad pct}#{zeroPad pct}#{zeroPad pct}&".toUpperCase( )

  handleRGB = ( theColor ) ->
    r = Math.round theColor.red # why am I rounding these?
    g = Math.round theColor.green
    b = Math.round theColor.blue
    "&H#{zeroPad b}#{zeroPad g}#{zeroPad r}&".toUpperCase( )

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

    "\\#{ASSField}c#{fmt}"
    # "GradientColor"
    # "LabColor"
    # "PatternColor"
    # "SpotColor"

  ASS_createDrawingFromPoints = ( pathPoints ) ->
    drawStr = ""

    if pathPoints.length > 0
      drawCom = 0
      drawStr += "m #{ASS_fixCoords pathPoints[0].anchor} "

      for j in [1...pathPoints.length] by 1
        currPoint = pathPoints[j]
        prevPoint = pathPoints[j-1]

        if checkLinear currPoint, prevPoint
          drawStr += ASS_linear currPoint
        else
          drawStr += ASS_cubic currPoint, prevPoint

      prevPoint = pathPoints[pathPoints.length-1]
      currPoint = pathPoints[0]

      unless checkLinear currPoint, prevPoint
        drawStr += ASS_cubic currPoint, prevPoint

      return drawStr

    return ""

  CG_createDrawingFromPoints = ( pathPoints ) ->
    drawStr = ""

    if pathPoints.length > 0
      drawStr += "CGContextMoveToPoint(ctx, #{CG_fixCoords pathPoints[0].anchor});\n"

      for j in [1...pathPoints.length] by 1
        currPoint = pathPoints[j]
        prevPoint = pathPoints[j-1]

        if checkLinear currPoint, prevPoint
          drawStr += CG_linear currPoint
        else
          drawStr += CG_cubic currPoint, prevPoint

      prevPoint = pathPoints[pathPoints.length-1]
      currPoint = pathPoints[0]

      unless checkLinear currPoint, prevPoint
        drawStr += CG_cubic currPoint, prevPoint

      return drawStr

    return ""

  methods = {
    collectActiveLayer: ->
      outputStr = ""

      for currPath in doc.pathItems

        if currPath.layer.name is currLayer.name

          unless currPath.hidden or currPath.guides or currPath.clipping

            if outputStr.length is 0
              fgc = manageColor currPath, "fillColor", 1
              sc = manageColor currPath, "strokeColor", 3
              outputStr += "{#{fgc}#{sc}\\p#{options.scale}}"

            outputStr += ASS_createDrawingFromPoints currPath.pathPoints

      outputStr[0...-1]

    CG_collectActiveLayer: ->
      outputStr = ""

      for currPath in doc.pathItems

        if currPath.layer.name is currLayer.name
          outputStr += CG_createDrawingFromPoints currPath.pathPoints

      outputStr

    collectInnerShadow: ->
      outputStr = ""
      clipStart = if options.scale is 1 then "" else "#{options.scale},"

      for outerGroup in currLayer.groupItems

        for group in outerGroup.groupItems
          outlinePaths = group.compoundPathItems[0].pathItems
          outlineStr = ""
          glyphPaths = group.compoundPathItems[1].pathItems
          glyphStr = ""

          for currPath in glyphPaths
            glyphStr += ASS_createDrawingFromPoints currPath.pathPoints

          for currPath in outlinePaths
            outlineStr += ASS_createDrawingFromPoints currPath.pathPoints

          glyphStr = glyphStr[0...-1]
          outlineStr = "{\\clip(#{clipStart}#{glyphStr})\\p#{options.scale}}#{outlineStr[0...-1]}"
          glyphStr = "{\\p#{options.scale}}#{glyphStr}"
          outputStr += "#{glyphStr}\n#{outlineStr}\n"

      "{innerShadow}\n#{outputStr}"[0...-2]

    collectAllLayers: ->
      output = {}
      overall = ""

      for currPath in doc.pathItems

        unless currPath.hidden or currPath.guides or currPath.clipping or not currPath.layer.visible
          outputStr = ""
          outputStr += ASS_createDrawingFromPoints currPath.pathPoints

          unless output[currPath.layer.name]
            fgc = manageColor currPath, "fillColor", 1
            sc = manageColor currPath, "strokeColor", 3
            outputStr = "{#{fgc}#{sc}\\p#{options.scale}}#{outputStr}"
            output[currPath.layer.name] = outputStr
          else
            output[currPath.layer.name] += outputStr

      for key, val of output
        overall += "#{val[0...-1]}\n"

      "{allLayers}\n#{overall}"[0...-2]
  }

  methods[options.method]()

win.show()
