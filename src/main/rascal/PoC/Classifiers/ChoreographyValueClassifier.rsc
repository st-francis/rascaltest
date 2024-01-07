module PoC::Classifiers::ChoreographyValueClassifier 

import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;
import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;

import String;
import Boolean;
import Exception;
import IO;

bool classifyChoreographyConstructValues(AChoreography choreography)
{
  bool validValues = classifyChoreographyConstruct(choreography.choreographyConstruct);

  return validValues;
}

bool classifyChoreographyConstruct(AChoreographyConstruct construct) 
{
  bool validValue = true; 

  switch(construct)
  {
    case AChoreographyComposition(AChoreographyConstruct firstConstruct, AChoreographyConstruct secondConstruct):
      return classifyChoreographyConstruct(firstConstruct) && classifyChoreographyConstruct(secondConstruct);
    case AProcessInteraction(AProcess sendingProcess, AExchangeValueDeclaration exchangeValueDeclaration, AProcess receivingProcess):
      return classifyValue(exchangeValueDeclaration);
    case AVariableAssignment(str processName, str variableName, AExchangeValueDeclaration exchangeValueDeclaration, AAssignmentOperator assignmentOperator):
      return classifyValue(exchangeValueDeclaration);
    case AIfStatement(AExpression expression, AChoreographyConstruct thenConstruct, AChoreographyConstruct elseConstruct):
      return true;
    case AWhileStatement(AExpression expression, AChoreographyConstruct whileConstruct):
      return true;
    case AEmptyChoreographyConstruct():
      return true;
    default: throw "No matching choreography construct found!";
  }
}

bool classifyValue(AExchangeValueDeclaration valueDeclaration)
{
  bool hasValidType = false;

  switch(valueDeclaration.valType)
  {
    case "Int":
      hasValidType = isValidInt(valueDeclaration.val);
    case "Bool":
      hasValidType = isValidBool(valueDeclaration.val);
  }

  return hasValidType;
}

bool isValidInt(str s) {
    bool valid = true;
    
    try
      int v = toInt(s);
    catch:
      valid = false;
    
    if(!valid)
    {
      println("Value <s> is not an int value!");
    }

    return valid;
}

bool isValidBool(str s) {
    bool valid = true;
    
    try 
        bool v = fromString(s);
    catch:
        valid = false;
    
    if(!valid)
    {
      println("Value <s> is not a bool value!");
    }

    return valid;
}