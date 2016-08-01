_ = require "lodash"
uuid = require "node-uuid"

console.log "id,input1,input2"
_.times 1024, (i) ->
  id = uuid.v4()
  input1 = _.random(0, 10)
  input2 = _.random(0, 10)
  console.log "#{id},#{input1},#{input2}"
