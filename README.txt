To use the proof-of-concept, the following software is required:
• Rascal MPL (v0.9.1 or higher)
• mCRL2 (V202206.1 or higher)

The file locations that should be specified are listed below:

- CHOREOGRAPHY_LOCATION (main.rsc): The location of the choreography file
- DEFAULT_FILE_LOCATION (main.rsc): The location where the process files and traces should be stored after they are generated
- MCRL2_BIN_LOCATION (mcrl2Service.rsc): The location of the bin folder of mCRL2
- MCRL2_LOCATION (mcrl2Service.rsc): The location of mCRL2

Then, to use the proof-of-concept using the following steps:
1. Provide a choreography that adheres to the grammar defined in ChoreoConcrete.rsc.
2. Make sure that CHOREOGRAPHY_LOCATION points to the choreography
3. To start the program execute the main() function from main.rsc.
4. The output will now show if the choreography is deadlock free
5. The process specifications will be created (called processname.proc) and stored at DEFAULT_FILE
6. The output will show is the combined process LTS is equivalent to the choreography

If the following three conditions are successful then the execution is successful:
1. The choreography should be deadlock-free (read from output)
2. A file should be created for each process
3. The choreography should be equivalent to the combined process behavior (read from output)
