# list-test.coffee
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

path = require 'path'
vows = require 'perjury'
assert = vows.assert
debug = require('debug')('fuzzy.ai:list-test')
_ = require 'lodash'

runScript = require './run-script'

vows
  .describe 'list test'
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
      'and we list all agents':
        topic: (created) ->
          runScript "list", (err, output) =>
            if err?
              @callback err
            else
              return @callback null, output, created
          undefined
        'it works': (err, output, created) ->
          assert.ifError err
          assert.isString output
          [headerLine] = output.split("\n", 1)
          debug headerLine
          headers = headerLine.split(",")
          debug headers
          assert.equal headers.length, 2
          assert.equal headers[0], "id"
          assert.equal headers[1], "name"
          lines = output.split("\n").slice(1, -1)
          rows = lines.map (line) -> line.split ',', 2
          for row in rows
            debug row
            assert.lengthOf row, 2
          assert.isArray _.find rows, (row) -> row[0] == created.id
  .export module
