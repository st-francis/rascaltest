module PoC::Converters::Choreography::ChoreoAssignmentConverter

import PoC::Machines::AbstractStateMachine;

import PoC::ChoreoLanguage::ChoreoAbstract;

import PoC::CommonLanguageElements::ExchangeValueAbstract;

import PoC::Utils::LabelUtil;

import PoC::Converters::Choreography::ChoreoASTToTransitionInfoConverter;
import PoC::Converters::Choreography::ChoreoConverterDataTypes;

// Function that returns a container for the assignment of a variable
// INPUT  : @assignment - the construct that contains the assignment
// INPUT  : @currentState - state number from the state where the assignment is executed
// OUTPUT : The set of next containers after the assignment
set[TransitionContainer] transitionContainerForAssignment(AChoreographyConstruct assignment, int currentState, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  // update variable collection
  map[str, map[str, AExchangeValueDeclaration]] newAssignments = ();
  str processName = "<assignment.processName>";
  str variableName = "<assignment.variableName>";
  
  newAssignments = updateVariableAssignment(processName, variableName, assignment.exchangeValueDeclaration, variableAssignments, assignment.assignmentOperator);

  // return transition
  return {TransitionContainer(assignment, TransitionContainerExtraInfo(AEmptyChoreographyConstruct(), 
                                                                               TransitionInfo(
                                                                                currentState, 
                                                                                getStateCounter(AEmptyChoreographyConstruct(), false, newAssignments),
                                                                                getAssignmentLabel(
                                                                                  assignment.processName,
                                                                                  assignment.variableName,
                                                                                  assignment.exchangeValueDeclaration,
                                                                                  assignment.assignmentOperator
                                                                                ),
                                                                                AssignmentTransition()),
                                                                                newAssignments))};
}
