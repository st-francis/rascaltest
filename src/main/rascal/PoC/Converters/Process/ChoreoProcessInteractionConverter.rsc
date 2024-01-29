module PoC::Converters::Process::ChoreoProcessInteractionConverter

import PoC::ChoreoProcessLanguage::ChoreoProcessAbstract;

import PoC::Converters::Process::ChoreoProcessDataTypes;
import PoC::Converters::Process::ChoreoProcessASTsToLTSConverter;

import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;

import PoC::Utils::LabelUtil;

import PoC::Machines::LabeledTransitionSystem;

import List;

ProcessTransitionContainer getProcessTransitionContainerForProcessInteraction(str sendingProcessName, str receivingProcessName, ProcessActionList previousActionList, int prevStateNo)
{
  if(size(previousActionList.processInfo[sendingProcessName]) == 0 || size(previousActionList.processInfo[receivingProcessName]) == 0)
  {
      return EmptyProcessTransitionContainer();
  }

  AProcessConstruct sendingConstruct = getFirsProcessConstructForPossibleComposition(previousActionList.processInfo[sendingProcessName][0]);
  AProcessConstruct receivingConstruct = getFirsProcessConstructForPossibleComposition(previousActionList.processInfo[receivingProcessName][0]);

  if(!(sendingConstruct is AProcessInteractionOutput) || !(receivingConstruct is AProcessInteractionInput))
  {
    return EmptyProcessTransitionContainer();
  }
  
  if(sendingConstruct is ATauConstruct || receivingConstruct is ATauConstruct)
  {
    return EmptyProcessTransitionContainer();
  }

  if(!(sendingProcessName == receivingConstruct.outputProcessName) || !(receivingProcessName == sendingConstruct.outputProcessName))
  {
    return EmptyProcessTransitionContainer();
  }
  
  str varTo   = receivingConstruct.varName;
  str varFrom = sendingConstruct.varName;
  AExchangeValueDeclaration exchangeValue = sendingConstruct.exchangeValue;

  map[str, map[str, AExchangeValueDeclaration]] varAssignments = updateVariableAssignment(previousActionList, receivingProcessName, varTo, exchangeValue, AEmptyAssignmentOperator());

  ProcessActionList updatedActionList = updateActionListForSenderAndReceiver(previousActionList, sendingProcessName, receivingProcessName); 
  updatedActionList.varAssignments = varAssignments;

  TransitionInfo transitionInfo = TransitionInfo(
                                      prevStateNo,
                                      getStateCounterForProcesses(EmptyActionList(),false, {}),
                                      getInteractionLabel(
                                        sendingProcessName,
                                        receivingProcessName,
                                        varFrom,
                                        varTo,
                                        exchangeValue
                                      ),
                                      InteractionTransition(sendingProcessName, receivingProcessName)
                                    );
  
  return ProcessTransitionContainer(updatedActionList, transitionInfo);
}

ProcessActionList updateActionListForSenderAndReceiver(ProcessActionList actionList, str sendingProcessName, str receivingProcessName)
{
  actionList.processInfo[sendingProcessName] = getNextRequiredProcessConstructs(actionList.processInfo[sendingProcessName]); 
  actionList.processInfo[receivingProcessName] = getNextRequiredProcessConstructs(actionList.processInfo[receivingProcessName]); 
  return actionList;
}

AProcessConstruct getFirsProcessConstructForPossibleComposition(AProcessConstruct construct)
{
  if(construct is AProcessSequentialComposition)
  {
    return construct.construct1;
  }
  return construct;
}