# fuzzy.ai-cmdln

This is the command-line client for fuzzy.ai API. If you install it, you can
do a few things with fuzzy.ai.

Note that this is just the command-line tool; for calling something from
your own code, try the [fuzzy.ai SDK](https://github.com/fuzzy-ai/nodejs).

# License

Copyright 2016 Fuzzy.ai <legal@fuzzy.ai>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

# Installation

To install this program, you need [node.js](http://nodejs.org/) and
[npm](http://npmjs.org/).

You can then just use this command to install the program:

```shell
npm install -g fuzzy.ai-cmdln
```

This will make the `fuzzy.ai` command available on your system.

# Commands

You can do various things with the command-line tool. At any time, you can
get the up-to-date usage info by using this call:

```
fuzzy.ai -h
```

That should output all the commands you can call. Here's more information
on each one.

## fuzzy.ai create <agentfile>

Create a new agent from a [JSON](http://www.json.org/) or
[CSON](https://github.com/bevry/cson) file. This will create a new
agent based on a single agent that is the contents of the file. (See
https://fuzzy.ai/docs/rest/agent for what should go in that file.)

If the filename ends with ".json", it'll be treated as JSON, and if it ends with
".cson", it'll be treated as CSON.

The agent will be created on the server, and the new version (including
timestamps and ID) will go to the output. If you use the `-q` option, only the
new agent ID will be output.

## fuzzy.ai read <agent>

Fetches an agent from the server to output. Use the name or the ID of the agent.
If the name has spaces, wrap it in quotes (""). Always returns JSON.

If you have more than one agent with the same name, this will give an error and
show you all the IDs with that same name.

## fuzzy.ai update <agent> <agentfile>

Updates an agent by name or ID given the contents of the agent file. The file
can be JSON or CSON, as with `fuzzy.ai create`, and the new agent will be sent
to the output.

## fuzzy.ai delete <agent>

Deletes an agent by name or ID. There's no undo, so use this carefully!

## fuzzy.ai batch <agent> <csvfile>

Evaluate every line in this [CSV](https://en.wikipedia.org/wiki/Comma-separated_values)
file as an input set, and output the results as a CSV file including the inputs
and outputs. You can use the agent name or ID.

The first line should be headers with the expected input names. Any
columns in the CSV file that aren't used by the agent will be passed through to
the output. So if you have an agent that takes `input1` and `input2` and outputs
`output1`, and your input file looks like this:

```csv
id,input1,input2
204283a0-5820-11e6-968b-c8f73398600c,3.5,80.7
```

Then the output will look like this:

```csv
id,input1,input2,output1
204283a0-5820-11e6-968b-c8f73398600c,3.5,80.7,17.0
```

## fuzzy.ai list

List all the agents in your account. Outputs a CSV file with two columns,
`id` and `name`, for the ID and name of the agent respectively.

```csv
id,name
4ZUHJOVGAW6IPMVTHHSXZOF77Q,An agent name
```

# Options

You can use various options to change how the program behaves.

## -k, --key

This is the API key that the command-line tool will use for the Fuzzy.ai API.
You can find your API key on the [fuzzy.ai dashboard](https://fuzzy.ai/) or in your [fuzzy.ai settings](https://fuzzy.ai/settings).

It is **required**. If you use the command-line tool with the same key very often,
you should consider putting it into a configuration file or environment variable (see below).

## -r, --root

Root of the API server. Unless you are testing this particular program with a
Fuzzy.ai mock, don't change this value.

## -o, --output

The output file to write to. Most of the commands have some output; this will
put the output into this output file.

## -q, --quiet

Output less data. Only kind of useful.

## -b, --batch-size

When doing a bunch of evaluations with `fuzzy.ai batch`, this sets the number
of evaluations to send at once. Defaults to 128, which is a lot of evaluations.

## -c, --config-file

Path to the config file (see below).

## -h, --help

Output help information. An abbreviated version of this document.

# Configuration file

You can use a configuration file if you use the same arguments, like `-k`, over
and over and over. It's a JSON file, by default in your home directory at
`$HOME/.fuzzy.ai.json`, but if you want you can move it somewhere else. It
contains a JSON object with one property per option:

```json
{
    "key": "your API key here"
}
```

# Environment variables

You can also define environment variables for the default values of options. They
are all prefixed with `FUZZY_AI_`, so these are the variables you can set:

* FUZZY_AI_KEY
* FUZZY_AI_ROOT
* FUZZY_AI_OUTPUT
* FUZZY_AI_QUIET
* FUZZY_AI_BATCH_SIZE
* FUZZY_AI_CONFIG_FILE
