fs = require 'fs'

FuzzyIOClient = require 'fuzzy.io'
yargs = require 'yargs'
async = require 'async'
CSON = require 'cson'

main = (argv) ->
  key = argv.k || argv.key || process.env.FUZZY_IO_KEY
  client = new FuzzyIOClient key

  newAgent = (filename, callback) ->
    async.waterfall [
      (callback) ->
        CSON.parseCSONFile filename, {}, callback
      (agent, callback) ->
        client.newAgent agent, callback
    ], callback

  async.map argv._, newAgent, (err, agents) ->
    if err
      console.error err
      process.exit -1
    else
      for agent in agents
        console.dir {name: agent.name, id: agent.id}
      process.exit 0

main yargs.argv
