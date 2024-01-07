module PoC::ChoreoProcessLanguage::ChoreoProcessAbstract

import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::CommonLanguageElements::ExpressionAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;
import PoC::CommonLanguageElements::AssignmentOperator;

data AChoreographyProcess = choreographyProcess(str name, list[AProcessConstruct] processConstructs);

data AProcessConstruct
      = AProcessInteractionInput(str varName, str outputProcessName)
      | AProcessInteractionOutput(str varName, AExchangeValueDeclaration exchangeValue, str outputProcessName)
      | AProcessSequentialComposition(AProcessConstruct construct1, AProcessConstruct construct2)
      | AProcessAssignment(str variableName, AExchangeValueDeclaration exchangeValue, AAssignmentOperator assignmentOperator)
      | AProcessIfStatement(AExpression expression, AProcessConstruct thenConstruct, AProcessConstruct elseConstruct)
      | AProcessWhileStatement(AExpression expression, AProcessConstruct whileConstruct)
      | ATauConstruct()
      | AEmptyProcessConstruct()
      ;