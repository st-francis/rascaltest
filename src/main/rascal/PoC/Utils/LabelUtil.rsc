module PoC::Utils::LabelUtil

import PoC::CommonLanguageElements::AssignmentOperator;
import PoC::CommonLanguageElements::ExchangeValueAbstract;

str getTauLabel()
{
    return "TAU";
}

str getAssignmentLabel(str processName, str variableName, AAssignmentOperator assignmentOperator, AExchangeValueDeclaration exchangeValueDeclaration)
{
    str assignmentOperatorLabel = "is";
    if(assignmentOperator is AAdditionOperator)
    {
      assignmentOperatorLabel = "plus_is";
    }
    return "<processName>_<variableName>_<assignmentOperatorLabel>_<exchangeValueDeclaration.val>_<exchangeValueDeclaration.valType>";
}