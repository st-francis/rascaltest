module PoC::Machines::FiniteStateMachine

import List;
import Set;

data State = State(str nr);
data Label = Label(str description, list[tuple[str, str]] arguments);
data TransitionInfo = TransitionInfo(int prevStateNo, int nextStateNo, Label transitionLabel, TransitionType transitionType);
data FiniteStateMachine = FiniteStateMachine(str machineName, str initialStateNr, set[TransitionInfo] stateTransitions);
data TransitionType = AssignmentTransition()
    | InteractionTransition(str sender, str receiver)
    | IfEvaluationTransition()
    | WhileEvaluationTransition()
    | TauTransition()
    ;

set[str] getLabelActions(FiniteStateMachine stateMachine) {
    return {getmCRL2ActionLabel(transition) | TransitionInfo transition <- stateMachine.stateTransitions};
}

int getUniqueStates(set[TransitionInfo] stateTransitions){
    return size({transitionInfo.prevStateNo, transitionInfo.nextStateNo| TransitionInfo transitionInfo <- stateTransitions});
}

str getmCRL2ActionLabel(TransitionInfo transitionInfo)
{
    str label = "";
    label += transitionInfo.transitionLabel.description;
        
    str argumentStr = getArgumentsStr(transitionInfo.transitionLabel.arguments);

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
