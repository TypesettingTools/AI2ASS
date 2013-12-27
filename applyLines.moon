-- This script takes one line and turns it into many lines.

-- Usage: select 1 line (or a bunch, it actually doesn't matter because it only
-- uses the active line). Run the macro. It will copy all of the shape data from
-- AI2ASS on the clipboard into Aegisub, creating as many lines as necessary.
-- Note that due to me being a fucking idiot, it will just kind of paste
-- whatever the hell you have on the clipboard into the current line. I don't
-- care to fix this. I doubt anyone except me will ever use this. If you do and
-- you don't like this behavior, pull requests welcome.

require "clipboard"

string.split = ( sep ) =>
	sep, fields = sep or ":", {}
	string.gsub @, "([^#{sep}]+)", (c) -> table.insert fields, c
	fields

-- Creates lines on a glyph by glyph basis because libass eats shit on very long
-- lines. This looks terrible on fades and ends up bloating the script a lot
-- more, but it's easier than actually fixing libass myself. Oh, and all the
-- colors are hardcoded because I don't give half a shit. Fix it yourself if you
-- want to use it.
applyInnerShadow = ( sub, originalLine, lineTable ) ->
	len = #lineTable
	for x = 2, len-2, 2
		error "DONGS" if aegisub.progress.is_cancelled!
		originalLine.text = [[{\pos(2,2)\c&H000000&\blur2}]] .. lineTable[x]
		originalLine.layer = 2
		sub.insert originalLine.n, originalLine
		originalLine.text = [[{\pos(0,0)\c&H0000FF&}]] .. lineTable[x-1]
		originalLine.layer = 1
		sub.insert originalLine.n, originalLine
		originalLine.text = [[{\3c&HFFFFFF&\bord8}]] .. originalLine.text
		originalLine.layer = 0
		sub.insert originalLine.n, originalLine

	originalLine.text = [[{\pos(2,2)\c&H000000&\blur2}]] .. lineTable[len]
	originalLine.layer = 2
	sub.insert originalLine.n, originalLine
	originalLine.text = [[{\pos(0,0)\c&H0000FF&}]] .. lineTable[len-1]
	originalLine.layer = 1
	sub.insert originalLine.n, originalLine
	originalLine.text = [[{\3c&HFFFFFF&\bord8}]] .. originalLine.text
	originalLine.layer = 0
	sub[originalLine.n-1] = originalLine

createInnerShadow = ( sub, sel, act ) ->
	originalLine = sub[act]
	originalLine.n = act + 1
	incomingLines = clipboard.get!
	lineTable = incomingLines\split "\r\n"
	if lineTable[1]\match "{innerShadow}"
		table.remove lineTable, 1
		if #lineTable % 2 == 0
			applyInnerShadow sub, originalLine, lineTable
		else
			aegisub.log 0, "This shit is malformed and everything you do is wrong."
	elseif lineTable[1]\match "{allLayers}"
		table.remove lineTable, 1
		applyAllLayers sub, originalLine, lineTable
	else
		originalLine.text = lineTable
		sub[act] = originalLine

aegisub.register_macro "Apply AI Lines", "Handles paste data from AI2ASS", createInnerShadow
