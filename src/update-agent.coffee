fs = require 'fs'

FuzzyIOClient = require 'fuzzy.io'
yargs = require 'yargs'
async = require 'async'
CSON = require 'cson'

main = (argv) ->
  key = argv.k || argv.key || process.env.FUZZY_IO_KEY
  id = argv.i || argv.id || process.env.FUZZY_IO_ID

  if argv._.length != 1
    console.log "Exactly one file required"

  client = new FuzzyIOClient key

  updateAgent = (filename, callback) ->
    async.waterfall [
      (callback) ->
        CSON.parseCSONFile filename, {}, callback
      (agent, callback) ->
        client.putAgent id, agent, callback
    ], callback

  updateAgent argv._[0], (err, agent) ->
    if err
      console.error err
      process.exit -1
    else
      console.dir {name: agent.name, id: agent.id}
      process.exit 0

main yargs.argv
