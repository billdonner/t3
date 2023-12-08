#  T3 - interact with the AI

version  0.3.3, ai = "chatgpt"

in progress

## Step 1 - ask the AI for "N" question blocks

The Pumper Tempates (system and user) are used to generate an array of JSON blocks about a series of topics from the AI. These blocks are organized by topic and passed to subsequent steps. 

The templates are essentially the system and user panel contents in the OpenAI playground.

The user panel can contain multiple sections separated by a line of five stars. Each section is executed as separate request to the AI.

The received blocks are augmented with a generated ID to allow for matching different outputs. 

The augmented blocks are written to PUMPER-LOG.JSON

## Step 2 - ask the AI to identify problems in generated data

The Validation Templates (system and user) are used for this phase. The output of this phase is a detailed JSON structure in VALIDATION-LOG.JSON describing the problems in the data; this data will drive utility programs outside this process.

## Step 3 - ask the AI to repair the data

The Repair Templates (system and user) are used for this phase.

For now, we will ignore the output from step 2 on the assumption the ai will itself identify  problems before repairing.

The output file is a stream of repaired JSON blocks.

## Step 4 - ask the AI to identify problems in generated data

Hopefully there will be no problems, otherwise we can go back to step 3 or just stop.
