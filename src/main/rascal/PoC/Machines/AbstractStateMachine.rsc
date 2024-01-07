module PoC::Machines::AbstractStateMachine

import List;
import IO;
import Set;

data State = State(str nr);
data Label = Label(str description, list[tuple[str, str]] arguments);
data Transition = Transition(State startingState, Label transitionLabel, State finalState);
data AbstractStateMachine = AbstractStateMachine(str machineName, str initialStateNr, list[Transition] stateTransitions);

set[str] getLabelActions(AbstractStateMachine stateMachine) {
    return {getmCRL2ActionLabel(transition) | Transition transition <- stateMachine.stateTransitions};
}

int getUniqueStates(list[Transition] stateTransitions){
    return size({transition.startingState, transition.finalState| Transition transition <- stateTransitions});
}

str getmCRL2ActionLabel(Transition transition)
{
    str label = "";
    label += transition.transitionLabel.description;
        
    str argumentStr = getArgumentsStr(transition.transitionLabel.arguments);

    return "<label><argumentStr>";
}

str getArgumentsStr(list[tuple[str,str]] arguments)
{
    str argumentStr = "";
    int count = 0;
    if(!isEmpty(arguments))
    {
        argumentStr += ": ";
        for(tuple[str,str] argument <- arguments)
        {
            count = count + 1;
            argumentStr += argument[0];

            if(count < size(arguments))
            {
                argumentStr += " # ";
            }
        }

        argumentStr += ";\n";
    }

    return argumentStr;
}
