module PoC::Machines::AldebaranMachine

import PoC::Machines::AbstractStateMachine;
import List;
import Set;
import String;

data AldebaranMachine = AldebaranMachine(str initalState, int nuOfStates, set[TransitionInfo] transitions);

str GetMachineAsFileString(AldebaranMachine aldebaranMachine)
{
  str content = "des (<aldebaranMachine.initalState>, <size(aldebaranMachine.transitions)>, <aldebaranMachine.nuOfStates>)\n";
  for(TransitionInfo transitionInfo <- aldebaranMachine.transitions)
  {   
      str argumentStr = getArgumentsStr(transitionInfo.transitionLabel.arguments);
      content += "(<transitionInfo.prevStateNo>,\"<transitionInfo.transitionLabel.description><argumentStr>\",<transitionInfo.nextStateNo>)\n";
  }
  
  return content;
}

str getArgumentsStr(list[tuple[str, str]] arguments)
{
    str argumentStr = "";
    if(!isEmpty(arguments))
    {
        int count = 0;
        argumentStr += "(";
            
        for(tuple[str, str] argument <- arguments)
        {
            count = count + 1;
            argumentStr += argument[1];

            if(count < size(arguments))
            {
                argumentStr += ",";
            }
        }

        argumentStr += ")";
    }

    return argumentStr;
}

str GetDataAndActionsString(set[str] labels) {
    str content = "act\n";
    
    for (str label <- labels) {
        content += label;
        if (!endsWith(label, ";\n")) {
            content += ";\n";
        }
    }

    return content;
}