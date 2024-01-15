module PoC::Facades::ChoreographyProcessorFacade

import PoC::Converters::Choreography::ChoreoASTToFSMConverter;
import PoC::Converters::Process::ChoreoProcessASTsToFSMConverter;

import PoC::Machines::FiniteStateMachine;
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

  // (Action B) Convert to FSM
  FiniteStateMachine machine  = convertChoreoASTToFSM(abstractChoreography.name, abstractChoreography.choreographyConstruct);

  // (Action C) Check deadlock-freedom
  bool isDeadockFreeChoreo      = isFiniteStateMachineDeadlockFree(machine, "test");

  // (Action D) Parse process files based on choreography AST
  list[loc] processFiles = projectChoreographyToProcessSpecifications(choreo.top.content.choreographyConstruct);
  list[AChoreographyProcess] abstractProcesses = parseProcessFiles(processFiles);

  // (Action E) Convert to FSM
  FiniteStateMachine processMachine  = convertChoreoProcessASTsToFSM(abstractChoreography.name, abstractProcesses);

  // Check deadlock-freedom
  bool isDeadockFreeProcess = isFiniteStateMachineDeadlockFree(processMachine, "processTest");

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

bool isFiniteStateMachineDeadlockFree(FiniteStateMachine finiteStateMachine, str fileName)
{
  AldebaranMachine aldMachine = AldebaranMachine(finiteStateMachine.initialStateNr, getUniqueStates(finiteStateMachine.stateTransitions), finiteStateMachine.stateTransitions);
  set[str] processActions     = getLabelActions(finiteStateMachine);
  str processLabels           = GetDataAndActionsString(processActions);

  return IsAldebaranMachineDeadlockFree(processLabels, aldMachine, fileName);
}