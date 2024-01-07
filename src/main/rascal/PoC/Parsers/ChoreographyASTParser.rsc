module PoC::Parsers::ChoreographyASTParser

import IO;
import List;
import Set;
import String;
import Boolean;
import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;
import PoC::Parsers::ExpressionParser;
import PoC::Parsers::AssignmentOperatorParser;
import ParseTree;

AChoreography parseChoreographyToAST(ConcreteChoreography choreography)
{
  AChoreographyConstruct choreographyConstruct = parseChoreographyConstruct(choreography.content.choreographyConstruct); 
  return AChoreography("<choreography.name>", choreographyConstruct);
}

AChoreographyConstruct parseChoreographyConstruct(ChoreographyConstruct construct)
{
  switch(construct)
  {
    case (ChoreographyConstruct) `<ChoreographyConstruct firstConstruct>;<ChoreographyConstruct nextConstruct>`:
      return AChoreographyComposition(parseAbstractChoreographyConstruct(firstConstruct), parseAbstractChoreographyConstruct(nextConstruct));
    case (ChoreographyConstruct) `<ProcessVariableCall variableCallSen><ExchangeValueDeclaration variableDeclaration>-\><ProcessVariableCall variableCallRec>`:
      return AProcessInteraction(AProcess("<variableCallSen.name>", "<variableCallSen.variableName>"), AExchangeValueDeclaration("<variableDeclaration.variableValue>", "<variableDeclaration.variableType>"), AProcess("<variableCallRec.name>", "<variableCallRec.variableName>"));
    case (ChoreographyConstruct) `<ProcessName name><ExchangeValueDeclaration variableDeclaration>-\><ProcessVariableCall variableCallRec>`:
      return AProcessInteraction(AProcess("<name>", ""), AExchangeValueDeclaration("<variableDeclaration.variableValue>", "<variableDeclaration.variableType>"), AProcess("<variableCallRec.name>", "<variableCallRec.variableName>"));
    case (ChoreographyConstruct) `if(<Expression expression>){<ChoreographyConstruct thenConstruct>}else{<ChoreographyConstruct elseConstruct>}`:
      return AIfStatement(parseAbstractExpression(expression), parseAbstractChoreographyConstruct(thenConstruct), parseAbstractChoreographyConstruct(elseConstruct));
    case (ChoreographyConstruct) `while(<Expression expression>){<ChoreographyConstruct whileConstruct>}`:
      return AWhileStatement(parseAbstractExpression(expression), parseAbstractChoreographyConstruct(whileConstruct));
    case (ChoreographyConstruct) `<ProcessName processName>.<Variable variableName><AssignmentOperator assignmentOperator><VariableValue variableValue>:<Type variableType>`:
      return AVariableAssignment("<processName>", "<variableName>", AExchangeValueDeclaration("<variableValue>", "<variableType>"), parseAbstractAssignmentOperator(assignmentOperator));
    default: throw "no matching construct found!";
  }
}
