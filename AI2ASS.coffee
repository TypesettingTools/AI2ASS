ai2assBackend = ( options ) ->
  pWin = new Window "palette"
  pWin.pBar = pWin.add "progressbar", undefined, 0, 250
  pWin.pBar.preferredSize = [ 250, 10 ]
  app.userInteractionLevel = UserInteractionLevel.DISPLAYALERTS
  doc = app.activeDocument
  org = doc.rulerOrigin
  currLayer = doc.activeLayer
  drawCom = 0

  output = {
    str: ""
    lastFill: ""
    lastStroke: ""
    lastLayer: ""
    append: ( toAppend ) ->
      @str += toAppend

    init: ( path ) ->
      @lastFill = manageColor path, "fillColor", 1
      @lastStroke = manageColor path, "strokeColor", 3
      @lastLayer = path.layer.name

      @append @prefix( )

    split: options.split or ( path ) ->
      fillColor = manageColor path, "fillColor", 1
      strokeColor = manageColor path, "strokeColor", 3
      layerName = path.layer.name

      fillChange = fillColor isnt @lastFill
      strokeChange = strokeColor isnt @lastStroke
      layerChange = layerName isnt @lastLayer

      if fillChange or strokeChange or layerChange
        @lastFill = fillColor
        @lastStroke = strokeColor
        @lastLayer = layerName

        @append "#{@suffix( )}\n#{@prefix( )}"

    appendPath: ( path ) ->
      unless path.hidden or path.guides or path.clipping or not (path.stroked or path.filled)
        @split( path )
        @append ASS_createDrawingFromPoints path.pathPoints

    prefix: -> "{\\an7\\pos(0,0)#{@lastStroke}#{@lastFill}\\p1}"

    suffix: -> "{\\p0}"

    merge: ->
      @str # cleanup everywher
  }

  switch options.wrapper
    when "clip"
      output.prefix = -> "\\clip("
      output.suffix = -> ")"
    when "iclip"
      output.prefix = -> "\\iclip("
      output.suffix = -> ")"
    when "bare"
      output.prefix = -> ""
      output.suffix = -> ""

  alert "Your colorspace needs to be RGB if you want colors." if doc.documentColorSpace == DocumentColorSpace.CMYK

  # For ASS, the origin is the top-left corner
  ASS_fixCoords = ( coordArr ) ->
    coordArr[0] = Math.round( (coordArr[0] + org[0])*100 )/100
    coordArr[1] = Math.round( (doc.height - (org[1] + coordArr[1]))*100 )/100
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
    # I don't actually know how you end up with a path with 0 elements.
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

  allThePaths = []
  recursePageItem = ( pageItem ) ->
    switch pageItem.typename

      when "CompoundPathItem"
        for path in pageItem.pathItems
          recursePageItem path

      when "GroupItem"
        for subPageItem in pageItem.pageItems
          recursePageItem subPageItem

      when "PathItem"
        allThePaths.push pageItem

      else
        alert pageItem.typename

  methods = {
    common: ->

      pWin.show( )
      output.init( allThePaths[0] )

      for path, i in allThePaths
        output.appendPath path
        pWin.pBar.value = Math.ceil i*250/allThePaths.length
        pWin.update( )

      output.append output.suffix( )
      pWin.close( )
      output.merge( )

    collectActiveLayer: ->

      # PAGEITEMS DOES NOT INCLUDE SUBLAYERS, AND AS FAR AS I CAN TELL,
      # THERE'S NO WAY TO POSSIBLY TELL FROM JS WHAT ORDER SUBLAYERS ARE
      # IN RELATIVE TO THE PATHS, COMPOUND PATHS, AND GROUPS WITHIN THE
      # LAYER, WHICH MEANS IT IS IMPOSSIBLE TO REPRODUCE THE WAY
      # SUBLAYERS ARE LAYERED. TL;DR IF YOU STICK A LAYER INSIDE ANOTHER
      # LAYER, FUCK YOU FOREVER.

      for pageItem in currLayer.pageItems
        recursePageItem pageItem, output

      @common( )

    CG_collectActiveLayer: ->

      output.appendPath = ( path ) ->
        unless path.hidden or path.guides or path.clipping or not (path.stroked or path.filled)
          @append CG_createDrawingFromPoints path.pathPoints

      @collectActiveLayer( )

    collectInnerShadow: ->
      outputStr = ""

      if currLayer.groupItems.length is 0
        return "Layer formatting not as expected."

      for outerGroup in currLayer.groupItems
        if outerGroup.groupItems.length is 0
          return "Layer formatting not as expected."

        for group in outerGroup.groupItems
          if group.compoundPathItems.length is 0
            return "Layer formatting not as expected."

          outlinePaths = group.compoundPathItems[0].pathItems
          outlineStr = ""
          glyphPaths = group.compoundPathItems[1].pathItems
          glyphStr = ""

          for currPath in glyphPaths
            glyphStr += ASS_createDrawingFromPoints currPath.pathPoints

          for currPath in outlinePaths
            outlineStr += ASS_createDrawingFromPoints currPath.pathPoints

          glyphStr = glyphStr[0...-1]
          outlineStr = "{\\clip(#{glyphStr})\\p1}#{outlineStr[0...-1]}"
          glyphStr = "{\\p1}#{glyphStr}"
          outputStr += "#{glyphStr}\n#{outlineStr}\n"

      "{innerShadow}\n#{outputStr}"[0...-2]

    collectAllLayers: ->

      allThePaths = doc.pathItems
      @common( )

  }

  methods[options.method]( )
