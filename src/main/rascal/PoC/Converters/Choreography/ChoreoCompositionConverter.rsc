module PoC::Converters::Choreography::ChoreoCompositionConverter

import PoC::Machines::FiniteStateMachine;

import PoC::ChoreoLanguage::ChoreoAbstract;

import PoC::CommonLanguageElements::ExchangeValueAbstract;

import PoC::Utils::LabelUtil;
import PoC::Utils::ChoreographyUtil;

import PoC::Converters::Choreography::ChoreoASTToTransitionInfoConverter;
import PoC::Converters::Choreography::ChoreoConverterDataTypes;

import PoC::Evaluators::ExpressionASTEvaluator;

// Function that returns the process containers for a composition construct 
// It returns a transition to the first construct of the composition
// In addition it returns containers for constructs that have no overlapping names with the first construct of the composition
// INPUT  : @composition - the composition construct
// INPUT  : @currentState - the current state from which the composition is encountered 
// OUTPUT : A set of interaction containers as a result of the composition
set[TransitionContainer] transitionContainerForComposition(AChoreographyConstruct composition, int currentState, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  AChoreographyConstruct toBeAddedToFirstConstruct = composition.secondConstruct;

  // construct 1 check
  if(composition.firstConstruct is AWhileStatement)
  {
    bool isWhileEntered = evaluateExpression(composition.firstConstruct.expression, variableAssignments);

    if(isWhileEntered)
    {
      toBeAddedToFirstConstruct = AChoreographyComposition(composition.firstConstruct, composition.secondConstruct);
    }
  }

  // (1) Getting set1
  set[TransitionContainer] set1 = { TransitionContainer(interaction.construct,
                                            TransitionContainerExtraInfo(
                                              composeChorConstructs(interaction.extraInfo.requiredChor, toBeAddedToFirstConstruct),
                                              TransitionInfo(
                                                currentState, 
                                                getStateCounter(AEmptyChoreographyConstruct(), false, interaction.extraInfo.variableAssignments), 
                                                interaction.extraInfo.transitionInfo.transitionLabel,
                                                interaction.extraInfo.transitionInfo.transitionType
                                              ),
                                              interaction.extraInfo.variableAssignments
                                            ))
                                            | TransitionContainer interaction <- getStateProcessInteractions(composition.firstConstruct, currentState, variableAssignments, true, toBeAddedToFirstConstruct)};


  // (2) Getting set2
  set[TransitionContainer] set2 = { TransitionContainer(interaction.construct, 
                                            TransitionContainerExtraInfo(
                                              composeChorConstructs(composition.firstConstruct, 
                                              interaction.extraInfo.requiredChor), 
                                              TransitionInfo(
                                                currentState, 
                                                getStateCounter(AEmptyChoreographyConstruct(), false, interaction.extraInfo.variableAssignments), 
                                                interaction.extraInfo.transitionInfo.transitionLabel,
                                                interaction.extraInfo.transitionInfo.transitionType
                                                ),
                                                interaction.extraInfo.variableAssignments)
                                            ) 
                                          | TransitionContainer interaction <- getStateProcessInteractions(composition.secondConstruct, currentState, variableAssignments, true, composition.secondConstruct)
                                          , !hasOverlappingProcessNames(tryGetFirstChoreographyConstruct(set1), interaction.construct)};

  // (3) Unifying the two sets
  set1 += set2;

  // (4) Returning the sets
  return set1;
}