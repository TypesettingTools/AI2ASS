#!/bin/sh

cat "AI2ASS UI.coffee" AI2ASS.coffee > AI2ASScomb.coffee
coffee -bc AI2ASS.coffee AI2ASScomb.coffee
mv AI2ASS.js built/AI2ASS.jsxinc
mv AI2ASScomb.js built/AI2ASS.jsx
rm AI2ASScomb.coffee
