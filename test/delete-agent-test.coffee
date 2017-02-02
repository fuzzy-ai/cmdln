# delete-agent-test.coffee
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
debug = require('debug')('fuzzy.ai:delete-agent-test')

runScript = require './run-script'

vows
  .describe 'delete agent test'
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
      'and we delete the agent':
        topic: (created) ->
          runScript "delete #{created.id}", (err, output) =>
            if err?
              @callback err
            else
              return @callback null
          undefined
        'it works': (err) ->
          assert.ifError err
        'and we read back the agent':
          topic: (created) ->
            runScript "read #{created.id}", (err, output) =>
              if !err?
                @callback new Error("Unexpected success")
              else if err.message.match /No such agent/
                @callback null
              else
                @callback err
            undefined
          'it works': (err) ->
            assert.ifError err

  .export module
