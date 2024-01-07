module PoC::CommonLanguageElements::ExchangeValueAbstract

data AExchangeValueDeclaration 
        = AExchangeValueDeclaration(str val, str valType)
        | AEmptyExchangeValueDeclaration()
        ;