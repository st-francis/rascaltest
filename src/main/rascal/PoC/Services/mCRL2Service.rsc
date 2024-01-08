module PoC::Services::mCRL2Service

import IO;
import util::ShellExec;
import PoC::Machines::AldebaranMachine;

import Boolean;
import String;

str defaultFileLocation = "C:/Users/marco/RascalTest/rascaltest/src/main/";
str defaultmCRL2Location = "M:/Programs/mCRL2/bin/";

bool IsAldebaranMachineDeadlockFree(str labels, AldebaranMachine machine, str fileName)
{
  println("Checking!");

  cleanTraceFiles(fileName);

  CreateAldabaranLTSFiles(labels, machine, fileName);
 
  CreateLPSFileForAldabaranLTSFiles("<fileName>.aut", "<fileName>.mcrl2", "<fileName>.lps");

  CreateLTSFileForLPS("<fileName>.lps", "<fileName>.lts");
  
  bool isDeadlockFree = isLTSDeadlockFree(fileName); 
  if(isDeadlockFree)
  {
    checkDivergence(fileName);
  }
  return isDeadlockFree;
}

void cleanTraceFiles(str fileName)
{
  remove(|file:///<defaultFileLocation><fileName>.lps_dlk_0.trc|);
  remove(|file:///<defaultFileLocation><fileName>.lps_divergence_0.trc|);
  remove(|file:///<defaultFileLocation><fileName>.lps_divergence_loop0.trc|);
}

void checkDivergence(str fileName)
{
  if(!exists(|file:///<defaultFileLocation><fileName>.lps_divergence_0.trc|))
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


bool areChoreographyMachineAndProcessMachineEquivalent(str choreoMachineFileName, str processMachineFileName)
{
  println("<choreoMachineFileName> <processMachineFileName>");
  list[str] commArgs = ["--equivalence=weak-trace", "--tau=T", "<defaultFileLocation><choreoMachineFileName>.aut", "<defaultFileLocation><processMachineFileName>.aut"];
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

  commArgs = ["--deadlock", "--divergence", "--trace", "--tau=T","--verbose","<defaultFileLocation><inputLPSFileName>", "<defaultFileLocation><outputLTSFileName>"];
  execute("lps2lts", commArgs);
}

void CreateReadableTraceFile(str inputTraceFileName, str outputTraceFileName)
{
  remove(|file:///<defaultFileLocation><outputTraceFileName>|);

  commArgs = ["<defaultFileLocation><inputTraceFileName>", "<defaultFileLocation><outputTraceFileName>"];
  execute("tracepp", commArgs);
}

str GetTraceString(str inputTraceFileName, str fileName)
{
  CreateReadableTraceFile(inputTraceFileName, "<fileName>.lps_dlk_0.txt");
  return readFile(|file:///<defaultFileLocation><fileName>.lps_dlk_0.txt|);
}

str execute(str appName, list[str] appArguments)
{
  return exec(|file:///<defaultmCRL2Location><appName>|, workingDir=|file:///M:/Programs/mCRL2/bin|, args=appArguments);
}