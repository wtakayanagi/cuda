# cat src/javascript.pegjs src/actor.pegjs > cuda.pegjs
pegjs src/c.pegjs
rm src/c.js .
node parse.js
