module PoC::Utils::LabelUtil

import PoC::CommonLanguageElements::AssignmentOperator;
import PoC::CommonLanguageElements::ExchangeValueAbstract;

import PoC::Machines::AbstractStateMachine;

import String;

Label getTauLabel()
{
    return Label("T", []);
}

Label getAssignmentLabel(str processName, str variableName, AExchangeValueDeclaration exchangeValueDeclaration, AAssignmentOperator assignmentOperator)
{
    str assignmentOperatorLabel = "is";
    if(assignmentOperator is AAdditionOperator)
    {
      assignmentOperatorLabel = "plus_is";
    }
    return Label("<processName>_<variableName>_<assignmentOperatorLabel>_<exchangeValueDeclaration.val>_<exchangeValueDeclaration.valType>", []);
}

Label getInteractionLabel(str sender, str receiver, str varFrom, str varTo, AExchangeValueDeclaration exchangeValueDeclaration)
{
  bool hasSendingVar = !isEmpty(varFrom);
  if(hasSendingVar)
  {
    varFrom = "_<varFrom>"; 
  } 

  str actionLabel =  "<sender><varFrom>_to_<receiver>_<varTo>";

  list[tuple[str,str]] argument = [];
   if(!(exchangeValueDeclaration is AEmptyExchangeValueDeclaration))
   {
      argument = [<exchangeValueDeclaration.valType, exchangeValueDeclaration.val>];
   }
   
   return Label("<actionLabel>", argument);
}

Label getIfStatementEvaluationLabel(bool isThen)
{
  if(isThen)
  {
    return Label("THEN", []);
  }
  else
  {
    return Label("ELSE", []);
  }
}

Label getWhileStatementEvaluationLabel(bool reentering)
{
  if(reentering)
  {
    return Label("REENTERING", []);
  }
  else
  {
    return Label("EXITING", []);
  } 
}