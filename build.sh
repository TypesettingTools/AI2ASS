#!/bin/sh

cat AI2ASS.coffee "AI2ASS UI.coffee" > AI2ASScomb.coffee
coffee -bc AI2ASScomb.coffee
mv AI2ASScomb.js built/AI2ASS.jsx
rm AI2ASScomb.coffee
