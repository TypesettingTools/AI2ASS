## AI2ASS ##
This is a script to "export"\* drawings in Adobe Illustrator as ASS vector objects. It was inspired by tophf's similar plugin for coreldraw.

It only acts upon the currently focused document.

It currently treats each layer as a single drawing. This should probably be changed.

It inserts the fill and stroke color of the first object on each layer. This is why the per-layer-shape design should be changed.

It supposedly supports RGB, grayscale and CMYK colorspaces. The CMYK conversion is downright wrong. Don't use it. I don't even know why I bothered to say it was supported in the first place.

This has been tested with Illustrator CS6 on OS X. Feel free to complain if it does not work for you. I might even try to fix it. That said, theoretically it should work with any version of illustrator back to CS 2.

### Great, but how do I run it? ###

Place `AI2ASS.jsx` in your Illustrator scripts folder. The actual location of this folder will depend on your operating system and the version of Illustrator you are using.

On OS X, it should be something like `/Applications/Adobe Illustrator CS6/Presets/en_US/Scripts`

I'm guessing it's something along the lines of `C:\Program Files\Adobe Illustrator CS6\Presets\en_US\Scripts` on Windows. Someone please correct this for me.

After that, it should appear in the menu as `File > Scripts > AI2ASS`.

#### TODO ####
- Switch to per-compound-path-shape design (this may end up being ugly and complicated).
- use stroke width for `\bord` ()
- produce centered drawings for `\an5`
- support gradients? (I have no idea how to even start)

\*"export" is in quotes because the interface consists of a prompt that pops up with copy-able text. This is terrible design, but I don't know of a better way to do it, given the restrictions of the scripting interface.