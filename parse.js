var fs = require('fs');
var util = require('util');
var js = require('./cuda');

fs.readFile('./example/simple.actor',
    function (err, input) {
        input = '' + input;
        var tree = js.parse(input, 'start');

        util.print(JSON.stringify(tree, null, 2));
    });
