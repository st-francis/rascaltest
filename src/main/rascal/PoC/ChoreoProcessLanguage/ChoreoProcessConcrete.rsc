module PoC::ChoreoProcessLanguage::ChoreoProcessConcrete

import PoC::ChoreoLanguage::ChoreoConcrete;

extend lang::std::Layout;
extend lang::std::Id;

start syntax ChoreographyProcess = "process" Id processName ChoreographyProcessContent content;

syntax ChoreographyProcessContent = "{" ProcessConstruct* processConstructs "}";

syntax ProcessConstruct
        = InteractionLine
        | TauConstruct
        | ProcessAssignment
        | IfStatement
        | WhileStatement
        > right SequentialComposition: ProcessConstruct ";" ProcessConstruct
        ;

syntax IfStatement 
        = "if" "(" Expression ")" "{" ProcessConstruct "}" "else" "{" ProcessConstruct "}";

syntax WhileStatement 
        = "while" "(" Expression ")" "{" ProcessConstruct "}";

syntax InteractionLine 
        = InteractionInput 
        | InteractionOutput
        ;  

syntax InteractionOutput 
        = ProcessName outputProcess "!" Variable variableName "(" VariableValue variableValue ":" Type variableType ")"
        | ProcessName outputProcess "!(" VariableValue variableValue ":" Type variableType ")"
        ;

syntax ProcessAssignment
        = Variable variableName AssignmentOperator assignmentOperator VariableValue variableValue ":" Type variableType; 

syntax TauConstruct = "TAU";

syntax InteractionInput =  ProcessName inputProcess  "?" Variable variableName;
