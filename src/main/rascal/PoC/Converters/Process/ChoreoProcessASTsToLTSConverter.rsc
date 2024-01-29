module PoC::Converters::Process::ChoreoProcessASTsToLTSConverter

import PoC::Utils::ActionListUtil;
import PoC::Utils::LabelUtil;

import PoC::Converters::Process::ChoreoProcessDataTypes;
import PoC::Converters::Process::ChoreoProcessAssignmentConverter;
import PoC::Converters::Process::ChoreoProcessInteractionConverter;
import PoC::Converters::Process::ChoreoProcessIfStatementConverter;
import PoC::Converters::Process::ChoreoProcessWhileStatementConverter;

import PoC::ChoreoProcessLanguage::ChoreoProcessAbstract;

import PoC::ChoreoLanguage::ChoreoAbstract;

import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;

import PoC::Evaluators::ExpressionASTEvaluator;

import PoC::Machines::LabeledTransitionSystem;

import Set;
import List;
import String;
import IO;

int initialStateNo = 0;
int stateCounter;
set[ProcessTransitionContainer] containers = {};

LabeledTransitionSystem convertChoreoProcessASTsToLTS(str name, list[AChoreographyProcess] processes)
{
  containers = {};
  ProcessActionList initialActionList = ProcessActionList((process.name : process.processConstructs | AChoreographyProcess process <- processes), ());
  stateCounter = initialStateNo;
  buildProcessTransitionContainersForActionList(initialActionList);
  set[TransitionInfo] transitionInfo =  {container.transitionInfo | ProcessTransitionContainer container <- containers};
  return LabeledTransitionSystem(name, "0", transitionInfo);
}

void buildProcessTransitionContainersForActionList(ProcessActionList initialActionList)
{
  set[ProcessTransitionContainer] currentContainers = getContainersForActionList(initialActionList, initialStateNo);
  addContainers(currentContainers);

  bool allActionListsFinished = false;
  set[ProcessTransitionContainer] nextContainers = containers;
  while(!allActionListsFinished)
  {
    set[ProcessTransitionContainer] newNextContainers = {};
    for(ProcessTransitionContainer nextContainer <- nextContainers)
    {
      set[ProcessTransitionContainer] newStateContainers = getContainersForActionList(nextContainer.actionList, nextContainer.transitionInfo.nextStateNo);
      newNextContainers += addContainers(newStateContainers);
    }

    nextContainers = newNextContainers;
    allActionListsFinished = checkIfFinished(nextContainers);
  }

  addFinalTauTransitions();
}

set[ProcessTransitionContainer] getContainersForActionList(ProcessActionList actionList, int prevStateNo)
{
    set[ProcessTransitionContainer] newContainers = {};
    for(str processName <- actionList.processInfo)
    { 
      if(!isEmpty(actionList.processInfo[processName]))
      {
        AProcessConstruct firstProcessConstruct = getFirstFrom(actionList.processInfo[processName]);
        newContainer = getProcessTransitionContainerForProcessConstruct(processName, firstProcessConstruct, actionList, prevStateNo);
        
        if(!(newContainer is EmptyProcessTransitionContainer))
        {
          if (!containerWithMatchingInteractionInContainerSet(newContainers, newContainer)) 
          {
            newContainers += newContainer;
          }
        }
      }
    }

    return newContainers;
}

bool containerWithMatchingInteractionInContainerSet(set[ProcessTransitionContainer] containers, ProcessTransitionContainer containerToBeFound)
{
  for(ProcessTransitionContainer container <- containers)
  {
    if(containerMatchesInteraction(container, containerToBeFound))
    {
      return true;
    }
  }

  return false;
}

bool containerMatchesInteraction(ProcessTransitionContainer container1, ProcessTransitionContainer container2) {
    
    if(container1.transitionInfo.transitionType is AssignmentTransition 
    || container2.transitionInfo.transitionType is AssignmentTransition
    || container1.transitionInfo.transitionType is IfEvaluationTransition
    || container2.transitionInfo.transitionType is IfEvaluationTransition
    || container1.transitionInfo.transitionType is WhileEvaluationTransition
    || container2.transitionInfo.transitionType is WhileEvaluationTransition
    || container1.transitionInfo.transitionType is TauTransition
    || container2.transitionInfo.transitionType is TauTransition)
    {
      return false;
    }

    if(container1.transitionInfo.transitionType is IfEvaluationTransition &&
      container2.transitionInfo.transitionType is IfEvaluationTransition &&
      !container1.transitionInfo.transitionType is TauTransition &&
      !container2.transitionInfo.transitionType is TauTransition)
      {
        return true;
      }

    return 
        container1.transitionInfo.transitionType.sender == container2.transitionInfo.transitionType.sender &&
        container1.transitionInfo.transitionType.receiver == container2.transitionInfo.transitionType.receiver;
}

set[ProcessTransitionContainer] addContainers(set[ProcessTransitionContainer] newContainers)
{
  set[ProcessTransitionContainer] addedContainers = {};
  for(ProcessTransitionContainer cont <- newContainers)
  {
    set[ProcessTransitionContainer] toBeCheckedContainers = containers + addedContainers;;
    ProcessTransitionContainer newContainer = ProcessTransitionContainer(
      cont.actionList,
        TransitionInfo(
          cont.transitionInfo.prevStateNo,
          getStateCounterForProcesses(cont.actionList, true, toBeCheckedContainers),
          cont.transitionInfo.transitionLabel,
          cont.transitionInfo.transitionType
        )
    );
      addedContainers += newContainer;
  }

  containers += addedContainers; 
  return addedContainers;
}

bool checkIfFinished(set[ProcessTransitionContainer] remainingContainers)
{
  bool isTempFinished = true;
  for(ProcessTransitionContainer remainingContainer <- remainingContainers)
  {
    for(str processName <- remainingContainer.actionList.processInfo)
    {
      if(!isEmpty(remainingContainer.actionList.processInfo[processName]))
      {
        isTempFinished = false;
      }
    }
  }

  return isTempFinished;
}

void addFinalTauTransitions()
{
  for(ProcessTransitionContainer container <- containers)
  {
    bool isTerminating = isActionListEmpty(container.actionList);
    if(isTerminating)
    {
      containers += getTauContainer(ProcessActionList((), ()), container.transitionInfo.nextStateNo, container.transitionInfo.nextStateNo, true);
    }
  }
}

ProcessTransitionContainer getProcessTransitionContainerForProcessConstruct(str processName, AProcessConstruct processConstruct, ProcessActionList previousActionList, int prevStateNo)
{
  switch(processConstruct)
  {
    case AProcessInteractionInput(str _, str outputProcessName):
      return getProcessTransitionContainerForProcessInteraction(outputProcessName, processName, previousActionList, prevStateNo);
    case AProcessInteractionOutput(str _, AExchangeValueDeclaration _, str outputProcessName):
      return getProcessTransitionContainerForProcessInteraction(processName, outputProcessName, previousActionList, prevStateNo);
    case AProcessSequentialComposition(AProcessConstruct _, AProcessConstruct _):
      return getProcessTransitionContainerForProcessConstruct(processName, processConstruct.construct1, previousActionList, prevStateNo);
    case AProcessAssignment(str _, AExchangeValueDeclaration _, AAssignmentOperator _):
      return getProcessTransitionContainerForAssignment(processName, processConstruct, previousActionList, prevStateNo);
    case AProcessIfStatement(AExpression _, AProcessConstruct _, AProcessConstruct _):
      return getProcessTransitionContainerForIfStatement(previousActionList, prevStateNo);
    case AProcessWhileStatement(AExpression _, AProcessConstruct _):
      return getProcessTransitionContainerForWhileStatement(previousActionList, prevStateNo, containers);
    case ATauConstruct():
      return getContainerForTauConstruct(processName, previousActionList, prevStateNo);
    default: 
      throw "no matching process construct found!";
  }
}

map[str, map[str, AExchangeValueDeclaration]] updateVariableAssignment(ProcessActionList previousActionList, str processName, str variableName, AExchangeValueDeclaration exchangeValueDeclaration, AAssignmentOperator assignmentOperator)
{
  if(!(processName in previousActionList.varAssignments) || !(variableName in previousActionList.varAssignments[processName]))
  {
    if(!(processName in previousActionList.varAssignments))
    {
      previousActionList.varAssignments[processName] = ();
    }

    if(!(variableName in previousActionList.varAssignments[processName]))
    {
      previousActionList.varAssignments[processName][variableName] = AEmptyExchangeValueDeclaration();
    }
  }
  else
  {
    if(assignmentOperator is AAdditionOperator)
    {
      int previousValue = toInt(previousActionList.varAssignments[processName][variableName].val);
      int newValue = previousValue + toInt(exchangeValueDeclaration.val);
      exchangeValueDeclaration = AExchangeValueDeclaration("<newValue>", exchangeValueDeclaration.valType);
    }
  }

  previousActionList.varAssignments[processName][variableName] = exchangeValueDeclaration;
  return previousActionList.varAssignments;
}

ProcessTransitionContainer getContainerForTauConstruct(str processName, ProcessActionList previousActionList, int previousStateNo)
{
  ProcessActionList newActionList = EmptyActionList();  
  newActionList = previousActionList;
  newActionList.processInfo[processName] = getNextRequiredProcessConstructs(previousActionList.processInfo[processName]);

  return getTauContainer(newActionList, previousStateNo, getStateCounterForProcesses(EmptyActionList(), false, {}),false);
}

list[AProcessConstruct] getNextRequiredProcessConstructs(list[AProcessConstruct] requiredProcessConstructs)
{
  if(!(size(requiredProcessConstructs) > 0))
  {
    return [];
  }

  if(getFirstFrom(requiredProcessConstructs) is AProcessSequentialComposition)
  {
    return [getFirstFrom(requiredProcessConstructs).construct2];
  }else
  {
    return requiredProcessConstructs[1..];
  }
}

ProcessTransitionContainer getTauContainer(ProcessActionList actionList, int stateFrom, int stateTo, bool isFinal)
{
  Label tauLabel = isFinal ? getFinalTauLabel() : getTauLabel();

  return ProcessTransitionContainer(
      actionList,
      TransitionInfo(stateFrom, stateTo, tauLabel, TauTransition()));
}

int getStateCounterForProcesses(ProcessActionList newProcessActionList, bool updateStateCounter, set[ProcessTransitionContainer] toBeCheckedContainers)
{
  if(!updateStateCounter)
  {
    return stateCounter;
  }

  for(ProcessTransitionContainer container <- toBeCheckedContainers)
  {  
    bool allRemainingConstructsEqual = areActionListsEqual(container.actionList, newProcessActionList); 

    if(allRemainingConstructsEqual)
    {
      return container.transitionInfo.nextStateNo;
    }
  }
  
  stateCounter = stateCounter + 1;
  return stateCounter;
}