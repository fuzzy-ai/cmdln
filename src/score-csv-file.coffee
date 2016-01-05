fs = require 'fs'

split = require 'split'
FuzzyIOClient = require 'fuzzy.io'
yargs = require 'yargs'
async = require 'async'
_ = require 'lodash'

main = (argv) ->

  key = argv.k || argv.key || process.env.FUZZY_IO_KEY
  id = argv.i || argv.id || process.env.FUZZY_IO_ID

  client = new FuzzyIOClient key

  filename = argv._[0]

  headers = null
  allHeaders = null
  headersOut = false

  score = (params, callback) ->
    client.evaluate id, params, (err, results) ->
      if err
        callback err
      else
        if !allHeaders?
          allHeaders = _.clone(headers).concat(_.keys(results))
        callback null, _.extend(_.clone(params), results)

  q = async.queue score, 16

  str = fs.createReadStream filename, {encoding: "utf8"}
  str = str.pipe split("\n")

  str.on 'data', (line) ->
    if !line? or line.length == 0
      return
    row = line.split(",")
    if !headers?
      headers = row
    else
      params = _.zipObject headers, _.map(row, (s) -> parseFloat(s))
      q.push params, (err, row) ->
        if err
          console.error err
        else
          if !headersOut
            console.log allHeaders.join(",")
            headersOut = true
          values = []
          for hdr in allHeaders
            values.push row[hdr]
          console.log values.join(",")

  str.on 'end', () ->
    q.drain = () ->
      process.exit 0

main yargs.argv
