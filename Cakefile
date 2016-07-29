fs = require "fs"

{spawn} = require "child_process"

glob = require "glob"
_ = require "lodash"

cmd = (str, env, callback) ->
  if _.isFunction(env)
    callback = env
    env = null
  env = _.defaults(env, process.env)
  parts = str.split(" ")
  main = parts[0]
  rest = parts.slice(1)
  proc = spawn main, rest, {env: env}
  proc.stderr.on "data", (data) ->
    process.stderr.write data.toString()
  proc.stdout.on "data", (data) ->
    process.stdout.write data.toString()
  proc.on "exit", (code) ->
    callback?() if code is 0

build = (callback) ->
  cmd "coffee -c fuzzy-ai-cmdln.coffee", callback

clean = (callback) ->
  patterns = ["*.js", "*~"]
  for pattern in patterns
    glob pattern, (err, files) ->
      for file in files
        fs.unlinkSync file
  callback()

task "clean", "Clean up extra files", ->
  clean()

task "build", "Build from source", ->
  clean ->
    build()
