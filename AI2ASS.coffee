ai2assBackend = ( options ) ->
  app.userInteractionLevel = UserInteractionLevel.DISPLAYALERTS
  pWin = new Window "palette"
  pWin.text = "Progress Occurs"
  pWin.pBar = pWin.add "progressbar", undefined, 0, 250
  pWin.pBar.preferredSize = [ 250, 10 ]
  doc = app.activeDocument
  org = doc.rulerOrigin
  currLayer = doc.activeLayer
  drawCom = 0

  output = {
    assSections: []

    appendPath: ( path ) ->
      stroke = manageColor path, "strokeColor", 3
      fill = manageColor path, "fillColor", 1
      layerName = path.layer.name
      layerNum = path.layer.zOrderPosition

      prefix = @prefix stroke, fill, layerNum, layerName

      if not @assSections[layerNum]?
        @assSections[layerNum] = {}

      if not @assSections[layerNum][prefix]?
        @assSections[layerNum][prefix] = []

      Array.prototype.push.apply @assSections[layerNum][prefix], ASS_createDrawingFromPoints path.pathPoints

    prefix: (stroke, fill) -> "{\\an7\\pos(0,0)#{stroke}#{fill}\\p1}"

    suffix: -> "{\\p0}"

    get: (includeEmptyLayers = false) ->
      fragments = []
      suffix = @suffix()

      for shapes, layerNum in @assSections
        if shapes?
          for prefix, paths of shapes
            fragments.push prefix
            fragments.push paths.join " "
            fragments.push suffix
            fragments.push "\n"
        else if includeEmptyLayers
            fragments.push "\n"

      fragments.pop()
      return fragments.join ""
  }

  drawing = {
    commands: []
    new: -> @commands = []
    get: -> return @commands

    CmdTypes: {
      None: -1
      Move: 0
      Linear: 1
      Cubic: 2
    }

    prevCmdType: -1

    addMove: ( point ) ->
      @commands.push "m"
      @addCoords point.anchor
      @prevCmdType = @CmdTypes.Move

    addLinear: ( point ) ->
      if @prevCmdType != @CmdTypes.Linear
        @commands.push "l"
        @prevCmdType = @CmdTypes.Linear

      @commands.push
      @addCoords point.anchor

    addCubic: (currPoint, prevPoint) ->
      if @prevCmdType != @CmdTypes.Cubic
        @commands.push "b"
        @prevCmdType = @CmdTypes.Cubic

      @addCoords prevPoint.rightDirection
      @addCoords currPoint.leftDirection
      @addCoords currPoint.anchor

    # For ASS, the origin is the top-left corner
    addCoords: ( coordArr ) ->
      @commands.push Math.round( (coordArr[0] + org[0])*100 )/100
      @commands.push Math.round( (doc.height - (org[1] + coordArr[1]))*100 )/100

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
    when "line"
      output.prefix = (stroke, fill, layerNum, layerName) ->
        "Dialogue: #{layerNum},0:00:00.00,0:00:00.00,AI,#{layerName},0,0,0,,{\\an7\\pos(0,0)#{stroke}#{fill}\\p1}"
      output.suffix = -> ""


  alert "Your colorspace needs to be RGB if you want colors." if doc.documentColorSpace == DocumentColorSpace.CMYK



  checkLinear = ( currPoint, prevPoint ) ->
    p1 = (prevPoint.anchor[0] == prevPoint.rightDirection[0] && prevPoint.anchor[1] == prevPoint.rightDirection[1])
    p2 = (currPoint.anchor[0] == currPoint.leftDirection[0] && currPoint.anchor[1] == currPoint.leftDirection[1])
    (p1 && p2)

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
    drawing.new()

    if pathPoints.length > 0
      drawing.addMove pathPoints[0]

      for j in [1...pathPoints.length] by 1
        currPoint = pathPoints[j]
        prevPoint = pathPoints[j-1]

        if checkLinear currPoint, prevPoint
          drawing.addLinear currPoint
        else
          drawing.addCubic currPoint, prevPoint

      prevPoint = pathPoints[pathPoints.length-1]
      currPoint = pathPoints[0]

      if checkLinear currPoint, prevPoint
        drawing.addLinear currPoint
      else
        drawing.addCubic currPoint, prevPoint

      return drawing.get()

  allThePaths = []
  recursePageItem = ( pageItem ) ->
    unless pageItem.hidden
      switch pageItem.typename

        when "CompoundPathItem"
          for path in pageItem.pathItems
            recursePageItem path

        when "GroupItem"
          for subPageItem in pageItem.pageItems
            recursePageItem subPageItem

        when "PathItem"
          unless pageItem.guides or pageItem.clipping or not (pageItem.stroked or pageItem.filled) or not pageItem.layer.visible
            allThePaths.push pageItem

  methods = {
    common: ->
      pWin.show( )

      for path, i in allThePaths
        output.appendPath path
        pWin.pBar.value = Math.ceil i*250/(allThePaths.length-1)
        pWin.update( )

      pWin.close( )
      allThePaths = []

    collectActiveLayer: ->

      # PAGEITEMS DOES NOT INCLUDE SUBLAYERS, AND AS FAR AS I CAN TELL,
      # THERE'S NO WAY TO POSSIBLY TELL FROM JS WHAT ORDER SUBLAYERS ARE
      # IN RELATIVE TO THE PATHS, COMPOUND PATHS, AND GROUPS WITHIN THE
      # LAYER, WHICH MEANS IT IS IMPOSSIBLE TO REPRODUCE THE WAY
      # SUBLAYERS ARE LAYERED. TL;DR IF YOU STICK A LAYER INSIDE ANOTHER
      # LAYER, FUCK YOU FOREVER.
      unless currLayer.visible
        return "Not doing anything to that invisible layer."

      for pageItem in currLayer.pageItems
        recursePageItem pageItem

      @common( )
      return output.get()

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

      for layer in doc.layers
        for pageItem in layer.pageItems
          recursePageItem pageItem

      @common( )
      return output.get()

    giveMeASeizure: ->

      pWin.label = pWin.add "statictext", undefined, ""

      for layer in doc.layers
        pWin.label.text = "Layer: #{layer.name}"

        for pageItem in layer.pageItems
          recursePageItem pageItem

      @common( )
      return output.get()
  }

  methods[options.method]( )
