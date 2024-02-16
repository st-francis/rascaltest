module PoC::CommonLanguageElements::ExpressionAbstract

import PoC::CommonLanguageElements::ProcessAbstract;

data AExpression
        = AExpressionConjunction(AExpression expr1, AExpression expr2)
        | AExpressionDisjunction(AExpression expr1, AExpression expr2)
        | AEqualExpression(AExpression val1, AExpression val2)
        | ANotEqualExpression(AExpression val1, AExpression val2)
        | AProcessVariableDeclarationExpression(AProcess process)
        | AIntExpression(int intValue)
        | ABoolExpression(bool boolValue)
        | AEmptyExpression()
        ;