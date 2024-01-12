module PoC::Converters::ChoreoASTToTransitionInfoConverter

import PoC::ChoreoLanguage::ChoreoAbstract;

import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;

import PoC::Machines::AbstractStateMachine;

import PoC::Evaluators::ExpressionASTEvaluator;

import PoC::Utils::LabelUtil;

import List;
import Set;
import IO;
import String;

int stateCounter = 0;
int initialStateNo = 0;


// The collection of TransitionContainers that is maintained during the evaluation
set[TransitionContainer] transitionContainers = {};
set[int] processedStateNos = {};

// The TransitionContainer contains the relevant choreography construct and the related extra info 
data TransitionContainer = TransitionContainer(AChoreographyConstruct construct, TransitionContainerExtraInfo extraInfo);

// The extra info contains the required choreography that is required after the transition and the transitioninfo
data TransitionContainerExtraInfo = TransitionContainerExtraInfo(AChoreographyConstruct requiredChor, TransitionInfo transitionInfo, map[str, map[str, AExchangeValueDeclaration]] variableAssignments);

// Main function to evaluate an choreographyConstruct and convert in to a set of TransitionInfo
// INPUT  : @choreographyConstruct - the construct that represent the parsed choreography    
// OUTPUT : The set of transitioninfos that are derived from the choreographyConstruct
AbstractStateMachine convertChoreoASTToASM(str choreographyName, AChoreographyConstruct choreographyConstruct)
{
  stateCounter = initialStateNo;
  transitionContainers = {};
  
  if(isTerminatingChorConstruct(choreographyConstruct))
  {
    return AbstractStateMachine(choreographyName, "0", {});
  }
  set[TransitionInfo] transitionInfo = buildTransitionInfo(choreographyConstruct);
  return AbstractStateMachine(choreographyName, "0", transitionInfo);
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

map[str, map[str, AExchangeValueDeclaration]] getVariableAssignmentsForWhileConstructContent(AChoreographyConstruct content, map[str, map[str, AExchangeValueDeclaration]] variableAssignments )
{
  map[str, map[str, AExchangeValueDeclaration]] tempVariableAssignments = ();
  switch(content)
  {
     case AChoreographyComposition(AChoreographyConstruct firstConstruct, AChoreographyConstruct secondConstruct):
      tempVariableAssignments += getVariableAssignmentsForWhileConstructContent(firstConstruct,  variableAssignments) + getVariableAssignmentsForWhileConstructContent(secondConstruct, variableAssignments);
    case AProcessInteraction(AProcess _, AExchangeValueDeclaration exchangeValueDeclaration, AProcess receivingProcess):
      tempVariableAssignments += updateVariableAssignment(receivingProcess.name, receivingProcess.variableName, exchangeValueDeclaration, variableAssignments, AEmptyAssignmentOperator());
    case AVariableAssignment(str processName, str variableName, AExchangeValueDeclaration exchangeValueDeclaration, AAssignmentOperator assignmentOperator):
      tempVariableAssignments += updateVariableAssignment(processName, variableName, exchangeValueDeclaration, variableAssignments, assignmentOperator);
    case AIfStatement(AExpression expression, AChoreographyConstruct thenConstruct, AChoreographyConstruct elseConstruct):
      tempVariableAssignments += getVariableUpdatesForIfStatement(expression, thenConstruct, elseConstruct, variableAssignments);
    case AWhileStatement(AExpression expression, AChoreographyConstruct whileConstruct):
      tempVariableAssignments += getVariableUpdatesForWhileStatement(expression, whileConstruct, variableAssignments);
    case AEmptyChoreographyConstruct():
      tempVariableAssignments += ();
  }

  return tempVariableAssignments;
}

map[str, map[str, AExchangeValueDeclaration]] getVariableUpdatesForWhileStatement(AExpression expression, AChoreographyConstruct whileConstruct, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
    bool evaluationRes = evaluateExpression(expression, variableAssignments);
    if(evaluationRes)
    {
      return getVariableAssignmentsForWhileConstructContent(whileConstruct, variableAssignments);
    }
    else
    {
      return ();
    }
}

map[str, map[str, AExchangeValueDeclaration]] getVariableUpdatesForIfStatement(AExpression expression, AChoreographyConstruct thenConstruct, AChoreographyConstruct elseConstruct, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  bool evaluationRes = evaluateExpression(expression, variableAssignments);
  if(evaluationRes)
  {
    return getVariableAssignmentsForWhileConstructContent(thenConstruct, variableAssignments);
  }
  else
  {
    return getVariableAssignmentsForWhileConstructContent(elseConstruct, variableAssignments);
  }
}

bool doesWhileContentMakeAnyDifference(AChoreographyConstruct whileConstruct, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  map[str, map[str, AExchangeValueDeclaration]] tempVars = getVariableAssignmentsForWhileConstructContent(whileConstruct, variableAssignments);
  
  bool hasDifference = false; 
  for(str processName <- tempVars)
  {
    for(str varName <- tempVars[processName])
    {
      if(!(processName in variableAssignments) || !(varName in variableAssignments[processName]) || variableAssignments[processName][varName] != tempVars[processName][varName])
      {
        hasDifference = true;
      }
    }
  }

  return hasDifference;
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

// Function returns the containers when an while-statement is encountered 
// INPUT  : @baseConstruct the construct for the while-statement
// INPUT  : @currentState the current state number
// INPUT  : @variableAssignments the current variableAssignments
// OUTPUT : The set of containers based on the while-statement
set[TransitionContainer] transitionContainerForWhileStatement(AChoreographyConstruct baseConstruct, int currentState, map[str, map[str, AExchangeValueDeclaration]] variableAssignments, bool partOfComposition, AChoreographyConstruct baseConstructWithAdditionalConstructs)
{
  bool enterWhile = evaluateExpression(baseConstruct.expression, variableAssignments);

  AChoreographyConstruct remainingConstruct = AEmptyChoreographyConstruct();
  if(enterWhile)
  {
      remainingConstruct = (partOfComposition) ? baseConstruct.whileConstruct : AChoreographyComposition(baseConstruct.whileConstruct, baseConstruct);

      AChoreographyConstruct constructToBeChecked = remainingConstruct;
      if(!(baseConstructWithAdditionalConstructs is AEmptyChoreographyConstruct))
      {
        constructToBeChecked = AChoreographyComposition(remainingConstruct, baseConstructWithAdditionalConstructs);
      }
      
      bool whileContentMakesAnyDifference = doesWhileContentMakeAnyDifference(baseConstruct.whileConstruct, variableAssignments);
      bool equivalentStateAlreadyExists = equivalentStateExists(constructToBeChecked, variableAssignments);
      if(!whileContentMakesAnyDifference && equivalentStateAlreadyExists)
      {
        return {};
      }
  }

  return {TransitionContainer(baseConstruct, 
                                  TransitionContainerExtraInfo(remainingConstruct, 
                                                              TransitionInfo(
                                                                currentState, 
                                                                getStateCounter(AEmptyChoreographyConstruct(), false, variableAssignments),
                                                                getWhileStatementEvaluationLabel(enterWhile),
                                                                WhileEvaluationTransition()),
                                                              variableAssignments))};
}

// Function returns the containers when an if-statement is encountered 
// INPUT  : @ifConstruct the construct for the if-statement
// INPUT  : @expression the expression for the if-statement
// INPUT  : @thenConstruct the construct that needs to be processed if the expression evaluates to true
// INPUT  : @elseConstruct the construct that needs to be processed if the expression evaluates to false
// INPUT  : @currentState the current state number
// INPUT  : @variableAssignments the current variableAssignments
// OUTPUT : The set of containers based on the if-statement
set[TransitionContainer] transitionContainerForIfStatement(AChoreographyConstruct ifConstruct, int currentState, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  bool evaluateThen = evaluateExpression(ifConstruct.expression, variableAssignments);
  AChoreographyConstruct remainingConstruct = AEmptyChoreographyConstruct();
  if(evaluateThen)
  {
    remainingConstruct = ifConstruct.thenConstruct;
  }
  else
  {
    remainingConstruct = ifConstruct.elseConstruct;
  }

  return {TransitionContainer(ifConstruct, 
                                      TransitionContainerExtraInfo(remainingConstruct, 
                                                                  TransitionInfo(
                                                                    currentState, 
                                                                    getStateCounter(AEmptyChoreographyConstruct(), false, variableAssignments),
                                                                    getIfStatementEvaluationLabel(evaluateThen),
                                                                    IfEvaluationTransition()),
                                                                  variableAssignments))};
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

// Function that returns the process containers for a composition construct 
// It returns a transition to the first construct of the composition
// In addition it returns containers for constructs that have no overlapping names with the first construct of the composition
// INPUT  : @composition - the composition construct
// INPUT  : @currentState - the current state from which the composition is encountered 
// OUTPUT : A set of interaction containers as a result of the composition
set[TransitionContainer] transitionContainerForComposition(AChoreographyConstruct composition, int currentState, map[str, map[str, AExchangeValueDeclaration]] variableAssignments)
{
  AChoreographyConstruct toBeAddedToFirstConstruct = composition.secondConstruct;

  // construct 1 check
  if(composition.firstConstruct is AWhileStatement)
  {
    bool isWhileEntered = evaluateExpression(composition.firstConstruct.expression, variableAssignments);

    if(isWhileEntered)
    {
      toBeAddedToFirstConstruct = AChoreographyComposition(composition.firstConstruct, composition.secondConstruct);
    }
  }

  // (1) Getting set1
  set[TransitionContainer] set1 = { TransitionContainer(interaction.construct,
                                            TransitionContainerExtraInfo(
                                              composeChorConstructs(interaction.extraInfo.requiredChor, toBeAddedToFirstConstruct),
                                              TransitionInfo(
                                                currentState, 
                                                getStateCounter(AEmptyChoreographyConstruct(), false, interaction.extraInfo.variableAssignments), 
                                                interaction.extraInfo.transitionInfo.transitionLabel,
                                                interaction.extraInfo.transitionInfo.transitionType
                                              ),
                                              interaction.extraInfo.variableAssignments
                                            ))
                                            | TransitionContainer interaction <- getStateProcessInteractions(composition.firstConstruct, currentState, variableAssignments, true, toBeAddedToFirstConstruct)};


  // (2) Getting set2
  set[TransitionContainer] set2 = { TransitionContainer(interaction.construct, 
                                            TransitionContainerExtraInfo(
                                              composeChorConstructs(composition.firstConstruct, 
                                              interaction.extraInfo.requiredChor), 
                                              TransitionInfo(
                                                currentState, 
                                                getStateCounter(AEmptyChoreographyConstruct(), false, interaction.extraInfo.variableAssignments), 
                                                interaction.extraInfo.transitionInfo.transitionLabel,
                                                interaction.extraInfo.transitionInfo.transitionType
                                                ),
                                                interaction.extraInfo.variableAssignments)
                                            ) 
                                          | TransitionContainer interaction <- getStateProcessInteractions(composition.secondConstruct, currentState, variableAssignments, true, composition.secondConstruct)
                                          , !hasOverlappingProcessNames(tryGetFirstChoreographyConstruct(set1), interaction.construct)};

  // (3) Unifying the two sets
  set1 += set2;

  // (4) Returning the sets
  return set1;
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

  set[str] construct1Names = getNamesForChoreographyConstruct(construct1);
  set[str] construct2Names = getNamesForChoreographyConstruct(construct2);

  for(str name <- construct1Names)
  {
    if(name in construct2Names)
    {
      return true;
    }
  }

  return false;
}

// Function that returns the names for a given construct
// INPUT  : @construct - the construct where the names need to be determined for
// OUTPUT : A set of process names that occur in the construct
set[str] getNamesForChoreographyConstruct(AChoreographyConstruct construct)
{
  switch(construct)
  {
    case AIfStatement(AExpression expression, AChoreographyConstruct _, AChoreographyConstruct _):
      return getExpressionNames(expression);
    case AWhileStatement(AExpression expression, AChoreographyConstruct _):
      return getExpressionNames(expression);
    case AProcessInteraction(AProcess sendingProcess, AExchangeValueDeclaration _, AProcess receivingProcess):
      return {sendingProcess.name, receivingProcess.name};
    case AVariableAssignment(str processName, str _, AExchangeValueDeclaration _, AAssignmentOperator _):
      return {processName};
    case AEmptyChoreographyConstruct():
      return {};
    default: throw "No matching choreography construct found!";
  }
}

// Function that evaluates an expression and returns all the process names
// INPUT  : @expression - the expression that needs evaluation
// OUTPUT : The names in the expression
set[str] getExpressionNames(AExpression expression)
{
  switch(expression)
  {
    case AExpressionConjunction(AExpression expr1, AExpression expr2):
      return getExpressionNames(expr1) + getExpressionNames(expr2);
    case AExpressionDisjunction(AExpression expr1, AExpression expr2):
      return getExpressionNames(expr1) + getExpressionNames(expr2);
    case AEqualExpression(AExpression val1, AExpression val2):
      return getExpressionName(val1) + getExpressionName(val2);
    case ANotEqualExpression(AExpression val1, AExpression val2):
      return getExpressionName(val1) + getExpressionName(val2);
  }

  return {};
}

// Function that returnst the name that may exist in an expression
// INPUT  : @expression the expression where the value needs to be retrieved from
// OUTPUT : A set of names that occur in the expression
set[str] getExpressionName(AExpression expression)
{
  switch(expression)
  {
    case AIntExpression(int _):
      return {};
    case ABoolExpression(bool _):
      return {};
    case AProcessVariableDeclarationExpression(AProcess process): 
      return {process.name};
  }
  
  return {};
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

// Function that indicates whether a construct is an terminating one
// INPUT  : @chorConstruct - the construct that needs to be checked
// OUTPUT : A flag indicating if the construct is terminating
bool isTerminatingChorConstruct(AChoreographyConstruct chorConstruct)
{
  switch(chorConstruct)
  {
    case AProcessInteraction(AProcess _, AExchangeValueDeclaration _, AProcess _):
      return false;
    case AChoreographyComposition(AChoreographyConstruct _, AChoreographyConstruct _):
      return false;
    case AVariableAssignment(str _, str _, AExchangeValueDeclaration _, AAssignmentOperator _):
      return false;
    case AIfStatement(AExpression _, AChoreographyConstruct _, AChoreographyConstruct _):
      return false;
    case AWhileStatement(AExpression _, AChoreographyConstruct _):
      return false; 
    case AEmptyChoreographyConstruct():
      return true;
    default: throw "The chor construct is not recognized!: <chorConstruct>";
  }
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