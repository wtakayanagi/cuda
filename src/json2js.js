/*
 * Unparser for JavaScript
 * This program takes a JSON tree that represents an abstract syntax
 * tree for JavaScript code and converts it to a textual program.
 */

var fs = require('fs');

var buf = [], indentLevel = 0, whitespaces = '    ', bol = true;
function newline() { B.push('\n'); bol = true; }

var B = { // Buffer
    push: function (/* args */) {
        for (var i = 0; i < arguments.length; i++) {
            this.indent();
            buf.push(arguments[i]);
        }
    },
    params: function (names) {
        if (names.length > 0) B.push(ident(names[0]));
        for (var i = 1; i < names.length; i++)
            this.format(', ', ident(names[i]));
    },
    separating: function (arr) {
        if (arr.length === 0) return;
        T(arr[0]);
        for (var i = 1; i < arr.length; i++) { this.push(', '); T(arr[i]); }
    },
    terminating: function (arr) {
        arr.forEach(function (a) { B.format(a, ';', newline); });
    },
    format: function (/* args */) {
        this.indent();
        for (var i = 0; i < arguments.length; i++) {
            var a = arguments[i];
            if (a == null) ;
            else if (Array.isArray(a)) {
                var sep = arguments[i+1]; i++;
                if (sep === ',') this.separating(a, sep);
                else if (sep === ';') this.terminating(a, sep);
            } else if (typeof a === 'object' && a.type) T(a);
            else if (typeof a === 'string') this.push(a);
            else if (typeof a === 'number') indentLevel += a;
            else if (typeof a === 'function') a();
            else console.error('I do not know what to do with: ', a);
        }
    },
    indent: function () {
        if (!bol) return;
        while (whitespaces.length < indentLevel)
            whitespaces += whitespaces;
        buf.push(whitespaces.substr(0, indentLevel));
        bol = false;
    },
    flush: function (fd) {
        if (fd) {
            newline();
            buf.forEach(function (line) { fs.writeSync(fd, line); });
            this.reset();
        } else {
            var result = buf.join('');
            this.reset();
            return result;
        }
    },
    reset: function () { buf = []; indentLevel = 0; }
};

var unwanted_characters = '`.*';
function ident(identifier) {
    var chars = identifier.split('');
    for (var i = 0; i < chars.length; i++)
        if (unwanted_characters.indexOf(chars[i]) >= 0) chars[i] = '_';
    return chars.join('');
}

var unparser = {
    BooleanLiteral: function (t) { B.push(t.value); },
    NullLiteral: function (t) { B.push('null'); },
    NumericLiteral: function (t) { B.push(t.value); },
    RegularExpressionLiteral: function (t) { B.push(t.body, t.flags); },
    StringLiteral: function (t) { B.push(JSON.stringify(t.value)); },

    ArrayLiteral: function (t) { B.format('[', t.elements, ',', ']'); },
    ObjectLiteral: function (t) { B.format('{', t.properties, ',', '}'); },

    This: function (t) { B.push('this'); },

    Function: function (t) {
        var isBOL = bol;
        if (t.name !== null) B.format('function ', ident(t.name), ' (');
        else B.push('function (');
        B.params(t.params);
        B.format(') {', 2, newline, t.elements, ';', -2, '}');
        if (isBOL) { B.push(';'); newline(); }
    },

    UnaryExpression: function (t) {
        B.format('(', t.operator, ' ', t.expression, ')');
    },
    PostfixExpression: function (t) {
        B.format('(', t.expression, ' ', t.operator, ')');
    },
    AssignmentExpression: function (t) {
        B.format('(', t.left, ' ', t.operator, ' ', t.right, ')');
    },
    BinaryExpression: function (t) {
        B.format('(', t.left, ' ', t.operator, ' ', t.right, ')');
    },
    ConditionalExpression: function (t) {
        B.format('(', t.condition, '?',
            t.trueExpression, ':', t.falseExpression, ')');
    },

    FunctionCall: function (t) {
        B.format('(', t.name, '(', t.arguments, ',', '))');
    },

    GetterDefinition: function (t) {
        B.format('get ', ident(t.name), ' {', 2, t.body, ';', -2, '}');
    },
    NewOperator: function (t) {
        B.format('(new ', t.constructor, '(', t.arguments, ',', '))');
    },
    PropertyAccess: function (t) {
        if (typeof t.name === 'string')
            B.format('(', t.base, '.', ident(t.name), ')');
        else B.format('(', t.base, '[', t.name, ']', ')');
    },
//  PropertyAccessProperty: function (t) { },
    PropertyAssignment: function (t) {
        B.format(t.name, ': ', t.value);
    },
    SetterDefinition: function (t) {
        B.format('set ', ident(t.name), '(', t.param.map(ident), ',', ')',
            t.body, ';');
    },

    Variable: function (t) { B.push(ident(t.name)); },
    VariableDeclaration: function (t) {
        if (t.value) B.format(t.name, ' = ', t.value);
        else B.format(t.name);
    },
    VariableStatement: function (t) {
        if (bol) B.format('var ', t.declarations, ',', ';', newline);
        else B.format('var ', t.declarations, ',');
    },

    BreakStatement: function (t) {
        if (t.label) B.format('break ', t.label);
        else B.push('break');
    },
    ContinueStatement: function (t) {
        if (t.label) B.format('continue ', t.label);
        else B.push('continue');
    },
    DebuggerStatement: function (t) { B.push('debugger'); },
    DoWhileStatement: function (t) {
        B.format('do ', t.statement);
        if (t.statement.type !== 'Block') B.format(';', newline);
        B.format('while (', t.condition, ')');
    },
    EmptyStatement: function (t) { B.push(';'); },
    ForInStatement: function (t) {
        B.format('for (var ', t.iterator, ' in ', t.collection, ') ',
            t.statement);
    },
    ForStatement: function (t) {
        B.format('for (', t.initializer, '; ', t.test, '; ', t.counter, ') ',
            t.statement, t.statement.type !== 'Block' ? ';' : '');
    },
    IfStatement: function (t) {
        B.format('if (', t.condition, ') ', t.ifStatement);
        if (t.elseStatement) {
            B.format(newline, 'else ', t.elseStatement);
            if (t.elseStatement !== 'Block') B.push(';');
        }
    },
    LabelledStatement: function (t) { B.format(t.label, ': ', t.statement); },
    ReturnStatement: function (t) {
        B.format('return ', t.value ? t.value : '');
    },
    SwitchStatement: function (t) {
        B.format('switch (', t.expression, ') {', 2);
        t.clauses.forEach(T);
        B.format(-2, '}');
    },
    CaseClause: function (t) {
        B.format('case ', t.selector, ': ', 2, t.statements, ';', -2);
    },
    DefaultClause: function (t) {
        B.format('default: ', 2, t.statements, ';', -2);
    },
    TryStatement: function (t) {
        B.format('try ', t.block, t.catch, t.finally);
    },
    Catch: function (t) {
        B.format(' catch (', ident(t.identifier), ') ', t.block);
    },
    Finally: function (t) {
        B.format(' finally ', t.block);
    },
    ThrowStatement: function (t) { B.format('throw ', t.exception); },
    WhileStatement: function (t) {
        B.format('while (', t.condition, ') ', t.statement);
    },
    WithStatement: function (t) {
        B.format('with (', t.environment, ')', t.statement);
    },

    Block: function (t) {
        if (t.statements.length === 0) B.format('{}');
        else B.format('{', 2, newline, t.statements, ';', -2, '}');
    },
    Program: function (t) {
        if (t.variables) 
            t.variables.forEach(function (v) {
                    B.format('var ', v, ';', newline);
                });
        t.elements.map(function (t) { T(t); });
    },
    ExpressionMacroDefinition: function (t) {},
    Characterstmt: function (t) {}
};

function T(t) {
    if (!t ) return;
    var unparse = unparser[t.type];
    if (unparse) return unparse(t);
    throw(new Error({ message: 'Unknown type', t: JSON.stringify(t) }));
}

exports.convert = function (t, output) {
    var fd = false;
    if (typeof output === 'number') fd = output;
    if (typeof output === 'string') {
        fd = fs.openSync(output, 'w');
    }
    B.format(B.reset, t);
    var result = B.flush(fd);
    if (fd) fs.closeSync(fd);
    return result;
};
