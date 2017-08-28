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

parse = require 'csv-parse/lib/sync'

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
      'teardown': (created) ->
          callback = @callback
          debug("Deleting #{created.id}")
          runScript "delete -y #{created.id}", (err, output) =>
            if err?
              debug("Got an error deleting agent #{created.id}")
              callback err
            else
              debug("Deleted agent #{created.id}")
              callback null
          undefined
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
          records = parse(output, {columns: true})
          assert.isObject _.find records, (record) -> record.id == created.id
          for record in records
            debug record
            assert.isString record.id
            assert.isString record.name
  .export module
