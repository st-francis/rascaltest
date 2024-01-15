module PoC::Converters::Choreography::ChoreoASTToFSMConverter

import PoC::ChoreoLanguage::ChoreoAbstract;

import PoC::Converters::Choreography::ChoreoConverterDataTypes;
import PoC::Converters::Choreography::ChoreoAssignmentConverter;
import PoC::Converters::Choreography::ChoreoInteractionConverter;
import PoC::Converters::Choreography::ChoreoCompositionConverter;
import PoC::Converters::Choreography::ChoreoIfStatementConverter;
import PoC::Converters::Choreography::ChoreoWhileStatementConverter;

import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;

import PoC::Machines::FiniteStateMachine;

import PoC::Evaluators::ExpressionASTEvaluator;

import PoC::Utils::ChoreographyUtil;
import PoC::Utils::LabelUtil;
import PoC::Utils::ExpressionUtil;

import List;
import Set;
import IO;
import String;

int stateCounter = 0;
int initialStateNo = 0;


// The collection of TransitionContainers that is maintained during the evaluation
set[TransitionContainer] transitionContainers = {};
set[int] processedStateNos = {};

// Main function to evaluate an choreographyConstruct and convert in to a set of TransitionInfo
// INPUT  : @choreographyConstruct - the construct that represent the parsed choreography    
// OUTPUT : The set of transitioninfos that are derived from the choreographyConstruct
FiniteStateMachine convertChoreoASTToFSM(str choreographyName, AChoreographyConstruct choreographyConstruct)
{
  stateCounter = initialStateNo;
  transitionContainers = {};
  
  if(isTerminatingChorConstruct(choreographyConstruct))
  {
    return FiniteStateMachine(choreographyName, "0", {});
  }
  set[TransitionInfo] transitionInfo = buildTransitionInfo(choreographyConstruct);
  return FiniteStateMachine(choreographyName, "0", transitionInfo);
}

// Function that retrieves the set of transitionInfos in a breadth-first manner
// INPUT  : @choreographyConstruct - the construct that represent the parsed choreographyConstruct
// OUTPUT : The set of transitionInfos that are derived from the choreographyConstruct
set[TransitionInfo] buildTransitionInfo(AChoreographyConstruct choreographyConstruct)
{
    transitionContainers = getInitialProcessInteractions(choreographyConstruct, ());

    set[TransitionContainer] nextProcessInteractions = transitionContainers;

    while (!(isEmpty(nextProcessInteractions)))
    {
        nextProcessInteractions = processNextInteractions(nextProcessInteractions);
    }

    transitionContainers += getTauContainersForContainers(transitionContainers);

    return extractTransitionInfo(transitionContainers);
}

// Function that comprehends the set of TransitionContainers and returs a new set of transitionInfos
// INPUT : @TransitionContainers - the interaction containers that are derived from the base construct
// OUTPT : a set of transitioninfos that contain the relevant info for the FSM  
set[TransitionInfo] extractTransitionInfo(set[TransitionContainer] TransitionContainers)
{
  return {container.extraInfo.transitionInfo | TransitionContainer container <- TransitionContainers};
}

// Function that iterates over a set of containers and returns the next containers based on the set of containers
// INPUT : @currentInteractions - the current interactions
// OUTPU : The set of new process interaction containers 
set[TransitionContainer] processNextInteractions(set[TransitionContainer] previousInteractions)
{
    set[TransitionContainer] newProcessInteractions = {};

    for (TransitionContainer previousInteraction <- previousInteractions)
    {
        set[TransitionContainer] requiredInteractions = getStateProcessInteractions(previousInteraction.extraInfo.requiredChor, previousInteraction.extraInfo.transitionInfo.nextStateNo, previousInteraction.extraInfo.variableAssignments, false, AEmptyChoreographyConstruct());
        newProcessInteractions += processRequiredInteractionsWithValidStateCounter(requiredInteractions);
        transitionContainers += newProcessInteractions;
    }

    return newProcessInteractions;
}

// Function does not so much except re-set the state counter which could not be done befor
// INPUT : @requiredInteractions - the new transitionContainers
// OUTPU : A set of the same interaction containers, with possibly updated state numbers
set[TransitionContainer] processRequiredInteractionsWithValidStateCounter(set[TransitionContainer] transitionContainers)
{
  return {TransitionContainer(interaction.construct, TransitionContainerExtraInfo(
                                                                                    interaction.extraInfo.requiredChor, 
                                                                                    TransitionInfo(
                                                                                      interaction.extraInfo.transitionInfo.prevStateNo, 
                                                                                      getStateCounter(interaction.extraInfo.requiredChor, true, interaction.extraInfo.variableAssignments),
                                                                                      interaction.extraInfo.transitionInfo.transitionLabel,
                                                                                      interaction.extraInfo.transitionInfo.transitionType)
                                                                                      , interaction.extraInfo.variableAssignments)) 
                                | TransitionContainer interaction <- transitionContainers};
}

// Function determines the initialContainers for the first choreographyConstruct 
// INPUT  : The base choreography construct
// OUTPUT : The first set of process interaction containers 
set[TransitionContainer] getInitialProcessInteractions(AChoreographyConstruct choreographyConstruct, map[str, map[str, AExchangeValueDeclaration]] initialVariableAssignments) {
    return { TransitionContainer(
                interaction.construct, 
                TransitionContainerExtraInfo(
                    interaction.extraInfo.requiredChor,
                    TransitionInfo(
                      interaction.extraInfo.transitionInfo.prevStateNo,
                      getStateCounter(interaction.extraInfo.requiredChor, true, interaction.extraInfo.variableAssignments),
                      interaction.extraInfo.transitionInfo.transitionLabel,
                      interaction.extraInfo.transitionInfo.transitionType
                    ),
                    interaction.extraInfo.variableAssignments
                )
            )
            | TransitionContainer interaction <- getStateProcessInteractions(choreographyConstruct, getStateCounter(AEmptyChoreographyConstruct(), false, initialVariableAssignments), initialVariableAssignments, false, AEmptyChoreographyConstruct())};
}

// Function adds a tau transition to all states that have a terminating choreography construct
// INPUT  : @containers - the containers that need to be checked if a tau should be added
// OUTPUT : The extra TAU containers that need to be added
set[TransitionContainer] getTauContainersForContainers(set[TransitionContainer] containers)
{
  set[TransitionContainer] tauContainers = {};

  for(TransitionContainer container <- containers)
  {
    if(isTerminatingChorConstruct(container.extraInfo.requiredChor))
    {
      tauContainers += {getTauContainer(container.extraInfo.transitionInfo.nextStateNo, container.extraInfo.transitionInfo.nextStateNo, 
            AProcessInteraction(
              AEmptyProcess(),
              AEmptyExchangeValueDeclaration(), 
              AEmptyProcess()),
              AEmptyChoreographyConstruct()
              , (), true)};
    }
  }

  return tauContainers;
}

// Function returns the containers that are derived for a choreographyConstruct
// INPUT  : @choreographyConstruct - the related construct that is switched on
// INPUT  : @currentState - the current state number 
// OUTPUT : The set of containers that are returned based on the construct
set[TransitionContainer] getStateProcessInteractions(AChoreographyConstruct choreographyConstruct, int currentState, map[str, map[str, AExchangeValueDeclaration]] variableAssignments, bool partOfComposition, AChoreographyConstruct originalConstruct)
{ 
  switch(choreographyConstruct)
  {
    case AChoreographyComposition(AChoreographyConstruct _, AChoreographyConstruct _):
      return transitionContainerForComposition(choreographyConstruct, currentState, variableAssignments);
    case AProcessInteraction(AProcess _, AExchangeValueDeclaration _, AProcess _):
      return transitionContainerForInteraction(choreographyConstruct, currentState, variableAssignments);
    case AVariableAssignment(str _, str _, AExchangeValueDeclaration _, AAssignmentOperator _):
      return transitionContainerForAssignment(choreographyConstruct, currentState, variableAssignments);
    case AIfStatement(AExpression _, AChoreographyConstruct _, AChoreographyConstruct _):
      return transitionContainerForIfStatement(choreographyConstruct, currentState, variableAssignments);
    case AWhileStatement(AExpression _, AChoreographyConstruct _):
      return transitionContainerForWhileStatement(choreographyConstruct, currentState, variableAssignments, partOfComposition, originalConstruct);
    case AEmptyChoreographyConstruct():
      return {};
    default: throw "No matching choreography construct found!";
  }
}

bool equivalentStateExists(AChoreographyConstruct remainingConstruct, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  for(TransitionContainer container <- transitionContainers)
  {
    if(container.extraInfo.requiredChor == remainingConstruct && container.extraInfo.variableAssignments == variableAssignments)
    {
      return true;
    }
  }

  return false;
}


// Function that updates the variable assignments 
// INPUT  : @processName - name of the process that has an updated variable
// INPUT  : @variableName - the name of the variable that is updated
// INPUT  : @exchangeValueDeclaration - the new value of the variable
map[str, map[str, AExchangeValueDeclaration]] updateVariableAssignment(str processName, str variableName, AExchangeValueDeclaration exchangeValueDeclaration, map[str, map[str, AExchangeValueDeclaration]] variableAssignments, AAssignmentOperator assignmentOperator)
{
  if(!(processName in variableAssignments) || !(variableName in variableAssignments[processName]))
  {
    if(!(processName in variableAssignments))
    {
      variableAssignments[processName] = ();
    }

    if(!(variableName in variableAssignments[processName]))
    {
      variableAssignments[processName][variableName] = AEmptyExchangeValueDeclaration();
    }
  }else
  {
      if(assignmentOperator is AAdditionOperator)
      {
        int previousValue = toInt(variableAssignments[processName][variableName].val);
        int newValue = previousValue + toInt(exchangeValueDeclaration.val);
        exchangeValueDeclaration = AExchangeValueDeclaration("<newValue>", exchangeValueDeclaration.valType);
      }
  }

  variableAssignments[processName][variableName] = exchangeValueDeclaration;

  return variableAssignments;
}


AChoreographyConstruct tryGetFirstChoreographyConstruct(set[TransitionContainer] containers)
{
  if(size(containers) == 0)
  {
    return AEmptyChoreographyConstruct();
  }
  else
  {
    return getFirstFrom(containers).construct;
  }
}

// Function that returns a tau container 
// INPUT  : @stateFrom - state number from where the tau transition is departing
// INPUT  : @stateTo  - state number where the tau transition is going to
// OUTPUT : the tau container 
TransitionContainer getTauContainer(int stateFrom, int stateTo, AChoreographyConstruct concerningConstruct, AChoreographyConstruct remainingConstruct, map[str, map[str, AExchangeValueDeclaration]] variableAssignments, bool isFinal)
{
  Label tauLabel = isFinal ? getFinalTauLabel() : getTauLabel();

  return TransitionContainer(
            concerningConstruct, 
            TransitionContainerExtraInfo(
              remainingConstruct,
              TransitionInfo(
                stateFrom, 
                stateTo, 
                tauLabel,
                TauTransition()
              ),
              variableAssignments
            )
        );
}

// Function that checkes whether two constructs have overlapping process names
// INPUT  : @construct1 - the first construct
// INPUT  : @construct2 - the second construct
// OUTPUT : flag to indicate if there are overlapping process names
bool hasOverlappingProcessNames(AChoreographyConstruct construct1, AChoreographyConstruct construct2)
{
  if(construct1 is AEmptyChoreographyConstruct || construct2 is AEmptyChoreographyConstruct)
  {
    println("returning true");
    return true;
  }

  set[str] construct1Names = findUniqueProcessNamesForAChoreographyConstruct(construct1);
  set[str] construct2Names = findUniqueProcessNamesForAChoreographyConstruct(construct2);

  for(str name <- construct1Names)
  {
    if(name in construct2Names)
    {
      return true;
    }
  }

  return false;
}

// Function that composes two choreography construct to one construct
// INPUT  : @construct1 - the first construct
// INPUT  : @construct2 - the second construct
// OUTPUT The composed construct
AChoreographyConstruct composeChorConstructs(AChoreographyConstruct construct1, AChoreographyConstruct construct2)
{
  bool construct1Empty = (construct1 is AEmptyChoreographyConstruct);
  bool construct2Empty = (construct2 is AEmptyChoreographyConstruct);
  
  AChoreographyConstruct compositeChorConstruct = 
      construct1Empty  && !construct2Empty ? construct2 :
      !construct1Empty && construct2Empty ? construct1 :
      !construct1Empty && !construct2Empty ? AChoreographyComposition(construct1, construct2) :
      AEmptyChoreographyConstruct();

  return compositeChorConstruct;
}

// Function to return a new state counter, which also checks if already existing states have an equal set of remaining constructs
// INPUT  : @choreographyConstruct - the remainingConstruct which is required to compare with older constructs
// INPUT  : @withUpdate - flag to indicate if the stateCounter should be updated or not
// INPUT  : @variableAssignments - the local set of assigned variables 
// OUTPUT : the new state number 
int getStateCounter(AChoreographyConstruct remainingConstruct, bool withUpdate, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  if(!withUpdate)
  {
    return stateCounter;
  }

  for(TransitionContainer container <- transitionContainers)
  {
    
    if(container.extraInfo.requiredChor == remainingConstruct && container.extraInfo.variableAssignments == variableAssignments)
    {
      return container.extraInfo.transitionInfo.nextStateNo;
    }
  }
  
  return stateCounter = stateCounter + 1;
}