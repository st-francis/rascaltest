module PoC::Classifiers::ConditionClassifier

import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::Utils::ChoreographyUtil;
import PoC::Utils::ExpressionUtil;

import Set;
import IO;

bool everyProcessOccursInExpression(ChoreographyConstruct construct)
{
  set[str] uniqueProcessNames = findUniqueProcessNamesForChoreographyConstruct(construct);
  bool validConstructConditions = verifyConstructConditions(construct, uniqueProcessNames);
  
  if(!validConstructConditions)
  {
    println("NOt every process occurs in each expression!");
  }

  return validConstructConditions;
}

bool verifyConstructConditions(ChoreographyConstruct construct, set[str] uniqueProcessNames)
{
  bool containsAllProcessNames = true;

   switch(construct)
    {
      case (ChoreographyConstruct) `<ChoreographyConstruct firstConstruct>;<ChoreographyConstruct nextConstruct>`:
        containsAllProcessNames = verifyConstructConditions(firstConstruct, uniqueProcessNames) && verifyConstructConditions(nextConstruct, uniqueProcessNames);
      case (ChoreographyConstruct) `<ProcessName processName>.<Variable variableName><AssignmentOperator assignmentOperator><VariableValue variableValue>:<Type variableType>`:
        containsAllProcessNames = true;
      case (ChoreographyConstruct) `<ProcessVariableCall variableCallSen><ExchangeValueDeclaration variableDeclaration>-\><ProcessVariableCall variableCallRec>`:
        containsAllProcessNames = true;
      case (ChoreographyConstruct) `<ProcessName name><ExchangeValueDeclaration variableDeclaration>-\><ProcessVariableCall variableCallRec>`:
        containsAllProcessNames = true;
      case (ChoreographyConstruct) `if(<Expression expression>){<ChoreographyConstruct thenConstruct>}else{<ChoreographyConstruct elseConstruct>}`:
        containsAllProcessNames = size(uniqueProcessNames - findUniqueProcessNamesForExpression(expression)) == 0;
      case (ChoreographyConstruct) `while(<Expression expression>){<ChoreographyConstruct whileConstruct>}`:
        containsAllProcessNames = size(uniqueProcessNames - findUniqueProcessNamesForExpression(expression)) == 0;
      default: throw "no matching construct found!";
    }


  return containsAllProcessNames;
}
