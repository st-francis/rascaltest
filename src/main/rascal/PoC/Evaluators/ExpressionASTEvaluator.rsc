module PoC::Evaluators::ExpressionASTEvaluator

import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;

import String;
import Boolean;


// Function that evaluates an expression and returns whether is true or false
// INPUT  : @expression - the expression that needs evaluation
// OUTPUT : The outcome of the expression
bool evaluateExpression(AExpression expression, map[str, map[str, AExchangeValueDeclaration]] varAssignments)
{
  bool result = false;
  switch(expression)
  {
    case AExpressionConjunction(AExpression expr1, AExpression expr2):
      result = evaluateExpression(expr1, varAssignments) && evaluateExpression(expr2, varAssignments);
    case AExpressionDisjunction(AExpression expr1, AExpression expr2):
      result =  evaluateExpression(expr1, varAssignments) || evaluateExpression(expr2, varAssignments);
    case AEqualExpression(AExpression val1, AExpression val2):
      result = getExpressionValue(val1, varAssignments) == getExpressionValue(val2, varAssignments);
    case ANotEqualExpression(AExpression val1, AExpression val2):
      result = getExpressionValue(val1, varAssignments) != getExpressionValue(val2, varAssignments);
  }
  return result;
}

// Function that returns an explicit value for an expression so it can be evaluated
// INPUT  : @expression the expression where the value needs to be retrieved from
// OUTPUT : The explicit expression value
AExpression getExpressionValue(AExpression expression, map[str, map[str, AExchangeValueDeclaration]] varAssignments)
{
  switch(expression)
  {
    case AIntExpression(int intValue):
      return expression;
    case ABoolExpression(bool boolValue):
      return expression;
    case AProcessVariableDeclarationExpression(AProcess process): 
      return getExpressionValueForProcessDeclaration(process, varAssignments);
  }
  
  return AEmptyExpression;
}

// Function that returns the explicit value for a process variabel declaration
// INPUT  : @processVariableDeclaration - the processVariableDeclaration where the variable needs to be fetched from
// OUTPUT : The explicit value that is stored in the declaration
AExpression getExpressionValueForProcessDeclaration(AProcess processVariableDeclaration, map[str, map[str, AExchangeValueDeclaration]] varAssignments)
{
  if(!(processVariableDeclaration.name in varAssignments))  {
    return AEmptyExpression();
  }

  AExchangeValueDeclaration valueDeclaration = varAssignments[processVariableDeclaration.name][processVariableDeclaration.variableName];
  switch(valueDeclaration.valType)
  {
    case "Int":
      return AIntExpression(toInt("<valueDeclaration.val>"));
    case "Bool":
      return ABoolExpression(fromString("<valueDeclaration.val>"));
  }

  return AEmptyExpression();
}
