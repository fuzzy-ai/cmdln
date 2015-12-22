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

  getAgent = (filename, callback) ->
    async.waterfall [
      (callback) ->
        client.getAgent id, callback
      (agent, callback) ->
        data = CSON.stringify agent
        fs.writeFile filename, data, {encoding: "utf8"}, callback
      ], callback

  getAgent argv._[0], (err, agent) ->
    if err
      console.error err
      process.exit -1
    else
      process.exit 0

main yargs.argv
