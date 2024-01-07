module PoC::Classifiers::ChoreographyClassifier 

import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::Classifiers::ChoreographyValueClassifier;
import PoC::Classifiers::ConditionClassifier;

bool classifyChoreography(ChoreographyConstruct concreteChoreography, AChoreography abstractChoreography)
{
  bool valuesWellFormed = classifyChoreographyConstructValues(abstractChoreography);
  bool conditionsWellFormed = everyProcessOccursInExpression(concreteChoreography);

  return valuesWellFormed && conditionsWellFormed;
}