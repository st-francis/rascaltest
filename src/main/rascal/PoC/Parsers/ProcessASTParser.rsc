module PoC::Parsers::ProcessASTParser

import PoC::ChoreoProcessLanguage::ChoreoProcessAbstract;
import PoC::ChoreoProcessLanguage::ChoreoProcessConcrete;

import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::ChoreoLanguage::ChoreoConcrete;

import PoC::Parsers::ExpressionParser;
import PoC::Parsers::AssignmentOperatorParser;

import PoC::CommonLanguageElements::ExchangeValueAbstract;


import IO;
import List;
import Set;

AChoreographyProcess parseChoreographyProcess(ChoreographyProcess process)
{
  list[AProcessConstruct] processConstructs = [];
  processConstructs = [parseProcessConstruct(construct) | ProcessConstruct construct <- process.content.processConstructs];

  return choreographyProcess("<process.processName>", processConstructs);
}

AProcessConstruct parseProcessConstruct(ProcessConstruct construct)
{
  switch(construct)
  {
    case (ProcessConstruct)`<ProcessName outputProcess>!<Variable variableName>(<VariableValue variableValue>:<Type variableType>)`:
        return AProcessInteractionOutput("<variableName>", AExchangeValueDeclaration("<variableValue>", "<variableType>"), "<outputProcess>");
    case (ProcessConstruct)`<ProcessName outputProcess>!(<VariableValue variableValue>:<Type variableType>)`:
        return AProcessInteractionOutput("", AExchangeValueDeclaration("<variableValue>", "<variableType>"), "<outputProcess>");
    case (ProcessConstruct)`<ProcessName inputProcess>?<Variable variableName>`:
        return AProcessInteractionInput("<variableName>", "<inputProcess>");
    case (ProcessConstruct)`<Variable variableName><AssignmentOperator assignmentOperator><VariableValue variableValue>:<Type variableType>`:
        return AProcessAssignment("<variableName>", AExchangeValueDeclaration("<variableValue>","<variableType>"), parseAbstractAssignmentOperator(assignmentOperator));
    case (ProcessConstruct)`TAU`:
        return ATauConstruct();
    case (ProcessConstruct) `if(<Expression expression>){<ProcessConstruct thenConstruct>}else{<ProcessConstruct elseConstruct>}`:
        return AProcessIfStatement(parseAbstractExpression(expression), parseProcessConstruct(thenConstruct), parseProcessConstruct(elseConstruct));
    case (ProcessConstruct) `while(<Expression expression>){<ProcessConstruct whileConstruct>}`:
        return AProcessWhileStatement(parseAbstractExpression(expression), parseProcessConstruct(whileConstruct));
    case (ProcessConstruct)`<ProcessConstruct firstConstruct>;<ProcessConstruct nextConstruct>`:
        return AProcessSequentialComposition(parseProcessConstruct(firstConstruct), parseProcessConstruct(nextConstruct));
    default: throw "Unsupported processInteraction <construct>";
  }
}