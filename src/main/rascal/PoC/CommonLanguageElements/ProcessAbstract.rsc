module PoC::CommonLanguageElements::ProcessAbstract

data AProcess 
        = AProcess(str name, str variableName)
        | AEmptyProcess()
        ;