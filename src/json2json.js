#!/usr/local/bin/node

var assert = require('assert');
var fs = require('fs');
var util = require('util');
var js = require('./actor_parser');


actorList = [], methodList = [];

var getEnv = function () {

	var fieldNames = {};

	'arguments,base,block,catch,clauses,collection,condition,counter,declarations,elseStatement,environment,exception,expressionleft,falseExpression,finally,ifStatement,initializer,iterator,right,selector,statement,statements,test,trueExpression,value'.split(',').forEach(function (name) { fieldNames[name] = true; });

	var H = {

		_: function(t, env) {
			for (var f in t) if (fieldNames[f]) G(t[f], env);
		},

		Program: function (t, env) {
			t.elements.forEach(function (t) { getEnv(t, env); });
		},

		Actor: function (t, env) {
			var a = {
				name: "",
				fields: {
					to: [],
					state: []
				},
				methods: []
			};
			a.name = t.name.toUpperCase();
			var lag = 0;
			t.elements.forEach(function (node, index) { 
				getEnv(node, a);
			   	if (node.type === 'VariableStatement') {
					t.elements.splice(index-lag, 1);
					lag++;
				}
			});
			actorList.push(a);
		},

		VariableStatement: function (t, env) {
			var type = t.typeSpecifier;
			t.declarations.forEach(function (t) {
				assert.equal('VariableDeclaration', t.type);
				if (type === "int" && env.fields) {
					var name = env.name + "_" + t.name.toUpperCase();
					env.fields.state.push(name);
				} else if (type === "Actor" && env.fields) {
					var name = env.name + "_" + t.name.toUpperCase();
					env.fields.to.push(name);
				} else console.error('error');
			});
		},

		VariableDeclaration: function (t, env) {
			env.push(t.name.toUpperCase());
			// I assume this type is never used. ..There is an error here.
		},

		Method: function (t, env) {
			var m = {
				name: "",
				params: {
					to: [],
					data: []
				}
			};
			m.name = "FUNC_" + t.name.toUpperCase();
			t.params.forEach(function (t) { 
				assert.equal('Parameter', t.type);
				G(t, m); 
			});
			delete t.params;  // after memorizing method's params
			if (env.methods) env.methods.push(m);
			else console.error('error');
			var isdup = false;
			methodList.forEach(function (method) {
				if (method.name === m.name) isdup = !isdup;
			});
			if (!isdup) methodList.push(m);
		},

		Parameter: function (t, env) {
			var type = t.typeName;
			var name = env.name + "_" + t.name.toUpperCase();
			if (type === 'int' && env.params) env.params.data.push(name);
			else if (type === 'Actor' && env.params) env.params.to.push(name);
			else console.error('error');
		}

	};

	var G = function (t, env) {
		if (Array.isArray(t))
			t.forEach(function (t) { getEnv(t, env); });
		else if (typeof(t) === 'object') {
			(H[t.type] || H._)(t, env);
		}
	};

	return G;

}();


var currentActor = "";
var init = "";

var js2cu = function () {

	var start = false;

	var H = {
		_: function (t, env) {
			
		},

		Actor: function (t, env) {
			currentActor = t.name;
			if (currentActor === "Main") {
				// making initialize function
			} else if (!start) {
				start = !start;
				t.type = 'SwitchStatement';
				delete t.name;
				var expression = t.expression = {
					type: 'Variable',
					name: 'type'
				};
				var clauses = t.clauses = [];
				t.elements.forEach(function (t) { js2cu(t, clauses); });
				delete t.elements;
			} else {
				delete t.type;
				delete t.name;
				t.elements.forEach(function (t) { js2cu(t, env); });
				delete t.elements;
			}
		},

		Method: function (t, env) {
			t.type = 'CaseClause';
			var name = "FUNC_" + t.name.toUpperCase();
			delete t.name;
			var method = {};
			methodList.forEach(function(list, index) {
				if (list.name === name) method = list.splice(index, 1)[0];
			});

			env.push(t);
		}
	};

}();


var argv = process.argv;
for (var i = 2; i < argv.length; i++) {
		fs.readFile(argv[i],
				function (err, input) {
						input = '' + input;
						var tree = js.parse(input, 'start');

						//util.print(JSON.stringify(tree, null, 2) + "\n");

						getEnv(tree);

						util.print(JSON.stringify(tree, null, 2) + "\n");
						//util.print(JSON.stringify(actorList, null, 2) + "\n");
						//util.print(JSON.stringify(methodList, null, 2) + "\n");
				});
}
