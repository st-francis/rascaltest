module PoC::Converters::Process::ChoreoProcessDataTypes

import PoC::Machines::LabeledTransitionSystem;
import PoC::ChoreoProcessLanguage::ChoreoProcessAbstract;
import PoC::CommonLanguageElements::ExchangeValueAbstract;

data ProcessTransitionContainer   = ProcessTransitionContainer(ProcessActionList actionList, TransitionInfo transitionInfo) | EmptyProcessTransitionContainer();

data ProcessActionList  = ProcessActionList(map[str processName, list[AProcessConstruct] requiredProcessConstructs] processInfo, map[str, map[str, AExchangeValueDeclaration]] varAssignments) | EmptyActionList();

