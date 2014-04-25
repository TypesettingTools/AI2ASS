## AI2ASS ##
![sweet screenshot][screenshit]

This is a script to export<sup>†</sup> drawings in Adobe Illustrator as ASS
vector objects. It was inspired by tophf's similar script for CorelDRAW.

<sub><sub><sup>†</sup>The exporting process consists of sticking generated
ASS into a window that has copyable text. This is still terrible design,
but at least it's slightly better than it used to be.</sub></sub>

### Features and Limitations

##### It only acts upon the currently focused document in Illustrator.

##### It should work with most versions of Illustrator.
Has been used with CS5, CS6 and CC versions of Illustrator.

##### Can export the current layer or all layers at once.

##### Shapes are separated by a their fill color, border color and layer.
Consecutive paths that share all these attributes will all be merged
into one line.

##### It supports RGB and Grayscale colorspaces
CMYK support may be added at some point in the future if I ever find a
conversion algorithm that works properly.

##### It can output shapes wrapped in {\p1}, \clip, \iclip, or output raw shape data.
All output shape data uses coördinates with two decimal places of
precision. Modern ASS renderers should be able to handle these properly.
If you are worried about people running horribly old and terrible
software, don't. If you're using this to do typesetting, odds are it'll
be to slow to run on their setup anyway.

### Great, but how do I run it? ###

Place [`AI2ASS Combined.jsx`][rawcomb] in your Illustrator
scripts folder. This is the easier way.

Alternately, place both [`AI2ASS.jsxinc`][raw] and [`AI2ASS
UI.jsx`][rawui] in your Illustrator scripts folder.

On OS X, the scripts folder should be something like
`/Applications/Adobe Illustrator CS6/Presets/en_US/Scripts`.

On Windows, it'll be `C:\Program Files\Adobe\Adobe Illustrator CS6 (64
Bit)\Presets\en_US\Scripts` , assuming you're running the 64-bit version
(thanks, __ar).

If you installed [`AI2ASS Combined.jsx`][rawcomb], it should appear in
the menu as `File > Scripts > AI2ASS Combined`. Running this will pop up
a persistent window with a button you can click to convert the active
layer into an ASS drawing. You don't need to close this ever. It's neat.

If you chose to install both of the other scripts instead, you'll have
to run the script using the Extendscript Toolkit, which may or may not
be installed by default. This is due to what appears to be a bug with
the `#include` preprocessor directive which, for some reason, causes the
window to disappear instantly when the script is not run from the ESTK.

#### WARNING: SHIT MOVES SLOW WHEN YOU HAVE A LOT OF STUFF GOING ON ####

But there's a cool progress bar so you can see that it's going slow.

### What the bloody hell does `collectInnerShadow` mean? ###

This script makes it easy to create an inner shadow effect in ASS by
turning the glyph outlines into ASS drawings and then clipping them to
the individual glyphs to which they correspond. To make this work, a
very specific layer layout is required. I will list the WorksForMe™
steps here and I cannot promise they will work for you or even for me on
another version of Illustrator. I have used this (and probably will only
ever use this) on Illustrator CS 5.5 on OS X.

The effect looks something like this:

![Inner Shadow][innerShadow]

#### STEPS ####
 1. Type what you want in the font you want.
 2. Convert the text into outlines.
 3. Add a stroke to it. Usually 4 px or so is good. Make sure it is aligned to the outside.
 4. In the menu: `Object > Path > Outline Stroke`
 5. Export with `collectInnerShadow`
 6. Use the macro provided by `applyLines.moon` to import them into Aegisub efficiently. That said, this macro is an inflexible piece of garbage because I just don't care.

### TODO ###
- AINT NOTHIN THIS IS PERFECT

[screenshit]: https://raw.github.com/torque/AI2ASS/master/screenshot.png
[raw]: https://raw.github.com/torque/AI2ASS/master/built/AI2ASS.jsxinc
[rawui]: https://raw.github.com/torque/AI2ASS/master/built/AI2ASS%20UI.jsx
[rawcomb]: https://raw.github.com/torque/AI2ASS/master/built/AI2ASS%20Combined.jsx
[innerShadow]: https://raw.github.com/torque/AI2ASS/master/innershadow.png
