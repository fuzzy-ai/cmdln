fs = require "fs"

{spawn} = require "child_process"

glob = require "glob"
_ = require "lodash"

cmd = (str, callback) ->

  parts = str.split(' ')
  main = parts[0]
  rest = parts.slice(1)
  proc = spawn main, rest
  out = ''
  err = ''

  proc.stderr.on 'data', (data) ->
    err += data.toString()

  proc.stdout.on 'data', (data) ->
    out += data.toString()

  proc.on 'exit', (code) ->
    if code is 0
      callback?(out, err)
    else
      process.exit(code)

build = (callback) ->
  cmd 'coffee -cp fuzzy.ai-cmdln.coffee', (output) ->
    shebang = '#!/usr/bin/env node'
    fs.writeFileSync './fuzzy.ai-cmdln.js', shebang + "\n" + output + "\n"

clean = (callback) ->
  patterns = ["*.js", "*~"]
  for pattern in patterns
    glob pattern, (err, files) ->
      for file in files
        fs.unlinkSync file
  callback?()

task "clean", "Clean up extra files", ->
  clean()

task "build", "Build from source", ->
  clean ->
    build()
