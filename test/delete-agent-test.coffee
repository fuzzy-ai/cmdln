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
async = require 'async'

runScript = require './run-script'

createAgent = (callback) ->
  agentFile = path.join(__dirname, "data", "twoinputs.cson")
  runScript "create #{agentFile}", (err, output) ->
    if err?
      callback err
    else
      try
        data = JSON.parse output
      catch parseError
        return callback parseError
      return callback null, data

vows
  .describe 'delete agent test'
  .addBatch
    'When we delete an agent with the -y flag':
      topic: ->
        id = null
        async.waterfall [
          (callback) ->
            createAgent callback
          (created, callback) ->
            id = created.id
            runScript "delete -y #{id}", callback
          (results, callback) ->
            runScript "read #{id}", (err, output) =>
              if !err?
                callback new Error("Unexpected success")
              else if err.message.match /No such agent/
                callback null
              else
                callback err
        ], @callback
        undefined
      'it works': (err) ->
        assert.ifError err
  .addBatch
    'When we delete an agent with the --yes flag':
      topic: ->
        id = null
        async.waterfall [
          (callback) ->
            createAgent callback
          (created, callback) ->
            id = created.id
            runScript "delete --yes #{id}", callback
          (results, callback) ->
            runScript "read #{id}", (err, output) =>
              if !err?
                callback new Error("Unexpected success")
              else if err.message.match /No such agent/
                callback null
              else
                callback err
        ], @callback
        undefined
      'it works': (err) ->
        assert.ifError err
  .addBatch
    'When we delete an agent with the "y" input':
      topic: ->
        id = null
        async.waterfall [
          (callback) ->
            createAgent callback
          (created, callback) ->
            id = created.id
            runScript "delete #{id}", "y\n", callback
          (results, callback) ->
            runScript "read #{id}", (err, output) =>
              if !err?
                callback new Error("Unexpected success")
              else if err.message.match /No such agent/
                callback null
              else
                callback err
        ], @callback
        undefined
      'it works': (err) ->
        assert.ifError err
  .addBatch
    'When we delete an agent with the "n" input':
      topic: ->
        id = null
        async.waterfall [
          (callback) ->
            createAgent callback
          (created, callback) ->
            id = created.id
            runScript "delete #{id}", "n\n", callback
          (results, callback) ->
            runScript "read #{id}", callback
        ], @callback
        undefined
      'it is still there': (err) ->
        assert.ifError err

  .export module
