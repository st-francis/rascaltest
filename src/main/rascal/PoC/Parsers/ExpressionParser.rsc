module PoC::Parsers::ExpressionParser

import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;
import String;
import Boolean;


AExpression parseAbstractExpression(Expression expression)
{
  switch(expression)
  {
    case (Expression) `<Int intValue>`:
              return AIntExpression(toInt("<intValue>"));
    case (Expression) `<Bool boolValue>`:
              return ABoolExpression(fromString("<boolValue>"));
    case (Expression) `<ProcessVariableCall processVariableCall>`:
              return AProcessVariableDeclarationExpression(AProcess("<processVariableCall.name>", "<processVariableCall.variableName>"));
    case (Expression) `<Expression expression1>==<Expression expression2>`:
              return AEqualExpression(parseAbstractExpression(expression1), parseAbstractExpression(expression2));
    case (Expression) `<Expression expression1>&&<Expression expression2>`:
              return AExpressionConjunction(parseAbstractExpression(expression1), parseAbstractExpression(expression2));
    case (Expression) `<Expression expression1>!=<Expression expression2>`:
              return ANotEqualExpression(parseAbstractExpression(expression1), parseAbstractExpression(expression2));
    case (Expression) `<Expression expression1>||<Expression expression2>`:
              return AExpressionDisjunction(parseAbstractExpression(expression1), parseAbstractExpression(expression2));
    
    default: throw "no matching construct found!";
  }
}