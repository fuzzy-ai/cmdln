# batch-agent-test.coffee
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

_ = require 'lodash'
vows = require 'perjury'
assert = vows.assert
debug = require('debug')('fuzzy.ai:batch-agent-test')

runScript = require './run-script'

vows
  .describe 'batch agent test'
  .addBatch
    'and we create a new agent':
      topic: ->
        agentFile = path.join(__dirname, "data", "twoinputs.cson")
        runScript "create #{agentFile}", (err, output) =>
          if err?
            @callback err
          else
            try
              data = JSON.parse output
            catch parseError
              return @callback parseError
            return @callback null, data
        undefined
      'it works': (err, data) ->
        assert.ifError err
        assert.isObject data
      'and we do batch evaluations on the agent':
        topic: (created) ->
          agentFile = path.join(__dirname, "data", "basic.csv")
          runScript "batch #{created.id} #{agentFile}", (err, output) =>
            if err?
              @callback err
            else
              return @callback null, output
          undefined
        'it works': (err, output) ->
          assert.ifError err
          assert.isString output
          lines = output.split "\n"
          debug lines
          # This includes closing newline
          assert.lengthOf lines, 13
          headers = lines[0].split ","
          assert.lengthOf headers, 3
          assert.equal headers[0], "input1"
          assert.equal headers[1], "input2"
          assert.equal headers[2], "output1"
          for line in lines.slice(1, 12)
            fields = line.split ","
            assert.lengthOf fields, 3
            for field in fields
              assert.isNumber parseFloat(field)
  .export module
