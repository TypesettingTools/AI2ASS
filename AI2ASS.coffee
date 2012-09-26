app.userInteractionLevel = UserInteractionLevel.DISPLAYALERTS # This should be the default, but CAN'T BE TOO CAREFUL
scl = parseInt prompt "Scale by 2^(n-1) (minimum 1)",1
drawStrs = {}
drawCom = 0

# I guess it uses some sort of JIT magic because functions have to be declared in order?
fixCoords = (coordArr) ->
  coordArr[0] = Math.round(coordArr[0]*Math.pow(2,scl-1))
  coordArr[1] = -Math.round(coordArr[1]*Math.pow(2,scl-1))
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
  for currLayer in [app.activeDocument.layers.length-1..0] by -1
    currLayer = app.activeDocument.layers[currLayer].name
    prompt("COPY THIS",drawStrs[currLayer].replace(/[ ]$/,""),"copy it") if drawStrs[currLayer]

zeroPad = (num) ->
  return "0"+num.toString(16) if num < 16
  return num.toString(16)

handleCMYK = (theColor) ->
  c = theColor.cyan/100; m = theColor.magenta/100
  y = theColor.yellow/100; k = theColor.black/100
  r = Math.round (1-c)*(1-k)*255
  b = Math.round (1-y)*(1-k)*255
  g = Math.round (1-m)*(1-k)*255
  ("&H"+zeroPad(b)+zeroPad(g)+zeroPad(r)+"&").toUpperCase()

handleGray = (theColor) ->
  pct = theColor.gray
  pct = Math.round pct*255/100
  ("&H"+zeroPad(pct)+zeroPad(pct)+zeroPad(pct)+"&").toUpperCase()

handleRGB = (theColor) ->
  r = Math.round theColor.red
  g = Math.round theColor.green
  b = Math.round theColor.blue
  ("&H"+zeroPad(b)+zeroPad(g)+zeroPad(r)+"&").toUpperCase()

manageColor = (currPath,field) ->
  switch currPath[field].typename
    when "RGBColor"
      return handleRGB currPath[field]
    when "GrayColor" 
      return handleGray currPath[field]
    when "CMYKColor"
      return handleCMYK currPath[field]
    when "noColor"
      return false
    else
      alert "Unsupported colorspace used."
      error()
  # "GradientColor"
  # "LabColor"
  # "PatternColor"
  # "SpotColor"

collectPaths = (callback) ->
  for currPath in app.activeDocument.pathItems
    lname = currPath.layer.name
    fgc = "\\c"+manageColor currPath,"fillColor"
    fgc = "\\1a&HFF&" unless fgc
    sc = "\\3c"+manageColor currPath,"strokeColor"
    sc = "\\3a&HFF&" unless sc
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

