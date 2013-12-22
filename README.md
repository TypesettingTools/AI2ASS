## AI2ASS ##
![sweet screenshot][screenshit]

This is a script to export<sup>†</sup> drawings in Adobe Illustrator as ASS
vector objects. It was inspired by tophf's similar script for CorelDRAW.

It only acts upon the currently focused document.

It currently only cares about the active layer, and it treats it as a single
drawing.

It inserts the fill and stroke color of the first object on the layer. This is
why the per-layer-shape design should be changed.

It supposedly supports RGB, grayscale and CMYK colorspaces. The CMYK conversion
is downright wrong. Don't use it. I don't even know why I bothered to say it was
supported in the first place.

This has been tested with Illustrator CS6/5 on OS X. Feel free to complain if it
does not work for you. I might even try to fix it. That said, theoretically it
should work with any version of Illustrator back to CS3.

### Great, but how do I run it? ###

Place [`AI2ASS.jsx`][raw] in your Illustrator scripts folder. The actual
location of this folder will depend on your operating system and the version of
Illustrator you are using.

On OS X, it should be something like `/Applications/Adobe Illustrator
CS6/Presets/en_US/Scripts`.

On Windows, it'll be `C:\Program Files\Adobe\Adobe Illustrator CS6 (64 Bit)\Presets\en_US\Scripts`
, assuming you're running the 64-bit version (thanks, __ar).

After that, it should appear in the menu as `File > Scripts > AI2ASS`. Running
this will pop up a persistent window with a button you can click to convert the
active layer into an ASS drawing. You don't need to close this ever. It's neat.

### What the bloody hell does `collectInnerShadow` mean? ###

This script makes it easy to create an inner shadow effect in ASS by turning the
glyph outlines into ASS drawings and then clipping them to the individual glyphs
to which they correspond. To make this work, a very specific layer layout is
required. I will list the WorksForMe™ steps here and I cannot promise they will
work for you or even for me on another version of Illustrator. I have used this
(and probably will only ever use this) on Illustrator CS 5.5 on OS X.

#### STEPS ####
 1. Type what you want in the font you want.
 2. Convert the text into outlines.
 3. Add a stroke to it. Usually 4 px or so is good. Make sure it is aligned to the outside.
 4. In the menu: `Object > Path > Outline Stroke`
 5. Export with `collectInnerShadow`
 6. Use the macro I haven't written yet to import them into Aegisub efficiently.

### TODO ###
- AINT NOTHIN THIS IS PERFECT

<sup>†</sup>The exporting process consists of sticking generated ASS into a
window that as copyable text. This is terrible design, but I don't know of a
better way to do it given the restrictions of the scripting interface.

[screenshit]: https://raw.github.com/torque/AI2ASS/master/screenshot.png
[raw]: https://raw.github.com/torque/AI2ASS/master/AI2ASS.jsx
