module PoC::Machines::AldebaranMachine

import PoC::Machines::AbstractStateMachine;
import List;
import Set;
import IO;
import String;

data AldebaranMachine = AldebaranMachine(str initalState, int nuOfStates, list[Transition] transitions);

str GetMachineAsFileString(AldebaranMachine aldebaranMachine)
{
  str content = "des (<aldebaranMachine.initalState>, <size(aldebaranMachine.transitions)>, <aldebaranMachine.nuOfStates>)\n";
  for(Transition transition <- aldebaranMachine.transitions)
  {   
      str argumentStr = getArgumentsStr(transition.transitionLabel.arguments);
      content += "(<transition.startingState.nr>,\"<transition.transitionLabel.description><argumentStr>\",<transition.finalState.nr>)\n";
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