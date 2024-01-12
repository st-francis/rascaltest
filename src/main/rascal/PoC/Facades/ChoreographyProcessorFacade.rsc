module PoC::Facades::ChoreographyProcessorFacade

import PoC::Converters::ChoreoASTToTransitionInfoConverter;
import PoC::Converters::ChoreoProcessASTsToTransitionInfoConverter;

import PoC::Machines::AbstractStateMachine;
import PoC::Machines::AldebaranMachine;

import PoC::Services::mCRL2Service;

import PoC::Parsers::ChoreographyASTParser;
import PoC::Parsers::ProcessASTParser;

import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::ChoreoProcessLanguage::ChoreoProcessConcrete;
import PoC::ChoreoProcessLanguage::ChoreoProcessAbstract;

import PoC::Projectors::ChoreographyProjector;

import PoC::Classifiers::ChoreographyClassifier; 

import ParseTree;

void processChoreography(str choreographyFileName)
{
  // (Action A) Parsing choreography file to a AST
  start[ConcreteChoreography] choreo = parseChoreographyFile(choreographyFileName);
  AChoreography abstractChoreography = parseChoreographyToAST(choreo.top);
  
  // Checking well-formedness
  if (!isChoreographyWellFormed(choreo.top.content.choreographyConstruct, abstractChoreography)) {
      throw "The choreography is not well-formed!";
  }

  // (Action B) Convert to ASM
  AbstractStateMachine machine  = convertChoreoASTToASM(abstractChoreography.name, abstractChoreography.choreographyConstruct);

  // (Action C) Check deadlock-freedom
  bool isDeadockFreeChoreo      = isAbstractStateMachineDeadlockFree(machine, "test");

  // (Action D) Parse process files based on choreography AST
  list[loc] processFiles = projectChoreographyToProcessSpecifications(choreo.top.content.choreographyConstruct);
  list[AChoreographyProcess] abstractProcesses = parseProcessFiles(processFiles);

  // (Action E) Convert to ASM
  AbstractStateMachine processMachine  = convertChoreoProcessASTsToASM(abstractChoreography.name, abstractProcesses);

  // Check deadlock-freedom
  bool isDeadockFreeProcess = isAbstractStateMachineDeadlockFree(processMachine, "processTest");

  // (Action F) Check if machines are equivalent
  bool areMachinesEquivalent = areChoreographyMachineAndProcessMachineEquivalent("test","processTest");
}

list[AChoreographyProcess] parseProcessFiles(list[loc] processFiles) {
    list[AChoreographyProcess] processes = [];
    for (loc processLocation <- processFiles) {
        ChoreographyProcess choreoProcess = parse(#start[ChoreographyProcess], processLocation).top;
        processes += parseChoreographyProcess(choreoProcess);
    }
    return processes;
}

bool isChoreographyWellFormed(ChoreographyConstruct concreteConstruct, AChoreography abstractChoreography) {
    return classifyChoreography(concreteConstruct, abstractChoreography);
}

start[ConcreteChoreography] parseChoreographyFile(str fileName) {
    return parse(#start[ConcreteChoreography], |file:///<fileName>|);
}

bool isAbstractStateMachineDeadlockFree(AbstractStateMachine abstractStateMachine, str fileName)
{
  AldebaranMachine aldMachine = AldebaranMachine(abstractStateMachine.initialStateNr, getUniqueStates(abstractStateMachine.stateTransitions), abstractStateMachine.stateTransitions);
  set[str] processActions     = getLabelActions(abstractStateMachine);
  str processLabels           = GetDataAndActionsString(processActions);

  return IsAldebaranMachineDeadlockFree(processLabels, aldMachine, fileName);
}