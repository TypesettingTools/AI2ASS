gc "AI2ASS.coffee" | Out-File AI2ASScomb.coffee -e UTF8
gc "AI2ASS UI.coffee" | Out-File AI2ASScomb.coffee -e UTF8 -a
coffee -bc AI2ASScomb.coffee
mkdir built -f
mv AI2ASScomb.js built/AI2ASS.jsx -force
rm AI2ASScomb.coffee
