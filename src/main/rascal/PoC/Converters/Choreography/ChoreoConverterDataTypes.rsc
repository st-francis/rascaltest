module PoC::Converters::Choreography::ChoreoConverterDataTypes

import PoC::ChoreoLanguage::ChoreoAbstract;
import PoC::Machines::FiniteStateMachine;
import PoC::CommonLanguageElements::ExchangeValueAbstract;

// The TransitionContainer contains the relevant choreography construct and the related extra info 
data TransitionContainer = TransitionContainer(AChoreographyConstruct construct, TransitionContainerExtraInfo extraInfo);

// The extra info contains the required choreography that is required after the transition and the transitioninfo
data TransitionContainerExtraInfo = TransitionContainerExtraInfo(AChoreographyConstruct requiredChor, TransitionInfo transitionInfo, map[str, map[str, AExchangeValueDeclaration]] variableAssignments);
