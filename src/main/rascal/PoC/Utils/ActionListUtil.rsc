module PoC::Utils::ActionListUtil


import PoC::Converters::Process::ChoreoProcessDataTypes;

import List;

bool isActionListEmpty(ProcessActionList actionList)
{
  for (str processName <- actionList.processInfo)
  {
    if (!isEmpty(actionList.processInfo[processName]))
    {
      return false;
    }
  }

  return true;
}

bool areActionListsEqual(ProcessActionList list1, ProcessActionList list2) {
    
    if(list1.varAssignments != list2.varAssignments)
    {
      return false;
    }

    for (str processName <- list1.processInfo) {
        if (list1.processInfo[processName] != list2.processInfo[processName]) {
            return false;
        }
    }
    return true;
}