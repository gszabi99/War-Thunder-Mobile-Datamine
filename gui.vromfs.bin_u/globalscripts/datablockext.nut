let { isEqual } = require("isEqual.nut")
let datablockCommon = require("%sqstd/datablock.nut")

local blkTypes = [ "string", "bool", "float", "integer", "int64", "instance", "null"]

function copyFromDataBlock(fromDataBlock, toDataBlock, isOverride = true) {
  if (!fromDataBlock || !toDataBlock) {
    print("ERROR: copyFromDataBlock: fromDataBlock or toDataBlock doesn't exist")
    return
  }
  for (local i = 0; i < fromDataBlock.blockCount(); i++) {
    local block = fromDataBlock.getBlock(i)
    local blockName = block.getBlockName()
    if (!toDataBlock?[blockName])
      toDataBlock[blockName] <- block
    else if (isOverride)
      toDataBlock[blockName].setFrom(block)
  }
  for (local i = 0; i < fromDataBlock.paramCount(); i++) {
    local paramName = fromDataBlock.getParamName(i)
    if (toDataBlock?[paramName] == null)
      toDataBlock[paramName] <- fromDataBlock[paramName]
    else if (isOverride)
      toDataBlock[paramName] = fromDataBlock[paramName]
  }
}

local function setBlkValueByPath(blk, path, val) {
  if (!blk || !path)
    return false

  local nodes = path.split("/")
  local key = nodes.len() ? nodes.pop() : null

  if (!key || !key.len())
    return false

  foreach (dir in nodes) {
    if (blk?[dir] != null && type(blk[dir]) != "instance")
      blk[dir] = null
    blk = blk.addBlock(dir)
  }

  //If current value is equal to existent in DataBlock don't override it
  if (isEqual(blk?[key], val))
    return type(val) == "instance" //If the same instance was changed, then need to save

  //Remove DataBlock slot if it contains an instance or if it has different type
  //from new value
  local destType = type(blk?[key])
  if (destType == "instance")
    blk.removeBlock(key)
  else if (blk?[key] != null && destType != type(val))
    blk[key] = null

  if (blkTypes.contains(type(val)))
    blk[key] = val
  else if (type(val) == "table") {
    blk = blk.addBlock(key)
    foreach(k,v in val)
      setBlkValueByPath(blk, k, v)
  }
  else {
    assert(false, $"Data type not suitable for writing to blk: {type(val)}")
    return false
  }

  return true
}

return datablockCommon.__merge({
  copyFromDataBlock
  setBlkValueByPath
})