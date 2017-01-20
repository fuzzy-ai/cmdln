_ = require "lodash"
uuid = require "node-uuid"

if process.argv.length < 3
  count = 128
else
  count = parseInt(process.argv[2])

console.log "id,input1,input2"

_.times count, (i) ->
  id = uuid.v4()
  input1 = _.random(0, 10)
  input2 = _.random(0, 10)
  console.log "#{id},#{input1},#{input2}"
