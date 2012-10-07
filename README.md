## AI2ASS ##
This is a script to "export"\* drawings in Adobe Illustrator as ASS vector objects. It was inspired by tophf's similar script for CorelDRAW.

It only acts upon the currently focused document.

It currently treats each layer as a single drawing. This should probably be changed.

It inserts the fill and stroke color of the first object on each layer. This is why the per-layer-shape design should be changed.

It supposedly supports RGB, grayscale and CMYK colorspaces. The CMYK conversion is downright wrong. Don't use it. I don't even know why I bothered to say it was supported in the first place.

This has been tested with Illustrator CS6 on OS X. Feel free to complain if it does not work for you. I might even try to fix it. That said, theoretically it should work with any version of Illustrator back to CS2.

### Great, but how do I run it? ###

Place [`AI2ASS.jsx`][raw] in your Illustrator scripts folder. The actual location of this folder will depend on your operating system and the version of Illustrator you are using.

On OS X, it should be something like `/Applications/Adobe Illustrator CS6/Presets/en_US/Scripts`.

On Windows, it'll be `C:\Program Files\Adobe\Adobe Illustrator CS6 (64 Bit)\Presets\en_US\Scripts`, assuming you're running the 64-bit version (thanks, __ar).

After that, it should appear in the menu as `File > Scripts > AI2ASS`.

#### TODO ####
- Switch to per-compound-path-shape design (this may end up being ugly and complicated).
- Use stroke width for `\bord` (maybe?)
- Make use of ScriptUI for ease-of-use.
- Produce centered drawings for `\an5`
- Support gradients? (I have no idea how to even start)

\*"Export" is in quotes because the interface consists of a prompt that pops up with copyable text. This is terrible design, but I don't know of a better way to do it given the restrictions of the scripting interface.

[raw]: https://raw.github.com/torque/AI2ASS/master/AI2ASS.jsx