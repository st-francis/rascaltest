module PoC::Converters::Process::ChoreoProcessAssignmentConverter

import PoC::ChoreoProcessLanguage::ChoreoProcessAbstract;

import PoC::Converters::Process::ChoreoProcessDataTypes;
import PoC::Converters::Process::ChoreoProcessASTsToFSMConverter;

import PoC::CommonLanguageElements::ExchangeValueAbstract;

import PoC::Utils::LabelUtil;

import PoC::Machines::FiniteStateMachine;


ProcessTransitionContainer getProcessTransitionContainerForAssignment(str processName, AProcessConstruct processConstruct, ProcessActionList previousActionList, int prevStateNo)
{
  map[str, map[str, AExchangeValueDeclaration]] varAssignments = ();
  varAssignments = updateVariableAssignment(previousActionList, "<processName>", "<processConstruct.variableName>", processConstruct.exchangeValue, processConstruct.assignmentOperator);
  
  previousActionList.processInfo[processName] = getNextRequiredProcessConstructs(previousActionList.processInfo[processName]);
  ProcessActionList updatedActionList = previousActionList;
  updatedActionList.varAssignments = varAssignments;
  
  TransitionInfo transitionInfo = TransitionInfo(
      prevStateNo,
      getStateCounterForProcesses(EmptyActionList(), false, {}),
      getAssignmentLabel(
        processName,
        processConstruct.variableName,
        processConstruct.exchangeValue,
        processConstruct.assignmentOperator
      ),
      AssignmentTransition()
      );

  return  ProcessTransitionContainer(updatedActionList, transitionInfo);
}