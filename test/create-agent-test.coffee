# create-agent-test.coffee
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
vows = require 'perjury'
assert = vows.assert

runScript = require './run-script'

vows
  .describe 'create agent test'
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
        assert.isString data.id
        assert.isString data.createdAt
        assert.equal data.name, "Two inputs, one output"
        assert.isObject data.inputs
        for name, sets of data.inputs
          assert.isString name
          assert.isObject sets
        assert.isObject data.outputs
        for name, sets of data.objects
          assert.isString name
          assert.isObject sets
        assert.isArray data.rules
        for rule in data.rules
          assert.isString rule

  .export module
