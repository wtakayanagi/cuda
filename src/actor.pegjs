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
