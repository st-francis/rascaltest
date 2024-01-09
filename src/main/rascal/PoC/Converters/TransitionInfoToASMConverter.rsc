module PoC::Converters::TransitionInfoToASMConverter

import PoC::Machines::AbstractStateMachine;
import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::Converters::ChoreoProcessASTsToTransitionInfoConverter;
import PoC::Converters::ChoreoASTToTransitionInfoConverter;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;
import String;


AbstractStateMachine convertTransitionInfosToASM(str choreographyName, set[TransitionInfo] transitionInfos)
{
  list[Transition] transitions = getTransitionsForTransitionInfos(transitionInfos);
  return AbstractStateMachine(choreographyName, "0", transitions);
}

list[Transition] getTransitionsForTransitionInfos(set[TransitionInfo] transitionInfos)
{
  list[Transition] transitions = [];

  for(TransitionInfo transitionInfo <- transitionInfos)
  {
    Transition transition = getTransitionForTransitionInfo(transitionInfo);
    transitions += transition;
  }

  return transitions;
}

Transition getTransitionForTransitionInfo(TransitionInfo transitionInfo)
{
  str actionLabel = transitionInfo.isTau ? "T" : getActionLabelForTransitionLabelInfo(transitionInfo.transitionLabelInfo);

  list[tuple[str,str]] argument = [];
  
  if(transitionInfo.transitionLabelInfo is TransitionLabelInfo)
  {
    AExchangeValueDeclaration exchangeValueDeclaration = transitionInfo.transitionLabelInfo.exchangeValueDeclaration;
    if(!(exchangeValueDeclaration is AEmptyExchangeValueDeclaration))
    {
      argument = [<exchangeValueDeclaration.valType, exchangeValueDeclaration.val>];
    }
  }

  return Transition(State("<transitionInfo.prevStateNo>"), Label("<actionLabel>", argument), State("<transitionInfo.nextStateNo>"));
}

str getActionLabelForTransitionLabelInfo(TransitionLabelInfo transitionLabelInfo)
{
  if(transitionLabelInfo is AssignmentTransitionLabelInfo)
  {
    return getAssignmentTransitionLabelInfoActionLabel(transitionLabelInfo);
  }
  
  if(transitionLabelInfo is IfThenElseDecisionLabelInfo)
  {
    return getIfThenElseDecisionLabelInfoActionLabel(transitionLabelInfo);
  }

  if(transitionLabelInfo is WhileDecisionLabelInfo)
  {
    return getWhileDecisionLabelInfoActionLabel(transitionLabelInfo);
  }
  
  return getProcessInteractionActionLabel(transitionLabelInfo);
}

str getIfThenElseDecisionLabelInfoActionLabel(TransitionLabelInfo labelInfo)
{
  if(labelInfo.isThen)
  {
    return "THEN";
  }
  else
  {
    return "ELSE";
  }
}

str getWhileDecisionLabelInfoActionLabel(TransitionLabelInfo labelInfo)
{
   if(labelInfo.reentering)
    {
      return "REENTERING";
    }
    else
    {
      return "EXITING";
    }
}

str getAssignmentTransitionLabelInfoActionLabel(TransitionLabelInfo labelInfo)
{
  str assignmentOperatorLabel = "is";
  if(labelInfo.assignmentOperator is AAdditionOperator)
  {
    assignmentOperatorLabel = "plus_is";
  }
  return "<labelInfo.currentProcess>_<labelInfo.variableName>_<assignmentOperatorLabel>_<labelInfo.exchangeValueDeclaration.val>_<labelInfo.exchangeValueDeclaration.valType>";
}

str getProcessInteractionActionLabel(TransitionLabelInfo labelInfo)
{
  str varFrom     = "";
  bool hasSendingVar = !isEmpty(labelInfo.varFrom);
  if(hasSendingVar)
  {
    varFrom = "_<labelInfo.varFrom>"; 
  } 

  return "<labelInfo.sender><varFrom>_to_<labelInfo.receiver>_<labelInfo.varTo>";
}