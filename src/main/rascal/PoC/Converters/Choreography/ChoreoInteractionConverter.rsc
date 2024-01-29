module PoC::Converters::Choreography::ChoreoInteractionConverter

import PoC::Machines::LabeledTransitionSystem;

import PoC::ChoreoLanguage::ChoreoAbstract;

import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;

import PoC::Utils::LabelUtil;

import PoC::Converters::Choreography::ChoreoASTToLTSConverter;
import PoC::Converters::Choreography::ChoreoConverterDataTypes;

// Function that returns the containers when an interaction construct is encountered
// INPUT  : @interaction - the interaction construct 
// INPUT  : @currentState - the current state from which the transition is departing
// OUTPUT : The set of containers as a result of the interaction
set[TransitionContainer] transitionContainerForInteraction(AChoreographyConstruct interaction, int currentState, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  map[str, map[str, AExchangeValueDeclaration]] newAssignments = updateVariableAssignment("<interaction.receivingProcess.name>","<interaction.receivingProcess.variableName>", interaction.exchangeValueDeclaration, variableAssignments, AEmptyAssignmentOperator());

  return {TransitionContainer(interaction, TransitionContainerExtraInfo(AEmptyChoreographyConstruct(), 
                                                                              TransitionInfo(
                                                                              currentState, 
                                                                              getStateCounter(AEmptyChoreographyConstruct(), false, newAssignments),
                                                                              getInteractionLabel(
                                                                                interaction.sendingProcess.name,
                                                                                interaction.receivingProcess.name,
                                                                                interaction.sendingProcess.variableName,
                                                                                interaction.receivingProcess.variableName,
                                                                                interaction.exchangeValueDeclaration
                                                                              ),
                                                                              InteractionTransition(interaction.sendingProcess.name, interaction.receivingProcess.name)),
                                                                              newAssignments))};
}