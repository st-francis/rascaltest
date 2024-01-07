module PoC::ChoreoLanguage::ChoreoConcrete

extend lang::std::Layout;
extend lang::std::Id;

start syntax ConcreteChoreography = "choreo" Id name ChoreographyContent content;

lexical Bool 
  = "true"
  | "false"
  ; 

lexical Int
  = [1-9][0-9]*
  | [0]
  ;

syntax ChoreographyContent = "{" ChoreographyConstruct choreographyConstruct "}";

syntax ChoreographyConstruct
          =  ProcessInteraction
          |  Assignment
          |  IfStatement
          |  WhileStatement
          >  right ChoreographyComposition: ChoreographyConstruct ";" ChoreographyConstruct
          ;

syntax IfStatement 
          = "if" "(" Expression ")" "{" ChoreographyConstruct "}" "else" "{" ChoreographyConstruct "}";

syntax WhileStatement
          = "while" "(" Expression ")" "{" ChoreographyConstruct "}";

syntax Expression 
          = Int
          | Bool
          | ProcessVariableCall
          > right Expression "==" Expression
          | Expression "!=" Expression
          > right (Expression "&&" Expression
          | Expression "||" Expression)
          ;

syntax AssignmentOperator
          = ":="
          | "+="
          ;          

syntax ProcessInteraction 
          =  ProcessVariableCall variableCallSen ExchangeValueDeclaration variableDeclaration "-\>" ProcessVariableCall variableCallRec
          |  ProcessName name ExchangeValueDeclaration variableDeclaration "-\>" ProcessVariableCall variableCallRec
          ;

syntax Assignment
          = ProcessName processName "." Variable variableName AssignmentOperator assingmentOperator VariableValue variableValue ":" Type variableType; 

syntax ProcessVariableCall = ProcessName name "." Variable variableName;

syntax ExchangeValueDeclaration = "(" VariableValue variableValue ":" Type variableType ")";

syntax ProcessName = Id;

syntax Variable = Id;

syntax VariableValue
  = Int
  | Bool
  ;
  
syntax Type 
  = "Int"
  | "Bool"
  ; 

keyword Reserved 
  = "process" 
  | "choreo"
  | "Bool"
  | "Int"
  ;