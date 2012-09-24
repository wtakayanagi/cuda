start
    = __ program:program __ { return program; }

program
    = elements:source_elements? {
        return {
            type: "Program",
            elements: elements !== "" ? elements : []
        };
    } 

source_elements
    = head:source_element tail:(__ source_element)* {
        var result = [head];
        for (var i = 0; i < tail.length; i++) {
            result.push(tail[i][1]);
        }
        return result;
    }

source_element
    = statement

// Lexical
identifier
    = !keyword name:identifier_name { return name; }

identifier_name
    = start:identifier_start parts:(identifier_part)* {
        return start + parts.join("");
    }

identifier_start
    = "_"
    / unicode_letter

identifier_part
    = identifier_start
    / unicode_digit

unicode_letter
    = [a-zA-z]

unicode_digit
    = [0-9]

keyword 
    = new_token
    / case_token
    / switch_token
    / for_token
    / default_token
    / while_token
    / do_token
    / return_token
    / if_token
    / else_token
    / continue_token
    / break_token
    / int_token
    / actor_token

new_token = "new" !identifier_part
case_token = "case" !identifier_part
switch_token = "switch" !identifier_part
for_token = "for" !identifier_part
default_token = "default" !identifier_part
while_token = "while" !identifier_part
do_token = "do" !identifier_part
return_token = "return" !identifier_part
if_token = "if" !identifier_part
else_token = "else" !identifier_part
continue_token = "continue" !identifier_part
break_token = "break" !identifier_part
int_token = "int" !identifier_part { return "int"; }
actor_token = "Actor" !identifier_part { return "Actor"; }

// Expression
argument_expression_list
    = head:assignment_expression tail:(__ "," __ assignment_expression)* { 
        var result = [head];
        for (var i = 0; i < tail.length; ++i) {
            result.push(tail[i][3]);
        }
        return result;
    }

additive_expression
    = head:multiplicative_expression tail:(__ ("+" / "-") __ multiplicative_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    }

multiplicative_expression
    = head:unary_expression tail:(__ ("*" / "/" / "%") __ unary_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    }

unary_expression
    = postfix_expression
    / operator:unary_operator __ expression:unary_expression {
        return {
            type: "UnaryExpression",
            operator: operator,
            expression: expression
        };
    }

postfix_expression
    = expression:primary_expression operation:(__ postfix_operation)* {
        var result  = expression;
        for (var i = 0; i < operation.length; ++i) {
            result = {
                type: "PostfixExpression",
                base: expression,
                operation: operation[i][1]
            }
        }
        return result;
    }

primary_expression
    = name:identifier { return { type: "Variable", name: name }; }
    / constant
    / "(" __ expression:expression __ ")" { return expression; }

constant
    = value:decimal_literal { 
        return { 
            type: "NumericLiteral",
            value: value
        }; 
    }

decimal_literal
    = "0" / digit:nonzero_digit digits:decimal_digits? { return digit + digits; }
    
decimal_digits
    = digits:decimal_digit+ { return digits.join(""); }

decimal_digit
    = [0-9]

nonzero_digit
    = [1-9]

postfix_operation
    = postfix_operator
    / array_expression
    / call_expression
    / member_expression

array_expression
    = "[" __ accessor:expression __ "]" { return { type: "ArrayAccess", expression:accessor }; }

new_expression
    = new_token __ name:identifier __ constructor:call_expression {
        return {
            type: "NewOperator",
            name: name,
            constructor: constructor
        };
    }

call_expression
    = "(" __ arguments:argument_expression_list? __ ")" {
        return {
            type: "FunctionCall",
            arguments: arguments !== "" ? arguments : []
        }; 
    }

member_expression
    = "." name:identifier {
        return {
            type: "PropertyAccess",
            name: name
        };
    }

unary_operator
    = "++"
    / "--"
    / "+"
    / "-"

postfix_operator
    = "++"
    / "--"

expression
    = head:assignment_expression tail:(__ "," __ assignment_expression)* {
        var result = [head];
        for (var i = 0; i < tail.length; ++i) {
            result.push(tail[i][3]);
        }
        return result;
    }

constant_expression
    = conditional_expression

assignment_expression
    = left:lvalue __ operator:assignment_operator __ right:assignment_expression {
        return {
            type: "AssignmentExpression",
            operator: operator,
            left: left,
            right: right
        };
    }
    / new_expression
    / conditional_expression

lvalue
    = unary_expression

assignment_operator
	= "="
	/ "*="
	/ "/="
	/ "%="
	/ "+="
	/ "-="
	/ "<<="
	/ ">>="
	/ "&="
	/ "^="
	/ "|="

conditional_expression
    = condition:logical_or_expression __ 
    "?" __ true_expression:expression __ 
    ":" __ false_expression:conditional_expression {
        var result = {
            type: "ConditionalExpression",
            condition: condition,
            true_expression: true_expression !== "" ? true_expression : null,
            false_expression: false_expression !== "" ? false_expression : null
        }; 
        return result;
    }
    / logical_or_expression

logical_or_expression
    = head:logical_and_expression tail:(__ "||" __ logical_and_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    }

logical_and_expression
    = head:inclusive_or_expression tail:(__ "&&" __ inclusive_or_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    } 

inclusive_or_expression
    = head:exclusive_or_expression tail:(__ "|" __ exclusive_or_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    }

exclusive_or_expression
    = head:and_expression tail:(__ "^" and_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    }

and_expression
    = head:equality_expression tail:(__ "&" __ equality_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    }

equality_expression
    = head:relation_expression tail:(__ ("==" / "!=") __ relation_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    }  

relation_expression
    = head:shift_expression tail:(__ ("<=" / ">=" / "<" / ">") __ shift_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    }

shift_expression
    = head:additive_expression tail:(__ ("<<" / ">>") __ additive_expression)* {
        var result = head;
        for (var i = 0; i < tail.length; ++i) {
            result = {
                type: "BinaryExpression",
                operator: tail[i][1],
                left: result,
                right: tail[i][3]
            };
        }
        return result;
    }

// Statements
statement 
    = block
    / variable_statement
    / labeled_statement
    / expression_statement
    / selection_statement
    / iteration_statement
    / jump_statement
    / actor_declaration

block
    = "{" __ statements:(statement_list __)? "}" {
        return {
            type: "Block",
            statements: statements !== "" ? statements[0] : []
        }
    }

variable_statement
    = type_specifier:type_specifier __ declarations:variable_declaration_list EOS {
        return {
            type: "VariableStatement",
            type_specifier: type_specifier,
            declarations: declarations
        };
    }
    
type_specifier
    = int_token
    / actor_token
    / identifier

variable_declaration_list
    = head:variable_declaration tail:(__ "," __ variable_declaration)* {
        var result = [head];
        for (var i = 0; i < tail.length; ++i) {
            result.push(tail[i][3]);
        }
        return result;
    }

variable_declaration
    = name:identifier __ value:intialiser? {
        return {
            type: "VariableDeclaration",
            name: name,
            value: value !== "" ? value : null 
        };
    }

intialiser
    = "=" (!"=") __ expression:assignment_expression { return expression; }

statement_list
    = head:statement tail:(__ statement)* {
        var result = [head];
        for (var i = 0; i < tail.length; ++i) {
            result.push(tail[i][1]);
        }
        return result;
    }

labeled_statement
    = case_token __ selector:constant_expression __ ":" __ statement:statement {
        return {
            type: "CaseClause",
            selector: selector,
            statement: statement
        }; 
    }
    / default_token __ ":" __ statement:statement {
        return {
            type: "DefaultClause",
            statement: statement
        };
    }

expression_statement
    = ";" { return { type: "EmptyStatement" }; }
    / expression:expression ";" { return expression; }

selection_statement
    = if_token __ 
    "(" __ condition:expression __ ")" __
    if_statement:statement
    else_statement:(__ else_token __ statement)? {
        return {
            type: "IfStatement",
            condition: condition,
            if_statement: if_statement,
            else_statement: else_statement !== "" ? else_statement[3] : null
        };
    }
    / switch_token __ "(" __ expression:expression __ ")" __ clauses:statement {
        return {
            type: "SwitchStatement",
            expression: expression,
            clauses: clauses
        };
    }

iteration_statement
    = while_token __ "(" __ condition:expression __ ")" __ statement:statement {
        return {
            type: "WhileStatement",
            condition: condition,
            statement: statement
        };
    }
    / do_token __ statement:statement __ while_token __ "(" __ condition:expression __ ")" __ EOS {
        return {
            type: "DoWhileStatement",
            condition: condition,
            statement: statement
        };
    }
    / for_token __
    "(" __
    initializer:expression_statement __ test:expression_statement __ counter:expression? __
    ")" __
    statement:statement {
        return {
            type: "ForStatement",
            initializer: initializer !== "" ? initializer : null,
            test: test !== "" ? test : null,
            counter: counter !== "" ? counter : null,
            statement: statement
        };
    } 

jump_statement
    = continue_token __ EOS { return { type: "ContinueStatement" }; }
    / break_token __ EOS { return { type: "BreakStatement" }; }
    / return_token __ value:expression? __ EOS {
        return {
            type: "ReturnStatement",
            value: value !== "" ? value : null
        };
    }

actor_declaration
    = actor_token __ name:identifier __
    "{" __ elements:actor_body? __ "}" {
        return {
            type: "Actor",
            name: name,
            elements: elements !== "" ? elements: []
        };    
    }

actor_body
    = head:actor_element tail:(__ actor_element)* {
        var result = [head];
        for (var i = 0; i < tail.length; ++i) {
            result.push(tail[i][1]);
        }
        return result;
    }

actor_element
    = statement 
    / method_declaration

method_declaration
    = name:identifier __ 
    "(" __ params:method_parameter_list? __ ")" __
    "{" __ elements:function_body __ "}" {
      return {
        type: "Method",
        name: name,
        params: params !== "" ? params : [],
        elements: elements
      };
    }

function_body
    = elements:source_elements? { return elements !== "" ? elements : []; }

method_parameter_list
  = head:type_identifier tail:(__ "," __ type_identifier)* {
      var result = [head];
      for (var i = 0; i < tail.length; i++) {
        result.push(tail[i][3]);
      }
      return result;
    }

type_identifier
    = typeName:type_specifier __ name:identifier {
        return {
            typeName: typeName,
            name: name
        };
    }

__ "whitespace"
    = [ \t\n\r]*

EOS 
    = ";"
