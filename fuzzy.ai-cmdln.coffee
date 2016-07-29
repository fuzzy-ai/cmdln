# fuzzy-ai.coffee
#
# Command-line tool for maintaining and using Fuzzy.ai agents
#
# Copyright 2016 Fuzzy.ai
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

path = require 'path'
fs = require 'fs'

FuzzyAIClient = require 'fuzzy.ai'
yargs = require 'yargs'
async = require 'async'
CSON = require 'cson'
_ = require 'lodash'

argv = yargs
  .usage('Usage: $0 <command> [options]')
  .demand(2)
  .command('create <agentfile>', 'Create a new agent from a file')
  .command('read <agent>', 'Export the agent')
  .command('update <agent> <agentfile>', 'Update the agent from the cson file')
  .command('delete <agent>', 'Delete the agent')
  .command('evaluate <agent>', 'Evaluate the inputs and show outputs')
  .command('batch <agent> <csvfile>', 'Evaluate all inputs from csv file')
  .command('train <agent> <csvfile>', 'Train the agent with csv data')
  .demand('k')
  .alias('k', 'key')
  .describe('k', 'API key')
  .alias('r', 'root')
  .describe('r', 'root of the API server')
  .default('r', 'https://api.fuzzy.ai')
  .alias('o', 'output')
  .describe('o', 'Output file')
  .alias('q', 'quiet')
  .describe('q', 'Minimize console output')
  .boolean('q')
  .default('q', false)
  .env('FUZZY_AI')
  .alias('c', 'config')
  .describe('c', 'Config file')
  .default('c', path.join(process.env.HOME, '.fuzzy.ai.json'))
  .config('config')
  .help('h')
  .alias('h', 'help')
  .argv

parseAgentFile = (agentFile) ->

  ext = path.extname(agentFile).toLowerCase()

  switch ext
    when '.cson'
      model = CSON.parseCSONFile agentFile
    when '.json'
      str = fs.readFileSync(agentFile, 'utf-8')
      model = JSON.parse(str)
    else
      throw new Error "Unrecognized file extension for model file #{agentFile}"

  model

# FIXME: this is kind of inefficient.

toID = (client, nameOrID, callback) ->
  client.getAgents (err, agents) ->
    if err
      callback err
    else
      withID = _.find agents, {id: nameOrID}
      if withID?
        callback null, withID.id
      else
        withName = _.filter agents, {name: nameOrID}
        if !withName? or withName.length == 0
          callback new Error("No such agent with name or ID '#{nameOrID}'")
        else if withName.length > 1
          ids = _.map withName, "id"
          str = ids.join(', ')
          msg = "Too many matches for name '#{nameOrID}'; choose one of #{str}"
          callback new Error(msg)
        else
          callback null, withName[0].id

toOutputStream = (name, callback) ->
  if name?
    try
      str = fs.createWriteStream name
      callback null, str
    catch err
      callback err, null
  else
    callback null, process.stdout

handler =
  create: (client, argv, callback) ->
    async.waterfall [
      (callback) ->
        parseAgentFile argv.agentfile, callback
      (agent, callback) ->
        client.newAgent agent, callback
      (created, callback) ->
        if argv.q
          callback null
        else
          async.waterfall [
            (callback) ->
              toOutputStream argv.o, callback
            (str, callback) ->
              str.end JSON.stringify(created), "utf-8", callback
          ], callback
    ], callback
  read: (client, argv, callback) ->
    agent = null
    async.waterfall [
      (callback) ->
        toID client, argv.agent, callback
      (id, callback) ->
        client.getAgent id, callback
      (results, callback) ->
        agent = results
        toOutputStream argv.o, callback
      (str, callback) ->
        str.end JSON.stringify(agent), "utf-8", callback
    ], callback
  update: (client, argv, callback) ->
    async.waterfall [
      (callback) ->
        async.parallel [
          (callback) ->
            toID client, argv.agent, callback
          (callback) ->
            parseAgentFile argv.agentfile, callback
        ], callback
      (results, callback) ->
        [id, agent] = results
        client.putAgent id, agent, callback
      (updated, callback) ->
        if argv.q
          callback null
        else
          async.waterfall [
            (callback) ->
              toOutputStream argv.o, callback
            (str, callback) ->
              str.end JSON.stringify(updated), "utf-8", callback
          ], callback
    ], callback
  delete: (client, argv, callback) ->
    async.waterfall [
      (callback) ->
        toID client, argv.agent, callback
      (id, callback) ->
        client.deleteAgent id, callback
    ], callback

main = (argv, callback) ->

  client = new FuzzyAIClient argv.k, argv.r

  command = argv._[0]

  if !_.has(handler, command)
    callback new Error("Unrecognized command: #{command}")
  else
    handler[command] client, argv, callback

main argv, (err) ->
  if err
    process.stderr.write err.message + "\n"
    process.exit 1
  else
    console.log "Done."
    process.exit 0
