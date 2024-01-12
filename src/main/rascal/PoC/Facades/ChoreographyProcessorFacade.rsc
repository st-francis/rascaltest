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
import IO;
import List;
import Set;


void processChoreography(str choreographyFileName)
{
  //  Parsing choreography file to a AST
  start[ConcreteChoreography] choreo = parse(#start[ConcreteChoreography], |file:///<choreographyFileName>|);
  AChoreography abstractChoreography = parseChoreographyToAST(choreo.top);
  
  // Checking well-formedness
  bool isWellFormed = classifyChoreography(choreo.top.content.choreographyConstruct, abstractChoreography);
  if(!isWellFormed)
  {
    throw "the choreography is not well-formed!";
  }

  // Get the containers for the process interactions 
  AbstractStateMachine machine  = convertChoreoASTToASM(abstractChoreography.name, abstractChoreography.choreographyConstruct);
  bool isDeadockFree            = isAbstractStateMachineDeadlockFree(machine, "test");

  // Parsing the process files based on the choreography AST
  list[loc] processFiles = projectChoreographyToProcessSpecifications(choreo.top.content.choreographyConstruct);
  list[AChoreographyProcess] aprocesses = [];
  for(loc processLocation <- processFiles)
  {
    start[ChoreographyProcess] choreoProcess = parse(#start[ChoreographyProcess], processLocation);
    aprocesses += parseChoreographyProcess(choreoProcess.top);
  }

  // Get the process containers for the process files
  AbstractStateMachine processMachine  = convertChoreoProcessASTsToASM(abstractChoreography.name, aprocesses);
  bool isDeadockFree2                         = isAbstractStateMachineDeadlockFree(processMachine, "processTest");

  // Check if both of the files are equivalent;
  bool res = areChoreographyMachineAndProcessMachineEquivalent("test","processTest");
}

bool isAbstractStateMachineDeadlockFree(AbstractStateMachine abstractStateMachine, str fileName)
{
  AldebaranMachine aldMachine = AldebaranMachine(abstractStateMachine.initialStateNr, getUniqueStates(abstractStateMachine.stateTransitions), abstractStateMachine.stateTransitions);
  set[str] processActions     = getLabelActions(abstractStateMachine);
  str processLabels           = GetDataAndActionsString(processActions);

  return IsAldebaranMachineDeadlockFree(processLabels, aldMachine, fileName);
}