ActorToken  = "Actor" !IdentifierPart

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

ActorDeclaration 
    = ActorToken __ name:Identifier __
    "{" __ elements:FunctionBody __ "}" {      
        return {
            type: "Actor",
            name: name,
            elements: elements
        };
    } 

