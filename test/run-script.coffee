# run-script.coffee
#
# Test running the fuzzy.ai script and getting its results
#
# Copyright 2017 Fuzzy.ai
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

child_process = require 'child_process'
path = require 'path'

debug = require('debug')('fuzzy.ai:run-script')

module.exports = runScript = (commandLine, callback) ->

  base = path.join(__dirname, "..", "fuzzy.ai-cmdln.js")
  args = commandLine.split /\s+/

  debug {base: base, args: args}

  child = child_process.fork base, args, {silent: true}

  errOutput = ""
  output = ""

  child.once "error", (err) ->
    callback err

  child.stderr.on "data", (data) ->
    str = data.toString('utf8')
    errOutput = "#{errOutput}#{str}"

  child.stdout.on "data", (data) ->
    str = data.toString('utf8')
    output = "#{output}#{str}"

  child.on 'exit', (code, signal) ->
    if errOutput.length > 0
      callback new Error("Standard error output: #{errOutput}")
    else if code? and code != 0
      callback new Error("Error code on exit: #{code}")
    else if !code? and signal?
      callback new Error("Child exited with signal #{signal}")
    else if code? and code == 0
      callback null, output
    else
      msg = "Unexpected state: #{code} #{signal} #{output} #{errOutput}"
      callback new Error(msg)
