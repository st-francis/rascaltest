module PoC::Converters::Choreography::ChoreoWhileStatementConverter

import PoC::Machines::AbstractStateMachine;

import PoC::ChoreoLanguage::ChoreoAbstract;

import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;

import PoC::Utils::LabelUtil;

import PoC::Converters::Choreography::ChoreoASTToTransitionInfoConverter;
import PoC::Converters::Choreography::ChoreoConverterDataTypes;

import PoC::Evaluators::ExpressionASTEvaluator;

// Function returns the containers when an while-statement is encountered 
// INPUT  : @baseConstruct the construct for the while-statement
// INPUT  : @currentState the current state number
// INPUT  : @variableAssignments the current variableAssignments
// OUTPUT : The set of containers based on the while-statement
set[TransitionContainer] transitionContainerForWhileStatement(AChoreographyConstruct baseConstruct, int currentState, map[str, map[str, AExchangeValueDeclaration]] variableAssignments, bool partOfComposition, AChoreographyConstruct baseConstructWithAdditionalConstructs)
{
  bool enterWhile = evaluateExpression(baseConstruct.expression, variableAssignments);

  AChoreographyConstruct remainingConstruct = AEmptyChoreographyConstruct();
  if(enterWhile)
  {
      remainingConstruct = (partOfComposition) ? baseConstruct.whileConstruct : AChoreographyComposition(baseConstruct.whileConstruct, baseConstruct);

      AChoreographyConstruct constructToBeChecked = remainingConstruct;
      if(!(baseConstructWithAdditionalConstructs is AEmptyChoreographyConstruct))
      {
        constructToBeChecked = AChoreographyComposition(remainingConstruct, baseConstructWithAdditionalConstructs);
      }
      
      bool whileContentMakesAnyDifference = doesWhileContentMakeAnyDifference(baseConstruct.whileConstruct, variableAssignments);
      bool equivalentStateAlreadyExists = equivalentStateExists(constructToBeChecked, variableAssignments);
      if(!whileContentMakesAnyDifference && equivalentStateAlreadyExists)
      {
        return {};
      }
  }

  return {TransitionContainer(baseConstruct, 
                                  TransitionContainerExtraInfo(remainingConstruct, 
                                                              TransitionInfo(
                                                                currentState, 
                                                                getStateCounter(AEmptyChoreographyConstruct(), false, variableAssignments),
                                                                getWhileStatementEvaluationLabel(enterWhile),
                                                                WhileEvaluationTransition()),
                                                              variableAssignments))};
}

bool doesWhileContentMakeAnyDifference(AChoreographyConstruct whileConstruct, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  map[str, map[str, AExchangeValueDeclaration]] tempVars = getVariableAssignmentsForWhileConstructContent(whileConstruct, variableAssignments);
  
  bool hasDifference = false; 
  for(str processName <- tempVars)
  {
    for(str varName <- tempVars[processName])
    {
      if(!(processName in variableAssignments) || !(varName in variableAssignments[processName]) || variableAssignments[processName][varName] != tempVars[processName][varName])
      {
        hasDifference = true;
      }
    }
  }

  return hasDifference;
}

map[str, map[str, AExchangeValueDeclaration]] getVariableUpdatesForWhileStatement(AExpression expression, AChoreographyConstruct whileConstruct, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
    bool evaluationRes = evaluateExpression(expression, variableAssignments);
    if(evaluationRes)
    {
      return getVariableAssignmentsForWhileConstructContent(whileConstruct, variableAssignments);
    }
    else
    {
      return ();
    }
}

map[str, map[str, AExchangeValueDeclaration]] getVariableAssignmentsForWhileConstructContent(AChoreographyConstruct content, map[str, map[str, AExchangeValueDeclaration]] variableAssignments )
{
  map[str, map[str, AExchangeValueDeclaration]] tempVariableAssignments = ();
  switch(content)
  {
     case AChoreographyComposition(AChoreographyConstruct firstConstruct, AChoreographyConstruct secondConstruct):
      tempVariableAssignments += getVariableAssignmentsForWhileConstructContent(firstConstruct,  variableAssignments) + getVariableAssignmentsForWhileConstructContent(secondConstruct, variableAssignments);
    case AProcessInteraction(AProcess _, AExchangeValueDeclaration exchangeValueDeclaration, AProcess receivingProcess):
      tempVariableAssignments += updateVariableAssignment(receivingProcess.name, receivingProcess.variableName, exchangeValueDeclaration, variableAssignments, AEmptyAssignmentOperator());
    case AVariableAssignment(str processName, str variableName, AExchangeValueDeclaration exchangeValueDeclaration, AAssignmentOperator assignmentOperator):
      tempVariableAssignments += updateVariableAssignment(processName, variableName, exchangeValueDeclaration, variableAssignments, assignmentOperator);
    case AIfStatement(AExpression expression, AChoreographyConstruct thenConstruct, AChoreographyConstruct elseConstruct):
      tempVariableAssignments += getVariableUpdatesForIfStatement(expression, thenConstruct, elseConstruct, variableAssignments);
    case AWhileStatement(AExpression expression, AChoreographyConstruct whileConstruct):
      tempVariableAssignments += getVariableUpdatesForWhileStatement(expression, whileConstruct, variableAssignments);
    case AEmptyChoreographyConstruct():
      tempVariableAssignments += ();
  }

  return tempVariableAssignments;
}

map[str, map[str, AExchangeValueDeclaration]] getVariableUpdatesForIfStatement(AExpression expression, AChoreographyConstruct thenConstruct, AChoreographyConstruct elseConstruct, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  bool evaluationRes = evaluateExpression(expression, variableAssignments);
  if(evaluationRes)
  {
    return getVariableAssignmentsForWhileConstructContent(thenConstruct, variableAssignments);
  }
  else
  {
    return getVariableAssignmentsForWhileConstructContent(elseConstruct, variableAssignments);
  }
}