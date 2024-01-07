module PoC::Parsers::AssignmentOperatorParser

import PoC::CommonLanguageElements::AssignmentOperator;
import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::ChoreoLanguage::ChoreoAbstract;

AAssignmentOperator parseAbstractAssignmentOperator(AssignmentOperator construct)
{
  switch(construct)
  {
    case (AssignmentOperator) `:=`:
      return AAssignmentOperator();
    case (AssignmentOperator) `+=`:
      return AAdditionOperator();
    default: throw "no matching construct found!";
  }
}