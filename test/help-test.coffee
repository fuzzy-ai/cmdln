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

debug = require('debug')('fuzzy.ai:help-test')

runScript = require './run-script'

vows
  .describe 'Show help output'
  .addBatch
    'When we ask for help':
      topic: ->
        runScript "-h", (err, output) =>
          if err?
            @callback err
          else
            return @callback null, output
        undefined
      'it works': (err, output) ->
        assert.ifError err
        assert.isString output
        debug output
        
  .export module
