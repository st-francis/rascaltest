module PoC::Facades::ChoreographyProcessorFacade

import PoC::Converters::Choreography::ChoreoASTToLTSConverter;
import PoC::Converters::Process::ChoreoProcessASTsToLTSConverter;

import PoC::Machines::LabeledTransitionSystem;
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
import IO;

void processChoreography(str choreographyFileName, str defaultFileLocation)
{
  str choreographyFile = "choreography";
  str processCompositionFile = "processComposition";

  // (Action A) Parsing choreography file to a AST
  start[ConcreteChoreography] choreo = parseChoreographyFile(choreographyFileName);
  AChoreography abstractChoreography = parseChoreographyToAST(choreo.top);
  println("Abstract choreography: <abstractChoreography>");
  
  // Checking well-formedness
  if (!isChoreographyWellFormed(choreo.top.content.choreographyConstruct, abstractChoreography)) {
      throw "The choreography is not well-formed!";
  }

  // (Action B) Convert to LTS
  LabeledTransitionSystem labeledTransitionSystem  = convertChoreoASTToLTS(abstractChoreography.name, abstractChoreography.choreographyConstruct);

  // (Action C) Check deadlock-freedom
  bool isDeadockFreeChoreo      = isLTSDeadlockFree(labeledTransitionSystem, choreographyFile, defaultFileLocation);

  // (Action D) Parse process files based on choreography AST
  list[loc] processFiles = projectChoreographyToProcessSpecifications(choreo.top.content.choreographyConstruct, defaultFileLocation);
  list[AChoreographyProcess] abstractProcesses = parseProcessFiles(processFiles);

  // (Action E) Convert to LTS
  LabeledTransitionSystem processLTS  = convertChoreoProcessASTsToLTS(abstractChoreography.name, abstractProcesses);

  // Check deadlock-freedom
  bool isDeadockFreeProcess = isLTSDeadlockFree(processLTS, processCompositionFile, defaultFileLocation);

  // (Action F) Check if machines are equivalent
  bool areMachinesEquivalent = doLTSIncludeEachOther(choreographyFile, processCompositionFile, defaultFileLocation);
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

bool isLTSDeadlockFree(LabeledTransitionSystem labeledTransitionSystem, str fileName, str defaultFileLocation)
{
  AldebaranMachine aldMachine = AldebaranMachine(labeledTransitionSystem.initialStateNr, getUniqueStates(labeledTransitionSystem.stateTransitions), labeledTransitionSystem.stateTransitions);
  set[str] processActions     = getLabelActions(labeledTransitionSystem);
  str processLabels           = GetDataAndActionsString(processActions);

  return IsAldebaranMachineDeadlockFree(processLabels, aldMachine, fileName, defaultFileLocation);
}