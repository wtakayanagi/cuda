ActorToken  = "Actor" !IdentifierPart
NewToken = "new" !Identifier { return "new"; }

Statement
  = Block
  / VariableStatement
  / EmptyStatement
  / ExpressionStatement
  / IfStatement
  / IterationStatement
  / ContinueStatement
  / BreakStatement
  / ReturnStatement
  / WithStatement
  / LabelledStatement
  / SwitchStatement
  / ThrowStatement
  / TryStatement
  / DebuggerStatement
  / FunctionDeclaration
  / FunctionExpression
  / ActorDeclaration
  / ActorDefinition
  / MethodDefinition

ActorDeclaration 
    = ActorToken __ name:Identifier __
    "{" __ elements:FunctionBody __ "}" {      
        return {
            type: "ActorDeclaration",
            name: name,
            elements: elements
        };
    } 

ActorDefinition
    = objectType:Identifier __ objectName:Identifier __ 
    "=" __ NewToken __ constructor:Identifier __ arguments:Arguments EOS {
        return  {
            type: "ActorDefinition",
            objectType: objectType,
            objectName: objectName,
            constructor: constructor,
            arguments: arguments
        }
    }
    / objectType:Identifier __ objectName:Identifier __ EOS {
        return  {
            type: "ActorDefinition",
            objectType: objectType,
            objectName: objectName,
        }
    }

MethodDefinition
    = name:Identifier __ 
    "(" __ params:MethodParameterList? __ ")" __
    "{" __ elements:FunctionBody __ "}" {
      return {
        type:     "Method",
        name:     name,
        params:   params !== "" ? params : [],
        elements: elements
      };
    }

MethodParameterList
  = head:TypeIdentifier tail:(__ "," __ TypeIdentifier)* {
      var result = [head];
      for (var i = 0; i < tail.length; i++) {
        result.push(tail[i][3]);
      }
      return result;
    }

TypeIdentifier
    = typeName:(VarToken / ActorToken) __ name:Identifier {
        return {
            type: "Variable",
            typeName: typeName,
            name: name
        };
    }
