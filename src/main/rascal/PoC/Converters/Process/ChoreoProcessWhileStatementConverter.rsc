module PoC::Converters::Process::ChoreoProcessWhileStatementConverter

import PoC::ChoreoProcessLanguage::ChoreoProcessAbstract;

import PoC::Converters::Process::ChoreoProcessDataTypes;
import PoC::Converters::Process::ChoreoProcessASTsToLTSConverter;

import PoC::Utils::ActionListUtil;
import PoC::Utils::LabelUtil;

import PoC::Evaluators::ExpressionASTEvaluator;

import PoC::Machines::LabeledTransitionSystem;

import IO;
import Set;
import List;

ProcessTransitionContainer getProcessTransitionContainerForWhileStatement(ProcessActionList previousActionList, int prevStateNo, set[ProcessTransitionContainer] actualContainers)
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
  bool equivalentStateAlreadyExists = equivalentProcessesStateExists(previousActionList, actualContainers);
  if(!hasDifferences && equivalentStateAlreadyExists)
  {
    return EmptyProcessTransitionContainer();
  }

  // STEP 5: return the process container where all the process have evaluated the if-statement
  TransitionInfo transitionInfo = TransitionInfo(
                                      prevStateNo,
                                      getStateCounterForProcesses(EmptyActionList(),false, {}),
                                      getWhileStatementEvaluationLabel(getFirstFrom(evaluationResults)),
                                      WhileEvaluationTransition()
                                    );


    return ProcessTransitionContainer(previousActionList, transitionInfo);
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

  return hasDifference;
}

bool equivalentProcessesStateExists(ProcessActionList processActionList, set[ProcessTransitionContainer] toBeCheckedContainers)
{
  for(ProcessTransitionContainer container <- toBeCheckedContainers)
  {  
    bool allRemainingConstructsEqual = areActionListsEqual(container.actionList, processActionList); 

    if(allRemainingConstructsEqual)
    {
      return true;
    }
  }
  return false;
}