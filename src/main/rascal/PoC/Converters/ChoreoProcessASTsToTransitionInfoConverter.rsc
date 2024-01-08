module PoC::Converters::ChoreoProcessASTsToTransitionInfoConverter

import PoC::ChoreoProcessLanguage::ChoreoProcessAbstract;
import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::Converters::ChoreoASTToTransitionInfoConverter;
import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;
import PoC::Evaluators::ExpressionASTEvaluator;

import Map;
import Set;
import List;
import String;
import IO;

data ProcessTransitionContainer   = ProcessTransitionContainer(ProcessActionList actionList, TransitionInfo transitionInfo) | EmptyProcessTransitionContainer();
data ProcessActionList  = ProcessActionList(map[str processName, list[AProcessConstruct] requiredProcessConstructs] processInfo, map[str, map[str, AExchangeValueDeclaration]] varAssignments) | EmptyActionList();

int initialStateNo = 0;
int stateCounter;
set[ProcessTransitionContainer] containers = {};

set[TransitionInfo] convertChoreoProcessASTsToTransitionInfo(list[AChoreographyProcess] processes)
{
  containers = {};
  ProcessActionList initialActionList = ProcessActionList((process.name : process.processConstructs | AChoreographyProcess process <- processes), ());
  stateCounter = initialStateNo;
  BuildProcessTransitionContainersForActionList(initialActionList);
  return {container.transitionInfo | ProcessTransitionContainer container <- containers};
}

void BuildProcessTransitionContainersForActionList(ProcessActionList initialActionList)
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
    
    if(container1.transitionInfo.transitionLabelInfo is AssignmentTransitionLabelInfo 
    || container2.transitionInfo.transitionLabelInfo is AssignmentTransitionLabelInfo
    || container1.transitionInfo.transitionLabelInfo is IfThenElseDecisionLabelInfo
    || container2.transitionInfo.transitionLabelInfo is IfThenElseDecisionLabelInfo
    || container1.transitionInfo.transitionLabelInfo is WhileDecisionLabelInfo
    || container2.transitionInfo.transitionLabelInfo is WhileDecisionLabelInfo)
    {
      return false;
    }

    if(container1.transitionInfo.transitionLabelInfo is IfThenElseDecisionLabelInfo &&
      container2.transitionInfo.transitionLabelInfo is IfThenElseDecisionLabelInfo &&
      !container1.transitionInfo.isTau &&
      !container2.transitionInfo.isTau)
      {
        return true;
      }

    return container1.transitionInfo.transitionLabelInfo.sender == container2.transitionInfo.transitionLabelInfo.sender &&
        container1.transitionInfo.transitionLabelInfo.receiver == container2.transitionInfo.transitionLabelInfo.receiver &&
        !container2.transitionInfo.isTau;
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
          cont.transitionInfo.isTau,
          cont.transitionInfo.transitionLabelInfo
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
    bool isTerminating = isTerminatingContainer(container.actionList);
    if(isTerminating)
    {
      containers += getTauContainer(ProcessActionList((), ()), container.transitionInfo.nextStateNo, container.transitionInfo.nextStateNo);
    }
  }
}

ProcessTransitionContainer getProcessTransitionContainerForProcessConstruct(str processName, AProcessConstruct processConstruct, ProcessActionList previousActionList, int prevStateNo)
{
  switch(processConstruct)
  {
    case AProcessInteractionInput(str varName, str outputProcessName):
      return getProcessTransitionContainerForProcessInteraction(outputProcessName, processName, processConstruct, previousActionList, prevStateNo);
    case AProcessInteractionOutput(str varName, AExchangeValueDeclaration exchangeValue, str outputProcessName):
      return getProcessTransitionContainerForProcessInteraction(processName, outputProcessName, processConstruct, previousActionList, prevStateNo);
    case AProcessSequentialComposition(AProcessConstruct construct1, AProcessConstruct construct2):
      return getProcessTransitionContainerForProcessConstruct(processName, processConstruct.construct1, previousActionList, prevStateNo);
    case AProcessAssignment(str variableName, AExchangeValueDeclaration exchangeValue, AAssignmentOperator assignmentOperator):
      return getProcessTransitionContainerForAssignment(processName, variableName, exchangeValue, assignmentOperator, previousActionList, prevStateNo);
    case AProcessIfStatement(AExpression expression, AProcessConstruct thenConstruct, AProcessConstruct elseConstruct):
      return getProcessTransitionContainerForIfStatement(previousActionList, prevStateNo);
    case AProcessWhileStatement(AExpression expression, AProcessConstruct whileConstruct):
      return getProcessTransitionContainerForWhileStatement(previousActionList, prevStateNo);
    case ATauConstruct():
      return getContainerForTauConstruct(processName, previousActionList, prevStateNo);
    default: 
      throw "no matching process construct found!";
  }
}

bool allNextProcessInfoElementsAreIf(map[str processName, list[AProcessConstruct] requiredProcessConstructs] processInfo)
{
  for(str name <- processInfo)
  {
    AProcessConstruct construct = processInfo[name][0];
    if(!(construct is AProcessIfStatement) && !((construct is AProcessSequentialComposition) && construct.construct1 is AProcessIfStatement))
    {
      return false;
    }
  }
  return true;
}

bool allNextProcessInfoElementsAreWhile(map[str processName, list[AProcessConstruct] requiredProcessConstructs] processInfo)
{
  for(str name <- processInfo)
  {
    AProcessConstruct construct = processInfo[name][0];
    if(!(construct is AProcessWhileStatement) && !((construct is AProcessSequentialComposition) && construct.construct1 is AProcessWhileStatement))
    {
      return false;
    }
  }
  return true;
}

set[bool] evaluateAllExpressions(ProcessActionList actionList)
 {
    set[bool] evaluationResults = {};
    for (str name <- actionList.processInfo) {
      AProcessConstruct construct = actionList.processInfo[name][0];

      if (construct is AProcessIfStatement || construct is AProcessWhileStatement) 
      {
        evaluationResults += evaluateExpression(construct.expression, actionList.varAssignments);
      } 
      else 
      {
        evaluationResults += evaluateExpression(construct.construct1.expression, actionList.varAssignments);
      }
    }
    return evaluationResults;
 }

map[str, tuple[AProcessConstruct, AProcessConstruct]] createThenElseConstructs(map[str processName, list[AProcessConstruct] requiredProcessConstructs] processInfo)
{
    map[str, tuple[AProcessConstruct, AProcessConstruct]] thenElseConstructs = ();
    for(str name <- processInfo)
    {
      AProcessConstruct construct = processInfo[name][0]; 
      if(construct is AProcessIfStatement)
      {
        thenElseConstructs[name] = <construct.thenConstruct, construct.elseConstruct>;
      }
      else if((construct is AProcessSequentialComposition) && construct.construct1 is AProcessIfStatement)
      {
          thenElseConstructs[name] = <construct.construct1.thenConstruct, construct.construct1.elseConstruct>;
      }
    }
    return thenElseConstructs;
}

map[str, AProcessConstruct] createWhileConstructs(map[str processName, list[AProcessConstruct] requiredProcessConstructs] processInfo)
{
    map[str, AProcessConstruct] whileConstructs = ();
    for(str name <- processInfo)
    {
      AProcessConstruct construct = processInfo[name][0]; 
      if(construct is AProcessWhileStatement)
      {
        whileConstructs[name] = construct.whileConstruct;
      }
      else if((construct is AProcessSequentialComposition) && construct.construct1 is AProcessWhileStatement)
      {
          whileConstructs[name] = construct.construct1.whileConstruct;
      }
    }
    return whileConstructs;
}

ProcessTransitionContainer getProcessTransitionContainerForWhileStatement(ProcessActionList previousActionList, int prevStateNo)
{
  // STEP 1: Check if all next processInfo elements are a WhileProcessConstruct or a composition with a WhileConstruct as its first element
  if(!allNextProcessInfoElementsAreWhile(previousActionList.processInfo))
  {
    return EmptyProcessTransitionContainer();
  }

  // STEP 2: Evaluate all values and check if they all evaluate to the same value
  set[bool] evaluationResults = evaluateAllExpressions(previousActionList);
  if(!(size(evaluationResults) == 1))
  {
    println("The while could not be projected!");
     return EmptyProcessTransitionContainer();
  }

  // STEP 3: Create a map for whileConstructs and update the procesInfo to the next processConstruct
  map[str, AProcessConstruct] whileConstructs = createWhileConstructs(previousActionList.processInfo);
  map[str, AProcessConstruct] whileStatements = ();
  for(str name <- previousActionList.processInfo)
  {
    whileStatements[name] = previousActionList.processInfo[name][0];  
  }

  for(str name <- previousActionList.processInfo)
  {
    previousActionList.processInfo[name] = getNextRequiredProcessConstructs(previousActionList.processInfo[name]);
  }

  // STEP 4: Update processInfo based on the evaluation results
  for (str name <- previousActionList.processInfo) {
    if (getFirstFrom(evaluationResults)) 
    {
      // bool hasDifferences = doesWhileContentMakeAnyDifference(whileStatements , previousActionList, prevStateNo);
      // bool equivalentStateAlreadyExists = equivalentProcessesStateExists(previousActionList, containers);
      // if(!hasDifferences && equivalentStateAlreadyExists)
      // {
      //   return EmptyProcessTransitionContainer();
      // }

      AProcessConstruct first = AEmptyProcessConstruct();
      AProcessConstruct second = AEmptyProcessConstruct();
      if(whileConstructs[name] is AProcessSequentialComposition)
      {
          first = whileConstructs[name].construct1;
          second = recursivelyBuildProcessConstructForWhileStatements(name, whileConstructs[name].construct2, whileStatements);
      }else
      {
        first = whileConstructs[name];
        second = whileStatements[name];
      }

      AProcessConstruct nextConstruct = size(previousActionList.processInfo[name]) == 0 ?  AProcessSequentialComposition(first, second) : AProcessSequentialComposition(first, second);
      previousActionList.processInfo[name] = [nextConstruct];
    }
    else 
    {
      list[AProcessConstruct] nextConstructs = size(previousActionList.processInfo[name]) == 0 ? [] :  previousActionList.processInfo[name];
      previousActionList.processInfo[name] = nextConstructs;
    }
  }

  bool hasDifferences = doesWhileContentMakeAnyDifference(whileStatements , previousActionList, prevStateNo);
  bool equivalentStateAlreadyExists = equivalentProcessesStateExists(previousActionList, containers);
  if(!hasDifferences && equivalentStateAlreadyExists)
  {
    return EmptyProcessTransitionContainer();
  }

  // STEP 5: return the process container where all the process have evaluated the if-statement
  TransitionInfo transitionInfo = TransitionInfo(
                                      prevStateNo,
                                      getStateCounterForProcesses(EmptyActionList(),false, {}),
                                      false,
                                      WhileDecisionLabelInfo(getFirstFrom(evaluationResults))
                                    );


    return ProcessTransitionContainer(previousActionList, transitionInfo);
}

bool equivalentProcessesStateExists(ProcessActionList processActionList, set[ProcessTransitionContainer] toBeCheckedContainers)
{
  for(ProcessTransitionContainer container <- toBeCheckedContainers)
  {  
    bool allRemainingConstructsEqual = areAllRemainingConstructsEqual(container.actionList, processActionList); 

    if(allRemainingConstructsEqual)
    {
      return true;
    }
  }
  return false;
}

AProcessConstruct recursivelyBuildProcessConstructForWhileStatements(str processName, AProcessConstruct construct, map[str, AProcessConstruct] whileStatements)
{
  if(construct is AProcessSequentialComposition)
  {
    return  AProcessSequentialComposition(construct.construct1, recursivelyBuildProcessConstructForWhileStatements(processName, construct.construct2, whileStatements));
  }
  else
  {
    return  AProcessSequentialComposition(construct, whileStatements[processName]);
  }
}

bool doesWhileContentMakeAnyDifference(map[str, AProcessConstruct] whileConstructs, ProcessActionList previousActionList, int prevStateNo)
{
  ProcessActionList copy = previousActionList;
  bool hasDifference = false;
  for(str processName <- whileConstructs)
  { 
    AProcessConstruct construct = AEmptyProcessConstruct();
    if(whileConstructs[processName] is AProcessSequentialComposition)
    {
      construct = whileConstructs[processName].construct1;
    }else
    {
      construct = whileConstructs[processName];
    }

    ProcessTransitionContainer cont = getProcessTransitionContainerForProcessConstruct(processName, construct.whileConstruct, copy, prevStateNo);
    for(str varName <- cont.actionList.varAssignments[processName])
    {
      if(!(processName in previousActionList.varAssignments) || !(varName in previousActionList.varAssignments[processName]) || cont.actionList.varAssignments[processName] != previousActionList.varAssignments[processName])
      {
        hasDifference = true;
      }
    }
  }

  println("hasDifference <hasDifference>");
  return hasDifference;
}

AProcessConstruct buildProcessComposition(AProcessConstruct abComposition, AProcessConstruct cConstruct)
{
  AProcessConstruct composition = AEmptyProcessConstruct();
  AProcessConstruct constructA  = AEmptyProcessConstruct();
  AProcessConstruct constructB  = AEmptyProcessConstruct();
  AProcessConstruct constructC  = cConstruct;


  if(!(abComposition.construct1 is AProcessSequentialComposition))
  {
    constructA = abComposition.construct1;
  }
  else{
    println("Yayks somm went wrong");
  }

  if(!(abComposition.construct2 is AProcessSequentialComposition))
  {
    constructB = AProcessSequentialComposition(abComposition.construct2, cConstruct);
  }else
  {
    constructB = buildProcessComposition(abComposition.construct2, cConstruct);
  }
  return AProcessSequentialComposition(constructA, constructB);
}

ProcessTransitionContainer getProcessTransitionContainerForIfStatement(ProcessActionList previousActionList, int prevStateNo)
{
  // STEP 1: Check if all next processInfo elements are either an IfProcessConstruct or a composition with an IFProcessConstruct as its first element 
  if(!allNextProcessInfoElementsAreIf(previousActionList.processInfo))
  {
    return EmptyProcessTransitionContainer();
  }

  // STEP 2: evaluate all values and check if they all evaluate to the same value
  set[bool] evaluationResults = evaluateAllExpressions(previousActionList);
  if(!(size(evaluationResults) == 1))
  {
    println("The if could not be projected!");
     return EmptyProcessTransitionContainer();
  }

  // STEP 3: Create a map for thenElseConstructs and update the procesInfo to the next processConstruct
  map[str, tuple[AProcessConstruct, AProcessConstruct]] thenElseConstructs = createThenElseConstructs(previousActionList.processInfo);
  for(str name <- previousActionList.processInfo)
  {
    previousActionList.processInfo[name] = getNextRequiredProcessConstructs(previousActionList.processInfo[name]);
  }

  // STEP 4: Update processInfo based on the evaluation results
  for (str name <- previousActionList.processInfo) {
    if (getFirstFrom(evaluationResults)) 
    {
      AProcessConstruct nextConstruct = AEmptyProcessConstruct();
      if(size(previousActionList.processInfo[name]) == 0)
      {
        nextConstruct = thenElseConstructs[name][0];
      }
      else if(thenElseConstructs[name][0] is AProcessSequentialComposition && size(previousActionList.processInfo[name]) > 0)
      {
         nextConstruct = AProcessSequentialComposition(thenElseConstructs[name][0].construct1, AProcessSequentialComposition(thenElseConstructs[name][0].construct2, previousActionList.processInfo[name][0]));
      }else if(size(previousActionList.processInfo[name]) > 0)
      {
        nextConstruct = AProcessSequentialComposition(thenElseConstructs[name][0], previousActionList.processInfo[name][0]);
      }
      
      previousActionList.processInfo[name] = [nextConstruct];
    } 
    else 
    {
      AProcessConstruct nextConstruct = AEmptyProcessConstruct();
      if(size(previousActionList.processInfo[name]) == 0)
      {
        nextConstruct = thenElseConstructs[name][1];
      }
      else if(thenElseConstructs[name][1] is AProcessSequentialComposition && size(previousActionList.processInfo[name]) > 0)
      {
         nextConstruct = AProcessSequentialComposition(thenElseConstructs[name][1].construct1, AProcessSequentialComposition(thenElseConstructs[name][1].construct2, previousActionList.processInfo[name][0]));
      }else if(size(previousActionList.processInfo[name]) > 0)
      {
        nextConstruct = AProcessSequentialComposition(thenElseConstructs[name][1], previousActionList.processInfo[name][0]);
      }

      // AProcessConstruct nextConstruct = size(previousActionList.processInfo[name]) == 0 ? thenElseConstructs[name][1] : AProcessSequentialComposition(thenElseConstructs[name][1], previousActionList.processInfo[name][0]);
      previousActionList.processInfo[name] = [nextConstruct]; 
    }
  }

  // STEP 5: return the process container where all the process have evaluated the if-statement
  TransitionInfo transitionInfo = TransitionInfo(
                                      prevStateNo,
                                      getStateCounterForProcesses(EmptyActionList(),false, {}),
                                      false,
                                      IfThenElseDecisionLabelInfo(getFirstFrom(evaluationResults))
                                    );
  
  return ProcessTransitionContainer(previousActionList, transitionInfo);
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

  return getTauContainer(newActionList, previousStateNo, getStateCounterForProcesses(EmptyActionList(), false, {}));
}

ProcessTransitionContainer getProcessTransitionContainerForAssignment(str processName, str variableName, AExchangeValueDeclaration exchangeValueDeclaration, AAssignmentOperator assignmentOperator,ProcessActionList previousActionList, int prevStateNo)
{
  map[str, map[str, AExchangeValueDeclaration]] varAssignments = ();
  varAssignments = updateVariableAssignment(previousActionList, "<processName>", "<variableName>", exchangeValueDeclaration, assignmentOperator);
  
  previousActionList.processInfo[processName] = getNextRequiredProcessConstructs(previousActionList.processInfo[processName]);
  ProcessActionList updatedActionList = previousActionList;
  updatedActionList.varAssignments = varAssignments;
  
  TransitionInfo transitionInfo = TransitionInfo(
      prevStateNo,
      getStateCounterForProcesses(EmptyActionList(), false, {}),
      false,
      AssignmentTransitionLabelInfo(
        processName,
        variableName,
        exchangeValueDeclaration,
        assignmentOperator
      ));

  return  ProcessTransitionContainer(updatedActionList, transitionInfo);
}

ProcessTransitionContainer getProcessTransitionContainerForProcessInteraction(str sendingProcessName, str receivingProcessName, AProcessConstruct processConstruct, ProcessActionList previousActionList, int prevStateNo)
{
  if(size(previousActionList.processInfo[sendingProcessName]) == 0 || size(previousActionList.processInfo[receivingProcessName]) == 0)
  {
      return EmptyProcessTransitionContainer();
  }

  AProcessConstruct sendingConstruct = getProcessConstruct(previousActionList.processInfo[sendingProcessName][0]);
  AProcessConstruct receivingConstruct = getProcessConstruct(previousActionList.processInfo[receivingProcessName][0]);

  // controle type
  if(!(sendingConstruct is AProcessInteractionOutput) || !(receivingConstruct is AProcessInteractionInput))
  {
    return EmptyProcessTransitionContainer();
  }
  
  // controle tau construct
  if(sendingConstruct is ATauConstruct || receivingConstruct is ATauConstruct)
  {
    return EmptyProcessTransitionContainer();
  }

  // controle juiste interactie
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
                                      false,
                                      TransitionLabelInfo(
                                        sendingProcessName,
                                        receivingProcessName,
                                        varFrom,
                                        varTo,
                                        exchangeValue
                                      )
                                    );
  
  return ProcessTransitionContainer(updatedActionList, transitionInfo);
}

ProcessActionList updateActionListForSenderAndReceiver(ProcessActionList actionList, str sendingProcessName, str receivingProcessName)
{
  actionList.processInfo[sendingProcessName] = getNextRequiredProcessConstructs(actionList.processInfo[sendingProcessName]); 
  actionList.processInfo[receivingProcessName] = getNextRequiredProcessConstructs(actionList.processInfo[receivingProcessName]); 
  return actionList;
}

AProcessConstruct getProcessConstruct(AProcessConstruct construct)
{
  if(construct is AProcessSequentialComposition)
  {
    return construct.construct1;
  }
  return construct;
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

ProcessTransitionContainer getTauContainer(ProcessActionList actionList, int stateFrom, int stateTo)
{
  return ProcessTransitionContainer(
      actionList,
      TransitionInfo(stateFrom, stateTo, true, TransitionLabelInfo("","","","",AEmptyExchangeValueDeclaration()))
    );
}

int getStateCounterForProcesses(ProcessActionList newProcessActionList, bool updateStateCounter, set[ProcessTransitionContainer] toBeCheckedContainers)
{
  if(!updateStateCounter)
  {
    return stateCounter;
  }

  for(ProcessTransitionContainer container <- toBeCheckedContainers)
  {  
    bool allRemainingConstructsEqual = areAllRemainingConstructsEqual(container.actionList, newProcessActionList); 

    if(allRemainingConstructsEqual)
    {
      return container.transitionInfo.nextStateNo;
    }
  }
  
  stateCounter = stateCounter + 1;
  return stateCounter;
}

bool areAllRemainingConstructsEqual(ProcessActionList list1, ProcessActionList list2) {
    
    if(list1.varAssignments != list2.varAssignments)
    {
      return false;
    }

    for (str processName <- list1.processInfo) {
        if (list1.processInfo[processName] != list2.processInfo[processName]) {
            return false;
        }
    }
    return true;
}

bool isTerminatingContainer(ProcessActionList actionList)
{
  for (str processName <- actionList.processInfo)
  {
    if (!isEmpty(actionList.processInfo[processName]))
    {
      return false;
    }
  }

  return true;
}