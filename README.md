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

##### Shapes are separated both by layer and the prefixes of the chosen output format (which may include color, stroke, opacity and clipping paths).
Paths that share all these attributes can be merged into a single line.
The following merge strategies are available:

+ __Disabled__: turns line merging off
+ __Safe__: merges lines in a way that doesn't disturb your scene graph order
+ __Ignore Blending Order__: merges all paths of a layer sharing a common prefix without respect to their order within the layer.

##### It supports RGB and Grayscale colorspaces
CMYK support may be added at some point in the future if I ever find a
conversion algorithm that works properly.

##### It can output shapes wrapped in {\p1}, \clip, \iclip, raw shape data, or complete dialogue lines.
All output shape data uses coordinates with two decimal places of
precision. Modern ASS renderers should be able to handle these properly.
If you are worried about people running horribly old and terrible
software, don't. If you're using this to do typesetting, odds are it'll
be too slow to run on their setup anyway.

##### Exports clipping paths as \clips of their respective lines

##### There is basic transparency support
AI2ASS correctly calculates the opacity for every path and exports it as
`\alpha` override tag. However, output will only be correct when not
using any of the blending modes unsupported in ASS (which is all of them
except the *Normal* mode).

### Great, but how do I run it? ###

Place [`AI2ASS.jsx`][raw] in your Illustrator
scripts folder.

On OS X, the scripts folder should be something like
`/Applications/Adobe Illustrator CS6/Presets/en_US/Scripts`.

On Windows, it'll be `C:\Program Files\Adobe\Adobe Illustrator CS6 (64
Bit)\Presets\en_US\Scripts` , assuming you're running the 64-bit version
(thanks, __ar).

If you launch Illustrator, the script should now appear in the menu as
`File > Scripts > AI2ASS`. Running this will pop up a persistent window
with a button you can click to convert the active layer into an ASS
drawing. You don't need to close this ever. It's neat.

#### WARNING: SHIT MOVES SLOW WHEN YOU HAVE A LOT OF STUFF GOING ON ####

But there's a cool progress bar so you can see that it's going slow.

### TODO ###
- AINT NOTHIN THIS IS PERFECT

[screenshit]: https://raw.github.com/torque/AI2ASS/master/screenshot.png
[raw]: https://raw.github.com/torque/AI2ASS/master/built/AI2ASS.jsx
