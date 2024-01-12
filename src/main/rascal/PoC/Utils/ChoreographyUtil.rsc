module PoC::Utils::ChoreographyUtil

import PoC::Utils::ExpressionUtil;

import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::CommonLanguageElements::AssignmentOperator;
import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;

set[str] findUniqueProcessNamesForChoreographyConstruct(ChoreographyConstruct choreographyConstruct)
{
    switch(choreographyConstruct)
    {
      case (ChoreographyConstruct) `<ChoreographyConstruct firstConstruct>;<ChoreographyConstruct nextConstruct>`:
        return findUniqueProcessNamesForChoreographyConstruct(firstConstruct) + findUniqueProcessNamesForChoreographyConstruct(nextConstruct);
      case (ChoreographyConstruct) `<ProcessName processName>.<Variable variableName><AssignmentOperator assignmentOperator><VariableValue variableValue>:<Type variableType>`:
        return {"<processName>"};
      case (ChoreographyConstruct) `<ProcessVariableCall variableCallSen><ExchangeValueDeclaration variableDeclaration>-\><ProcessVariableCall variableCallRec>`:
        return {"<variableCallSen.name>", "<variableCallRec.name>"};
      case (ChoreographyConstruct) `<ProcessName name><ExchangeValueDeclaration variableDeclaration>-\><ProcessVariableCall variableCallRec>`:
        return {"<name>", "<variableCallRec.name>"};
      case (ChoreographyConstruct) `if(<Expression expression>){<ChoreographyConstruct thenConstruct>}else{<ChoreographyConstruct elseConstruct>}`:
        return findUniqueProcessNamesForExpression(expression) + findUniqueProcessNamesForChoreographyConstruct(thenConstruct) + findUniqueProcessNamesForChoreographyConstruct(elseConstruct);
      case (ChoreographyConstruct) `while(<Expression expression>){<ChoreographyConstruct whileConstruct>}`:
        return findUniqueProcessNamesForExpression(expression) + findUniqueProcessNamesForChoreographyConstruct(whileConstruct);
      default: throw "no matching construct found!";
    }
}

// Function that returns the names for a given construct
// INPUT  : @construct - the construct where the names need to be determined for
// OUTPUT : A set of process names that occur in the construct
set[str] findUniqueProcessNamesForAChoreographyConstruct(AChoreographyConstruct construct)
{
  switch(construct)
  {
    case AIfStatement(AExpression expression, AChoreographyConstruct _, AChoreographyConstruct _):
      return getExpressionNames(expression);
    case AWhileStatement(AExpression expression, AChoreographyConstruct _):
      return getExpressionNames(expression);
    case AProcessInteraction(AProcess sendingProcess, AExchangeValueDeclaration _, AProcess receivingProcess):
      return {sendingProcess.name, receivingProcess.name};
    case AVariableAssignment(str processName, str _, AExchangeValueDeclaration _, AAssignmentOperator _):
      return {processName};
    case AEmptyChoreographyConstruct():
      return {};
    default: throw "No matching choreography construct found!";
  }
}

// Function that indicates whether a construct is an terminating one
// INPUT  : @chorConstruct - the construct that needs to be checked
// OUTPUT : A flag indicating if the construct is terminating
bool isTerminatingChorConstruct(AChoreographyConstruct chorConstruct)
{
  switch(chorConstruct)
  {
    case AProcessInteraction(AProcess _, AExchangeValueDeclaration _, AProcess _):
      return false;
    case AChoreographyComposition(AChoreographyConstruct _, AChoreographyConstruct _):
      return false;
    case AVariableAssignment(str _, str _, AExchangeValueDeclaration _, AAssignmentOperator _):
      return false;
    case AIfStatement(AExpression _, AChoreographyConstruct _, AChoreographyConstruct _):
      return false;
    case AWhileStatement(AExpression _, AChoreographyConstruct _):
      return false; 
    case AEmptyChoreographyConstruct():
      return true;
    default: throw "The chor construct is not recognized!: <chorConstruct>";
  }
}