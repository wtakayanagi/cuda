SourceElements
    = head:SourceElement tail:(__ SourceElement)* {
        var result = [head];
        for (var i = 0; i < tail.length; ++i) {
            result.push(tail[i][1]);
        }
        return result;
    }

SourceElement
    = ActorDeclaration
    / Statement

FunctionBody
    = elements:Statements? { return elements !== "" ? elements : []; }

Statements
    = head:Statement tail:(__ Statement)* {
        var result = [head];
        for (var i = 0; i < tail.length; i++) {
            result.push(tail[i][1]);
        }
        return result;
    }

ActorToken  = "Actor" !IdentifierPart { return "Actor"; }
VarToken = "int" !IdentifierPart { return "int"; }

ActorDeclaration 
    = ActorToken __ name:Identifier __
    "{" __ elements:ActorBody? __ "}" {      
        return {
            type: "Actor",
            name: name,
            elements: elements !== "" ? elements : []
        };
    } 

ActorBody
    = head:ActorElement tail:(__ ActorElement)* {
        var result = [head];
        for (var i = 0; i < tail.length; i++) {
            result.push(tail[i][1]);
        }
        return result;
    }

ActorElement
    = Statement
    / MethodDeclaration

VariableStatement
    = typeSpecifier:TypeSpecifier __ declarations:VariableDeclarationList EOS {
        return {
            type: "VariableStatement",
            typeSpecifier: typeSpecifier,
            declarations: declarations
        };
    }

TypeSpecifier
    = VarToken
    / ActorToken
    / Identifier

MethodDeclaration
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
    = typeSpecifier:TypeSpecifier __ name:Identifier {
        return {
            type: "Parameter",
            typeName: typeSpecifier,
            name: name
        };
    }
