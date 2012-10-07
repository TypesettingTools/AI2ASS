app.userInteractionLevel = UserInteractionLevel.DISPLAYALERTS # This should be the default, but CAN'T BE TOO CAREFUL
doc = app.activeDocument
alert "your colorspace needs to be RGB if you want colors." if doc.documentColorSpace == DocumentColorSpace.CMYK
scl = parseInt prompt "Scale by 2^(n-1) (minimum 1)",1
drawStrs = {}
drawCom = 0

# I guess it uses some sort of JIT magic because functions have to be declared in order?
fixCoords = (coordArr) ->
  org = doc.rulerOrigin
  coordArr[0] = Math.round((coordArr[0] + org[0])*Math.pow(2,scl-1))
  coordArr[1] = Math.round((doc.height - (org[1] + coordArr[1]))*Math.pow(2,scl-1))
  coordArr.join(" ")

linear = (currPoint) ->
  drawing = ""
  if drawCom != 1
    drawCom = 1
    drawing = "l "
  drawing += fixCoords(currPoint.anchor)+" "

cubic = (currPoint, prevPoint) ->
  drawing = ""
  if drawCom != 2
    drawCom = 2
    drawing = "b "
  drawing += fixCoords(prevPoint.rightDirection,scl)+" "+fixCoords(currPoint.leftDirection,scl)+" "+fixCoords(currPoint.anchor,scl)+" "

byLayer = () ->
  for currLayer in [doc.layers.length-1..0] by -1
    currLayer = doc.layers[currLayer].name
    herp = prompt("COPY THIS",drawStrs[currLayer].replace(/[ ]$/,""),"copy it") if drawStrs[currLayer]
  herp = null

zeroPad = (num) ->
  return "0"+num.toString(16) if num < 16
  return num.toString(16)

handleGray = (theColor) ->
  pct = theColor.gray
  pct = Math.round pct*255/100
  ("&H"+zeroPad(pct)+zeroPad(pct)+zeroPad(pct)+"&").toUpperCase()

handleRGB = (theColor) ->
  r = Math.round theColor.red # why am I rounding these?
  g = Math.round theColor.green
  b = Math.round theColor.blue
  ("&H"+zeroPad(b)+zeroPad(g)+zeroPad(r)+"&").toUpperCase()

manageColor = (currPath,field,ASSField) ->
  fmt = ""
  switch currPath[field].typename
    when "RGBColor"
      fmt = handleRGB currPath[field]
    when "GrayColor" 
      fmt = handleGray currPath[field]
    when "NoColor"
      switch field # not sure I really want this much nesting but oh well
        when "fillColor"
          return "\\#{ASSField}a&HFF&"
        when "strokeColor"
          return "\\bord0"
    else
      return ""
  return "\\#{ASSField}c#{fmt}"
  # "GradientColor"
  # "LabColor"
  # "PatternColor"
  # "SpotColor"

collectPaths = (callback) ->
  for currPath in doc.pathItems
    lname = currPath.layer.name
    fgc = manageColor currPath, "fillColor", 1
    sc = manageColor currPath,"strokeColor", 3
    drawStrs[lname] = "{"+fgc+sc+"\\p"+scl+"}" unless drawStrs[lname]
    points = currPath.pathPoints
    if points.length > 0
      drawCom = 0
      drawStrs[lname] += "m "+fixCoords(points[0].anchor,scl)+" "
      for j in [1...points.length] by 1
        currPoint = points[j]; prevPoint = points[j-1]
        if currPoint.pointType == PointType.CORNER && prevPoint.pointType == PointType.CORNER
          drawStrs[lname] += linear currPoint
        else
          drawStrs[lname] += cubic currPoint,prevPoint
      prevPoint = points[points.length-1]
      currPoint = points[0]
      if currPoint.pointType == PointType.SMOOTH || prevPoint.pointType == PointType.SMOOTH
        drawStrs[lname] += cubic currPoint,prevPoint
  callback()

collectPaths(byLayer) # because it looks clever
