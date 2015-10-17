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
  tempLayer = null
  black = new RGBColor();

  countPathItems = ( obj ) ->
    recurse = ( obj ) ->
      unless obj.hidden
        switch obj.typename
          when "Document"
            recurse layer for layer in obj.layers
          when "Layer", "GroupItem"
            recurse pageItem for pageItem in obj.pageItems
          when "CompoundPathItem"
            recurse path for path in obj.pathItems
          when "PathItem"
            count += 1

    count = 0
    recurse obj
    return count

  makeClip = ( clippingPath ) ->
    clip = {
      tempGroup: null
      isVisible: false

      add: (clippingPath) ->
        # prepare a group to apply the pathfinder effect to
        unless tempLayer?
          tempLayer = doc.layers.add()
          tempLayer.name = "AI2ASS_tmp"
          tempLayer.zOrder(ZOrderMethod.SENDTOBACK)
        unless @tempGroup
          @tempGroup = tempLayer.groupItems.add()

        # copy all path into the group and make sure it has a fill
        copy = clippingPath.duplicate(@tempGroup, ElementPlacement.PLACEATBEGINNING)
        copy.filled = true
        copy.stroked = false
        copy.clipping = false
        copy.fillColor = black

        if @tempGroup.pageItems.length > 1
          # select the group, apply the pathfinder and expand
          prevSelection = doc.selection
          doc.selection = [@tempGroup]
          app.executeMenuCommand("Live Pathfinder Intersect")
          app.executeMenuCommand("expandStyle")
          # expanding created a new group
          @tempGroup = doc.selection[0]

          # no intersection between paths means we have an empty clipping area
          if @tempGroup.pageItems.length == 1
            @isVisible = true
          else
            @isVisible = false
            @tempGroup.pageItems.removeAll()

          # restore previous selection
          doc.selection = prevSelection
        else @isVisible = true

      copy: -> return makeClip @tempGroup.pageItems[0]
      get: -> return @tempGroup.pageItems[0]
      getASS: ->
        drawing = ASS_createDrawingFromPoints @tempGroup.pageItems[0].pathPoints
        return "\\clip(#{drawing.join ' '})"
    }

    clip.add clippingPath
    return clip

  output = {
    pathCnt: null
    processedPathCnt: 0
    layers: []

    makeLayer: (emptyPrefix) ->
      layer = {
        groups: []
        currGroupIdx: -1
        currGroup: null
        emptyPrefix: null

        makeMergeGroup: ->
          {
            dirtyRects: []
            lines: {}

            addPath: (path, prefix) ->
              unless @isZeroArea path.visibleBounds
                @dirtyRects.push path.visibleBounds
                drawing = ASS_createDrawingFromPoints path.pathPoints

                if @lines[prefix]?
                  Array.prototype.push.apply @lines[prefix], drawing
                else @lines[prefix] = drawing

            isZeroArea: (bounds) ->
              return bounds[2]-bounds[0] == 0 and bounds[3]-bounds[1] == 0

            isMergeable: (path) ->
              bounds = path.visibleBounds

              if @isZeroArea bounds
                return true

              for rect in @dirtyRects
                if bounds[2] > rect[0] and bounds[0] < rect[2] and bounds[3] < rect[1] and bounds[1] > rect[3]
                  return false

              return true
          }

        addGroup: ->
          @currGroupIdx += 1
          @currGroup = @makeMergeGroup()
          @groups[@currGroupIdx] = @currGroup

        addPath: (path, prefix) ->
          unless @currGroup.isMergeable path
            @addGroup()
          @currGroup.addPath path, prefix
      }

      layer.addGroup()
      layer.emptyPrefix = emptyPrefix
      return layer

    process: ( obj, clip, opacity = 100 ) ->
      if not @pathCnt?
        @pathCnt = countPathItems obj

      if !obj.hidden and (not clip? or clip.isVisible)
        opacity = if obj.opacity? then opacity * obj.opacity/100 else 100

        switch obj.typename
          when "Document"
            for layer in obj.layers by -1
              @process layer

          when "Layer"
            if obj.pageItems.length == 0
              @layers[obj.zOrderPosition] = @makeLayer @emptyPrefix obj.zOrderPosition, obj.name
            else
              for subPageItem in obj.pageItems by -1
                @process subPageItem, null, opacity

          when "CompoundPathItem"
            for path in obj.pathItems by -1
              @process path, clip, opacity

          when "GroupItem"
            if obj.clipped
              clipPath = (pI for pI in obj.pageItems when pI.clipping)[0]
              if clip?
                clip = clip.copy()
                clip.add clipPath
              else
                clip = makeClip clipPath
              @processedPathCnt += 1

            for subPageItem in obj.pageItems by -1 when not subPageItem.clipping
              @process subPageItem, clip, opacity

          when "PathItem"
            if @processedPathCnt % 10 == 0
              pWin.pBar.value = Math.ceil @processedPathCnt*250/@pathCnt
              pWin.update( )

            unless obj.guides or not (obj.stroked or obj.filled or obj.clipping) or not obj.layer.visible
              @appendPath obj, clip, opacity

            @processedPathCnt += 1

    appendPath: ( path, clipObj, opacity ) ->
      stroke = manageColor path, "strokeColor", 3
      fill = manageColor path, "fillColor", 1
      layerName = path.layer.name
      layerNum = path.layer.zOrderPosition
      alpha = manageOpacity opacity
      clip = if clipObj? then clipObj.getASS() else ""

      prefix = @prefix stroke, fill, clip, alpha, layerNum, layerName

      layer = @layers[layerNum]
      unless layer?
        layer = @makeLayer()
        @layers[layerNum] = layer

      layer.addPath path, prefix

    prefix: (stroke, fill, clip, alpha) ->
      "{\\an7\\pos(0,0)#{stroke}#{fill}#{alpha}#{clip}\\p1}"

    emptyPrefix: -> ""
    suffix: -> "{\\p0}"

    get: (includeEmptyLayers) ->
      fragments = []
      suffix = @suffix()

      for layer in @layers when layer?
        if includeEmptyLayers && layer.emptyPrefix?
            fragments.push layer.emptyPrefix
            fragments.push "\n"

        for mergeGroup in layer.groups
          for prefix, drawing of mergeGroup.lines
            fragments.push prefix
            fragments.push drawing.join " "
            fragments.push suffix
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
      output.prefix = (stroke, fill, clip, alpha, layerNum, layerName) ->
        "Dialogue: #{layerNum},0:00:00.00,0:00:00.00,AI,#{layerName},0,0,0,,{\\an7\\pos(0,0)#{stroke}#{fill}#{alpha}#{clip}\\p1}"
      output.suffix = -> ""
      output.emptyPrefix = (layerNum, layerName) ->
        "Dialogue: #{layerNum},0:00:00.00,0:00:00.00,AI,#{layerName},0,0,0,,"


  alert "Your colorspace needs to be RGB if you want colors." if doc.documentColorSpace == DocumentColorSpace.CMYK



  checkLinear = ( currPoint, prevPoint ) ->
    p1 = (prevPoint.anchor[0] == prevPoint.rightDirection[0] && prevPoint.anchor[1] == prevPoint.rightDirection[1])
    p2 = (currPoint.anchor[0] == currPoint.leftDirection[0] && currPoint.anchor[1] == currPoint.leftDirection[1])
    (p1 && p2)

  zeroPad = ( num ) ->
    hexStr = num.toString(16).toUpperCase()
    return if num < 16 then "0#{hexStr}" else hexStr

  handleGray = ( theColor ) ->
    pct = theColor.gray
    pct = Math.round (100-pct)*255/100
    "&H#{zeroPad pct}#{zeroPad pct}#{zeroPad pct}&"

  handleRGB = ( theColor ) ->
    r = Math.round theColor.red # why am I rounding these?
    g = Math.round theColor.green
    b = Math.round theColor.blue
    "&H#{zeroPad b}#{zeroPad g}#{zeroPad r}&"

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

  manageOpacity = (opacity) ->
    if opacity >= 100
      return ""

    return "\\alpha&H#{zeroPad 255 - Math.round(opacity)/100 * 255}&"

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

  methods = {
    collectActiveLayer: ->

      # PAGEITEMS DOES NOT INCLUDE SUBLAYERS, AND AS FAR AS I CAN TELL,
      # THERE'S NO WAY TO POSSIBLY TELL FROM JS WHAT ORDER SUBLAYERS ARE
      # IN RELATIVE TO THE PATHS, COMPOUND PATHS, AND GROUPS WITHIN THE
      # LAYER, WHICH MEANS IT IS IMPOSSIBLE TO REPRODUCE THE WAY
      # SUBLAYERS ARE LAYERED. TL;DR IF YOU STICK A LAYER INSIDE ANOTHER
      # LAYER, FUCK YOU FOREVER.
      unless currLayer.visible
        return "Not doing anything to that invisible layer."

      pWin.show( )
      output.process currLayer
      pWin.close( )

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
      pWin.show( )
      output.process doc
      pWin.close( )

      return output.get()

    collectAllLayersIncludeEmpty: ->
      pWin.show( )
      output.process doc
      pWin.close( )

      return output.get(true)
  }

  methods[options.method]( )
