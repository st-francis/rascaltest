module PoC::Projectors::ChoreographyProjector

import PoC::ChoreoLanguage::ChoreoConcrete;
import PoC::Utils::Util;

import List;
import Set;
import IO;
import String;

data ProcessFileData = ProcessFileData(loc fileLocation, list[str] fileLines);

map[str processName, ProcessFileData fileData] processFiles = ();
set[str] uniqueProcessNames = {};
int initialFileLines = 2;

list[loc] projectChoreographyToProcessSpecifications(ChoreographyConstruct baseConstruct)
{
  processFiles = ();
  uniqueProcessNames = {};

  // step 1 determine which files need to be created
  uniqueProcessNames = findUniqueProcessNamesForChoreographyConstruct(baseConstruct);

  // step 2 create the files
  createProcessFiles(uniqueProcessNames);
  
  // step 3 fill the files with the required lines
  fillProcessFiles(baseConstruct, false);

  // step 4 finalize file data;
  finalizeProcessFiles();

  // step 5 save files
  saveProcessFiles();

  return [processFiles[processName].fileLocation | str processName <- processFiles];
}

void fillProcessFiles(ChoreographyConstruct choreographyConstruct, bool addSemicolon)
{
  switch(choreographyConstruct)
    {
      case (ChoreographyConstruct) `<ChoreographyConstruct firstConstruct>;<ChoreographyConstruct nextConstruct>`:
        addComposition(firstConstruct, nextConstruct);
      case (ChoreographyConstruct) `<ProcessName processName>.<Variable variableName><AssignmentOperator assignmentOperator><VariableValue variableValue>:<Type variableType>`:
        addAssignment(processName, variableName, variableValue, variableType, assignmentOperator, addSemicolon);
      case (ChoreographyConstruct) `<ProcessVariableCall variableCallSen><ExchangeValueDeclaration variableDeclaration>-\><ProcessVariableCall variableCallRec>`:
        addLinesForInteraction("<variableCallSen.name>", "<variableCallRec.name>", "<variableCallSen.variableName>", "<variableCallRec.variableName>", "<variableDeclaration.variableValue>", "<variableDeclaration.variableType>", addSemicolon);
      case (ChoreographyConstruct) `<ProcessName name><ExchangeValueDeclaration variableDeclaration>-\><ProcessVariableCall variableCallRec>`:
        addLinesForInteraction("<name>", "<variableCallRec.name>", "", "<variableCallRec.variableName>", "<variableDeclaration.variableValue>", "<variableDeclaration.variableType>", addSemicolon);
      case (ChoreographyConstruct) `if(<Expression expression>){<ChoreographyConstruct thenConstruct>}else{<ChoreographyConstruct elseConstruct>}`:
        addLinesForIfStatement(expression, thenConstruct, elseConstruct, addSemicolon);
      case (ChoreographyConstruct) `while(<Expression expression>){<ChoreographyConstruct whileConstruct>}`:
        addLinesForWhileStatement(expression, whileConstruct, addSemicolon);
      default: throw "no matching construct found!";
    }
}

void addLinesForWhileStatement(Expression expression, ChoreographyConstruct whileConstruct, bool addSemicolon)
{
  map[str, list[Expression]] expressionsPerProcess = getExpressionsPerProcess(expression);
  // add expressions to files 
  for(str processName <- expressionsPerProcess)
  {
    str line = "\u0020\u0020while(";
    int count = 1;
    for(Expression expr <- expressionsPerProcess[processName])
    {
      line += getExpressionString(expr);
      if(count < size(expressionsPerProcess[processName]))
      {
        line += "&&";
        count = count + 1;
      }
    }
    line += "){";
    appendLine(processName, line, false);
  }

  // add the while construct;
  fillProcessFiles(whileConstruct, false);
  for(str processName <- expressionsPerProcess)
  {
    appendLine(processName, "\u0020\u0020}",addSemicolon);
  }
}

map[str, list[Expression]] getExpressionsPerProcess(Expression expression)
{
   // Get a list of all the expressions
  list[Expression] expressionList = getExpressionListForExpressions([expression]);
  
  // Get a map with all the expression belonging to a particular process
  map[str, list[Expression]] expressionsPerProcess = ();
  for(Expression expr <- expressionList)
  {
    set[str] uniqueNames = findUniqueProcessNamesForExpression(expr);
    str first = getFirstFrom(uniqueNames);
    expressionsPerProcess += (first: [expr]); 
  }

  return expressionsPerProcess;
}

void addLinesForIfStatement(Expression expression, ChoreographyConstruct thenConstruct, ChoreographyConstruct elseConstruct, bool addSemicolon)
{  
  // Get a map with all the expression belonging to a particular process
  map[str, list[Expression]] expressionsPerProcess = getExpressionsPerProcess(expression);

  // add expressions to files 
  for(str processName <- expressionsPerProcess)
  {
    str line = "\u0020\u0020if(";
    int count = 1;
    for(Expression expr <- expressionsPerProcess[processName])
    {
      line += getExpressionString(expr);
      if(count < size(expressionsPerProcess[processName]))
      {
        line += "&&";
        count = count + 1;
      }
    }
    line += "){";
    appendLine(processName, line, false);
  }
  // add the then construct;
  fillProcessFiles(thenConstruct, false);
  for(str processName <- expressionsPerProcess)
  {
    appendLine(processName, "\u0020\u0020}else{",false);
  }

  // add the else construct
  fillProcessFiles(elseConstruct, false);
  for(str processName <- expressionsPerProcess)
  {
    appendLine(processName, "\u0020\u0020}", addSemicolon);
  }
}

str getExpressionString(Expression expression)
{
  switch(expression)
  {
    case (Expression) `<Int intValue>`:
              return "<intValue>";
    case (Expression) `<Bool boolValue>`:
              return "<boolValue>";
    case (Expression) `<ProcessVariableCall processVariableCall>`:
              return "<processVariableCall.name>.<processVariableCall.variableName>";
    case (Expression) `<Expression expression1>==<Expression expression2>`:
              return "<getExpressionString(expression1)>==<getExpressionString(expression2)>";
    case (Expression) `<Expression expression1>!=<Expression expression2>`:
              return "<getExpressionString(expression1)>!=<getExpressionString(expression2)>";

    default: throw "no matching construct found!";
  }
}

list[Expression] getExpressionListForExpressions(list[Expression] expressions)
{
  list[Expression] expressionList = [];

  for(Expression expr <- expressions)
  {
    switch(expr)
    {
      case (Expression) `<Expression expression1>==<Expression expression2>`:
                expressionList += expr;
      case (Expression) `<Expression expression1>!=<Expression expression2>`:
                expressionList += expr;
      case (Expression) `<Expression expression1>&&<Expression expression2>`:
                expressionList += getExpressionListForExpressions([expression1, expression2]);
      case (Expression) `<Expression expression1>||<Expression expression2>`:
                expressionList += getExpressionListForExpressions([expression1, expression2]);
      default: throw "no matching construct found!";
    } 
  }

  return expressionList;
}

void addAssignment(ProcessName processName, Variable variableName, VariableValue variableValue, Type variableType, AssignmentOperator assignmentOperator, bool addSemicolon)
{
  str operatorStr = "";
  switch(assignmentOperator)
  {
    case (AssignmentOperator) `:=`:
      operatorStr = ":=";
    case (AssignmentOperator) `+=`:
      operatorStr = "+=";
  }

  addAssignmentLine("<processName>", "<variableName>", "<variableValue>", "<variableType>", operatorStr, addSemicolon);

  for(str uniqueName <- uniqueProcessNames)
  {
    if(uniqueName != "<processName>")
    {
      addTauLine(uniqueName, addSemicolon);
    }
  }
}

void addComposition(ChoreographyConstruct firstConstruct, ChoreographyConstruct nextConstruct)
{
  fillProcessFiles(firstConstruct, true);
  fillProcessFiles(nextConstruct, false);
}

void addLinesForInteraction(str sendingProcessName, str receivingProcessName, str varFromName, str varToName, str val, str valType, bool addSemicolon)
{
  addSendingInteractionLine(sendingProcessName, receivingProcessName, varFromName, val, valType, addSemicolon);
  addReceivingInteractionLine(receivingProcessName, sendingProcessName, varToName, addSemicolon);

  for(str processName <- uniqueProcessNames)
  {
    if(processName != sendingProcessName && processName != receivingProcessName)
    {
      addTauLine(processName, addSemicolon);
    }
  }
}

void addAssignmentLine(str processName, str variableName, str variableValue, str variableType, str assignmentOperator, bool addSemicolon)
{
  str assignmentLine = "\u0020\u0020<variableName> <assignmentOperator> <variableValue>:<variableType>";
  appendLine(processName, assignmentLine, addSemicolon);
}

void addTauLine(str processName, bool addSemicolon) {
    str tauLine = "\u0020\u0020TAU";
    appendLine(processName, tauLine, addSemicolon);
}

void addSendingInteractionLine(str sendingProcessName, str receivingProcessName, str varFromName, str val, str valType, bool addSemicolon)
{
    str interactionLine = "\u0020\u0020<receivingProcessName>!<varFromName>(<val>:<valType>)";
    appendLine(sendingProcessName, interactionLine, addSemicolon);
}

void addReceivingInteractionLine(str receivingProcessName, str sendingProcessName, str varToName, bool addSemicolon)
{
    str interactionLine = "\u0020\u0020<sendingProcessName>?<varToName>";
    appendLine(receivingProcessName, interactionLine, addSemicolon);
}

void appendLine(str processName, str line,  bool addSemicolon) {
    processFiles[processName].fileLines += ["\n" + line];

    if(addSemicolon)
    {
      processFiles[processName].fileLines += [";"];
    }
}

void createProcessFiles(set[str] uniqueProcessNames)
{
  for(str processName <- uniqueProcessNames)
  {
    loc location =  |file:///C:/Users/marco/RascalTest/rascaltest/src/main/<processName>.proc|;
    list[str] firstLines = ["process <processName> \n", "\u007B \n"];
    processFiles[processName] = ProcessFileData(location, firstLines);
  }
}

void finalizeProcessFiles()
{
  for(str processName <- processFiles)
  {
    processFiles[processName].fileLines += ["\n\u007D"];
  }
}

void saveProcessFiles()
{
  for(str processName <- processFiles)
  {
    ProcessFileData processFileData = processFiles[processName];
    writeFile(processFileData.fileLocation, processFileData.fileLines);
  }
}