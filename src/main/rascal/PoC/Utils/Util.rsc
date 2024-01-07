module PoC::Utils::Util

import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::CommonLanguageElements::AssignmentOperator;

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

set[str] findUniqueProcessNamesForExpression(Expression expr)
{
  switch(expr)
  {
    case (Expression) `<Int intValue>`:
              return {};
    case (Expression) `<Bool boolValue>`:
              return {};
    case (Expression) `<ProcessVariableCall processVariableCall>`:
              return {"<processVariableCall.name>"};
    case (Expression) `<Expression expression1>==<Expression expression2>`:
              return findUniqueProcessNamesForExpression(expression1) + findUniqueProcessNamesForExpression(expression2);
    case (Expression) `<Expression expression1>!=<Expression expression2>`:
              return findUniqueProcessNamesForExpression(expression1) + findUniqueProcessNamesForExpression(expression2);
    case (Expression) `<Expression expression1>&&<Expression expression2>`:
              return findUniqueProcessNamesForExpression(expression1) + findUniqueProcessNamesForExpression(expression2);
    case (Expression) `<Expression expression1>||<Expression expression2>`:
              return findUniqueProcessNamesForExpression(expression1) + findUniqueProcessNamesForExpression(expression2);
    
    default: throw "no matching construct found!";
  }
}