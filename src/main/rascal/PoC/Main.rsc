module PoC::Main

import PoC::Facades::ChoreographyProcessorFacade;
import IO;

void main(list[str] args)
{
  cleanAndCreateResultsFile();
  processChoreography(args[0], "DEFAULT_FILE_LOCATION");
}

void cleanAndCreateResultsFile(str default_file_location)
{
  try 
    remove(|file:///<default_file_location>/rascal/PoC/bin/results.txt|);
  catch:
    println("Failed to remove file");

  writeFile(|file:///<default_file_location>/rascal/PoC/bin/results.txt|, "");
}
