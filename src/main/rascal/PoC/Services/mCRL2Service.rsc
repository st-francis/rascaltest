module PoC::Services::mCRL2Service

import IO;
import util::ShellExec;
import PoC::Machines::AldebaranMachine;

import Boolean;
import String;

str defaultFileLocation = "M:/RascalTestNew/rascaltest/src/main/";
str defaultmCRL2BinLocation = "M:/Programs/mCRL2/bin/";
str defaultmCRL2Location = "M:/Programs/mCRL2/bin";

bool IsAldebaranMachineDeadlockFree(str labels, AldebaranMachine machine, str fileName)
{
  println("Checking!");

  cleanFiles(fileName);

  CreateAldabaranLTSFiles(labels, machine, fileName);

  ShowLTS(fileName, ".aut");
 
  CreateLPSFileForAldabaranLTSFiles("<fileName>.aut", "<fileName>.mcrl2", "<fileName>.lps");

  CreateLTSFileForLPS("<fileName>.lps", "<fileName>.lts");
  
  CreatePBESForLTS(fileName);

  bool isDeadlockFree = SolvePBES(fileName);

  return isDeadlockFree;
}

void cleanFiles(str fileName)
{
  remove(|file:///<defaultFileLocation><fileName>.lps_dlk_0.trc|);
  remove(|file:///<defaultFileLocation><fileName>.lps_dlk_0.txt|);
  remove(|file:///<defaultFileLocation><fileName>.lps_act_0_FinalT.trc|);
  remove(|file:///<defaultFileLocation><fileName>.lps_act_0_FinalT.txt|);
  remove(|file:///<defaultFileLocation>counter-example.lts|);
}

void checkFinalTau(str fileName)
{
  if(!exists(|file:///<defaultFileLocation><fileName>.lps_act_0_FinalT.trc|))
  {
    println("Livelock has occured!");
  }
}

bool isLTSDeadlockFree(str fileName)
{
  if(exists(|file:///<defaultFileLocation><fileName>.lps_dlk_0.trc|))
  {
    println("Deadlock has been detected:");
    println(GetTraceString("<fileName>.lps_dlk_0.trc", fileName));
    return false;
  }
  else
  {
    println("The system is deadlock-free!");
    return true;  
  }
}


bool doLTSIncludeEachOther(str lts1Name, str lts2Name)
{
  bool lts1inlts2 = false;
  bool lts2inlts1 = false;

  lts1inlts2 = isLTSIncluded(lts1Name, lts2Name);
  if(!lts1inlts2)
  {
    println("Showing counter example LTS");
    ShowLTS("counter-example", ".lts");
    return false;
  }

  lts2inlts1 = isLTSIncluded(lts2Name, lts1Name);
  if(!lts1inlts2)
  {
    println("Showing counter example LTS");
    ShowLTS("counter-example", ".lts");
    return false;
  }
  println("LTSs include each other!");
  return true;
}

bool isLTSIncluded(str lts1Name, str lts2Name)
{
    list[str] commArgs = ["--counter-example", 
                          "--counter-example-file=<defaultFileLocation>counter-example.lts",
                          "--preorder=weak-trace-ac", 
                          "--tau=T,FinalT", 
                          "<defaultFileLocation><lts1Name>.aut",
                          "<defaultFileLocation><lts2Name>.aut"];
    str res = execute("ltscompare", commArgs);

    return fromString(trim(res));
}

bool areChoreographyMachineAndProcessMachineEquivalent(str choreoMachineFileName, str processMachineFileName)
{
  println("<choreoMachineFileName> <processMachineFileName>");
  list[str] commArgs = ["--equivalence=weak-trace", "--tau=T,FinalT", "<defaultFileLocation><choreoMachineFileName>.aut", "<defaultFileLocation><processMachineFileName>.aut"];
  str err = execute("ltscompare", commArgs);  
  
  println("result equiv. check: <err>");

  bool areEquivalent = fromString(trim(err));  
  if(areEquivalent)
  {
    println("The systems are equivalent!");
  }
  else
  {
    println("The systems are not equivalent!");
  }

  return areEquivalent;
}


void CreateAldabaranLTSFiles(str labels, AldebaranMachine machine, str fileName)
{
  println("Creating aldabaran files!");

  loc aldebaranFileName = |file:///<defaultFileLocation><fileName>.aut|;
  loc dataAndActionFileName = |file:///<defaultFileLocation><fileName>.mcrl2|;

  remove(aldebaranFileName);
  remove(dataAndActionFileName);
  
  writeFile(aldebaranFileName, GetMachineAsFileString(machine));
  writeFile(dataAndActionFileName, labels);
}

void CreateLPSFileForAldabaranLTSFiles(str inputAldabaranFilename, str inputDataAndActionFileName, str outputFilename)
{
  println("Creating LPS files!");

  remove(|file:///<defaultFileLocation><outputFilename>|);

  list[str] commArgs = ["--data=<defaultFileLocation><inputDataAndActionFileName>", "<defaultFileLocation><inputAldabaranFilename>", "<defaultFileLocation><outputFilename>"];
  execute("lts2lps", commArgs);
}

void CreateLTSFileForLPS(str inputLPSFileName, str outputLTSFileName)
{
  println("Creating LTS files for LPS!");
  remove(|file:///<defaultFileLocation><outputLTSFileName>|);
  commArgs = ["--deadlock", "--action=FinalT","--trace","--verbose","<defaultFileLocation><inputLPSFileName>", "<defaultFileLocation><outputLTSFileName>"];
  println("Executing LPS2LTS!");
  try execute("lps2lts", commArgs);
  catch: println(); 
}

void CreatePBESForLTS(str fileName)
{
  str outputFileName = "<fileName>.pbes";
  println("Creating PBES for LTS!");
  remove(|file:///<defaultFileLocation><outputFileName>|);
  commArgs = ["--counter-example",                                 //Counter-example flag 
              "--data=<defaultFileLocation><fileName>.mcrl2",      //data and actions specification
              "--formula=<defaultFileLocation>isDeadlockFree",     //formula file reference
              "<defaultFileLocation><fileName>.lts",               //input file name
              "<defaultFileLocation><outputFileName>"];            //output file name 
  execute("lts2pbes", commArgs);
}

bool SolvePBES(str fileName)
{
  println("Solving PBES");
  str evidenceFile = "<fileName>.pbes.evidence.lts";
  remove(|file:///<defaultFileLocation><evidenceFile>|);
  commArgs = ["--file=<defaultFileLocation><fileName>.lts",
              "<defaultFileLocation><fileName>.pbes"];

  str res = execute("pbessolve", commArgs);
  println(res);
  return fromString(trim(res));
}

void CreateReadableTraceFile(str inputTraceFileName, str outputTraceFileName)
{
  remove(|file:///<defaultFileLocation><outputTraceFileName>|);

  commArgs = ["<defaultFileLocation><inputTraceFileName>", "<defaultFileLocation><outputTraceFileName>"];
  execute("tracepp", commArgs);
}

void ShowLTS(str inputFileName, str format)
{
    commArgs = ["<defaultFileLocation><inputFileName><format>"];
    createProcess(|file:///<defaultmCRL2BinLocation><"ltsgraph">|, workingDir=|file:///<defaultmCRL2Location>|, args=commArgs);
}

str GetTraceString(str inputTraceFileName, str fileName)
{
  CreateReadableTraceFile(inputTraceFileName, "<fileName>.lps_dlk_0.txt");
  return readFile(|file:///<defaultFileLocation><fileName>.lps_dlk_0.txt|);
}

str execute(str appName, list[str] appArguments)
{ 
  println(appArguments);
  return exec(|file:///<defaultmCRL2BinLocation><appName>|, workingDir=|file:///<defaultmCRL2Location>|, args=appArguments);
}