module PoC::Converters::Choreography::ChoreoIfStatementConverter

import PoC::Machines::LabeledTransitionSystem;

import PoC::ChoreoLanguage::ChoreoAbstract;

import PoC::CommonLanguageElements::ExchangeValueAbstract;

import PoC::Utils::LabelUtil;

import PoC::Converters::Choreography::ChoreoASTToLTSConverter;
import PoC::Converters::Choreography::ChoreoConverterDataTypes;

import PoC::Evaluators::ExpressionASTEvaluator;

// Function returns the containers when an if-statement is encountered 
// INPUT  : @ifConstruct the construct for the if-statement
// INPUT  : @expression the expression for the if-statement
// INPUT  : @thenConstruct the construct that needs to be processed if the expression evaluates to true
// INPUT  : @elseConstruct the construct that needs to be processed if the expression evaluates to false
// INPUT  : @currentState the current state number
// INPUT  : @variableAssignments the current variableAssignments
// OUTPUT : The set of containers based on the if-statement
set[TransitionContainer] transitionContainerForIfStatement(AChoreographyConstruct ifConstruct, int currentState, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  bool evaluateThen = evaluateExpression(ifConstruct.expression, variableAssignments);
  AChoreographyConstruct remainingConstruct = AEmptyChoreographyConstruct();
  if(evaluateThen)
  {
    remainingConstruct = ifConstruct.thenConstruct;
  }
  else
  {
    remainingConstruct = ifConstruct.elseConstruct;
  }

  return {TransitionContainer(ifConstruct, 
                                      TransitionContainerExtraInfo(remainingConstruct, 
                                                                  TransitionInfo(
                                                                    currentState, 
                                                                    getStateCounter(AEmptyChoreographyConstruct(), false, variableAssignments),
                                                                    getIfStatementEvaluationLabel(evaluateThen),
                                                                    IfEvaluationTransition()),
                                                                  variableAssignments))};
}