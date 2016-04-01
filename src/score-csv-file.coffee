fs = require 'fs'

split = require 'split'
FuzzyIOClient = require 'fuzzy.io'
yargs = require 'yargs'
async = require 'async'
_ = require 'lodash'

main = (argv) ->

  key = argv.k || argv.key || process.env.FUZZY_IO_KEY
  id = argv.i || argv.id || process.env.FUZZY_IO_ID
  ignore = argv.g || argv.ignore

  if !key?
    process.stderr.write "No key defined."
    process.exit(-1)

  if !id?
    process.stderr.write "No agent ID defined."
    process.exit(-1)

  client = new FuzzyIOClient key

  filename = argv._[0]

  headers = null
  allHeaders = null
  headersOut = false

  score = (params, callback) ->
    if ignore
      toEval = _.omit(params, ignore)
    else
      toEval = params
    clean = {}
    for name, value of toEval
      if value?
        clean[name] = value
    client.evaluate id, clean, (err, results) ->
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
      params = {}
      for header, i in headers
        s = row[i]
        if ignore? && header == ignore
          params[header] = s
        else if s? && s.length > 0
          params[header] = parseFloat(s)
        else
          params[header] = null
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
