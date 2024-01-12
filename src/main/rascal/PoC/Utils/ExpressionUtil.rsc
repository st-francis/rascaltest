module PoC::Utils::ExpressionUtil

import PoC::ChoreoLanguage::ChoreoConcrete;

import PoC::Utils::ChoreographyUtil;

import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;


// Function that returnst the name that may exist in an expression
// INPUT  : @expression the expression where the value needs to be retrieved from
// OUTPUT : A set of names that occur in the expression
set[str] getExpressionName(AExpression expression)
{
  switch(expression)
  {
    case AIntExpression(int _):
      return {};
    case ABoolExpression(bool _):
      return {};
    case AProcessVariableDeclarationExpression(AProcess process): 
      return {process.name};
  }
  
  return {};
}

// Function that evaluates an expression and returns all the process names
// INPUT  : @expression - the expression that needs evaluation
// OUTPUT : The names in the expression
set[str] getExpressionNames(AExpression expression)
{
  switch(expression)
  {
    case AExpressionConjunction(AExpression expr1, AExpression expr2):
      return getExpressionNames(expr1) + getExpressionNames(expr2);
    case AExpressionDisjunction(AExpression expr1, AExpression expr2):
      return getExpressionNames(expr1) + getExpressionNames(expr2);
    case AEqualExpression(AExpression val1, AExpression val2):
      return getExpressionName(val1) + getExpressionName(val2);
    case ANotEqualExpression(AExpression val1, AExpression val2):
      return getExpressionName(val1) + getExpressionName(val2);
  }

  return {};
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
