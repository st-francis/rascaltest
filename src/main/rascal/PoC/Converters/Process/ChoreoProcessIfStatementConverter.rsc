module PoC::Converters::Process::ChoreoProcessIfStatementConverter

import PoC::ChoreoProcessLanguage::ChoreoProcessAbstract;

import PoC::Converters::Process::ChoreoProcessDataTypes;
import PoC::Converters::Process::ChoreoProcessASTsToLTSConverter;

import PoC::Evaluators::ExpressionASTEvaluator;

import PoC::CommonLanguageElements::ExchangeValueAbstract;

import PoC::Utils::LabelUtil;

import PoC::Machines::LabeledTransitionSystem;

import IO;
import List;
import Set;

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

      previousActionList.processInfo[name] = [nextConstruct]; 
    }
  }

  // STEP 5: return the process container where all the process have evaluated the if-statement
  TransitionInfo transitionInfo = TransitionInfo(
                                      prevStateNo,
                                      getStateCounterForProcesses(EmptyActionList(),false, {}),
                                      getIfStatementEvaluationLabel(getFirstFrom(evaluationResults)),
                                      IfEvaluationTransition()
                                    );
  
  return ProcessTransitionContainer(previousActionList, transitionInfo);
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