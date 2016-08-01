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
parse = require 'csv-parse'
transform = require 'stream-transform'
stringify = require 'csv-stringify'
debug = require('debug')('fuzzy.ai:cmdln')

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
  .alias('b', 'batch-size')
  .describe('b', "Batch size")
  .number('b')
  .default('b', 128)
  .env('FUZZY_AI')
  .alias('c', 'config')
  .describe('c', 'Config file')
  .default('c', path.join(process.env.HOME, '.fuzzy.ai.json'))
  .config('config')
  .help('h')
  .alias('h', 'help')
  .argv

# pretty-print an object as JSON

pp = (obj) ->
  JSON.stringify(obj, null, 2) + "\n"

parseAgentFile = (agentFile, callback) ->

  ext = path.extname(agentFile).toLowerCase()

  switch ext
    when '.cson'
      CSON.parseCSONFile agentFile, {}, callback
    when '.json'
      fs.readFile agentFile, 'utf-8', (err, str) ->
        if err
          callback err
        else
          try
            model = JSON.parse(str)
            # We don't want exceptions bubbling back up here
            setImmediate callback, null, model
          catch error
            callback null, error
    else
      callback new Error "Unrecognized extension for #{agentFile}"

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
      # So exceptions don't bubble up here
      setImmediate callback, null, str
    catch err
      callback err, null
  else
    callback null, process.stdout

transformCSVFile = (filename, output, handler, callback) ->

  parser = parse
    delimiter: ','
    columns: true
    auto_parse: true
    auto_parse_date: true

  stringifier = stringify
    delimiter: ','
    header: true

  input = fs.createReadStream filename

  blankToNull = transform (record, callback) ->
    for name, value of record
      if _.isString record[name] and record[name].length is 0
        record[name] = null
    callback null, record

  transformer = transform handler

  output.on 'finish', ->
    callback null

  input
  .pipe(parser)
  .pipe(blankToNull)
  .pipe(transformer)
  .pipe(stringifier)
  .pipe(output)

handler =
  create: (client, argv, callback) ->
    debug("Creating a new agent")
    created = null
    async.waterfall [
      (callback) ->
        debug "Parsing agent file #{argv.agentfile}"
        parseAgentFile argv.agentfile, callback
      (agent, callback) ->
        debug "Got agent"
        debug agent
        client.newAgent agent, callback
      (results, callback) ->
        created = results
        debug created
        toOutputStream argv.o, callback
      (str, callback) ->
        if argv.q
          str.write created.id, "utf-8", callback
        else
          str.write pp(created), "utf-8", callback
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
        str.write pp(agent), "utf-8", callback
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
        async.waterfall [
          (callback) ->
            toOutputStream argv.o, callback
          (str, callback) ->
            if argv.q
              str.write updated.id, "utf-8", callback
            else
              str.write pp(updated), "utf-8", callback
        ], callback
    ], callback
  delete: (client, argv, callback) ->
    async.waterfall [
      (callback) ->
        toID client, argv.agent, callback
      (id, callback) ->
        client.deleteAgent id, callback
    ], callback
  batch: (client, argv, callback) ->
    id = null
    inputNames = null
    outputNames = null
    debug "Starting batch for #{argv.agent}"
    async.waterfall [
      (callback) ->
        debug "Getting ID for #{argv.agent}"
        toID client, argv.agent, callback
      (results, callback) ->
        id = results
        debug "ID for #{argv.agent} is #{id}"
        client.getAgent id, callback
      (agent, callback) ->
        debug "Getting inputNames and outputNames for #{id}"
        inputNames = _.keys agent.inputs
        outputNames = _.keys agent.outputs
        debug inputNames
        debug outputNames
        debug "Getting output stream for #{argv.o}"
        toOutputStream argv.o, callback
      (output, callback) ->
        buffer = []

        debug "Got stream for #{argv.o}"

        parser = parse
          delimiter: ','
          columns: true
          auto_parse: true
          auto_parse_date: true

        stringifier = stringify
          delimiter: ','
          header: true

        debug "Creating input stream for #{argv.csvfile}"

        input = fs.createReadStream argv.csvfile

        b2n = (record, callback) ->
          for name, value of record
            if _.isString record[name] and record[name].length is 0
              record[name] = null
          callback null, record

        blankToNull = transform b2n, {parallel: Infinity}

        debug blankToNull

        postBatch = (batch) ->
          debug "Posting batch (#{batch.length})"
          inputs = _.map batch, (batchItem) ->
            _.pick batchItem[0], inputNames
          client.evaluate id, inputs, (err, outputs) ->
            if err
              debug err
              _.each batch, (batchItem) ->
                setImmediate batchItem[1], err
            else
              _.each batch, (batchItem, i) ->
                results = _.assign {}, batchItem[0], outputs[i]
                setImmediate batchItem[1], null, results

        enqueueRecord = (record, callback) ->
          debug "Got record"
          buffer.push [record, callback]
          debug "Buffer length = #{buffer.length} (max #{argv.b})"
          if buffer.length == argv.b
            debug "Flushing buffer"
            batch = buffer.slice()
            buffer = []
            postBatch batch

        transformer = transform enqueueRecord, {parallel: Infinity}

        debug "parallel = #{transformer.options.parallel}"

        blankToNull.on 'end', ->
          debug "Finishing input"
          batch = buffer.slice()
          buffer = []
          postBatch batch

        output.on 'finish', ->
          debug "Finished"
          callback null

        debug "Setting up pipeline"

        input
        .pipe(parser)
        .pipe(blankToNull)
        .pipe(transformer)
        .pipe(stringifier)
        .pipe(output)

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
    process.exit 0
