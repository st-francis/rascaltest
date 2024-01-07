module PoC::ChoreoLanguage::ChoreoAbstract

import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::ProcessAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;

data AChoreography = AChoreography(str name, AChoreographyConstruct  choreographyConstruct);

data AChoreographyConstruct 
        =  AChoreographyComposition(AChoreographyConstruct firstConstruct, AChoreographyConstruct secondConstruct)
        |  AProcessInteraction(AProcess sendingProcess, AExchangeValueDeclaration exchangeValueDeclaration, AProcess receivingProcess)
        |  AVariableAssignment(str processName, str variableName, AExchangeValueDeclaration exchangeValueDeclaration, AAssignmentOperator assignmentOperator)
        |  AIfStatement(AExpression expression, AChoreographyConstruct thenConstruct, AChoreographyConstruct elseConstruct)
        |  AWhileStatement(AExpression expression, AChoreographyConstruct whileConstruct)
        |  AEmptyChoreographyConstruct()
        ;

