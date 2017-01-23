_ = require "lodash"
uuid = require "node-uuid"

if process.argv.length < 3
  count = 128
else
  count = parseInt(process.argv[2])

if process.argv.length < 4
  inputs = 2
else
  inputs = parseInt(process.argv[3])

inputNames = _.times inputs, (i) -> "input#{i + 1}"

console.log "id,#{inputNames.join(',')}"

_.times count, (i) ->
  id = uuid.v4()
  values = _.times inputs, -> _.random(0, 10)
  console.log "#{id},#{values.join(',')}"
