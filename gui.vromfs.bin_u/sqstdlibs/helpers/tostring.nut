let { isDataBlock } = require("%sqstd/underscore.nut")
let u = require("u.nut")
let g_string = require("%sqstd/string.nut")
let {format} = require("string")
let math = require("math")

let hexNumbers = "0123456789abcdef"
local toString 

function tableKeyToString(k) {
  if (type(k) != "string")
    return $"[ {toString(k) }]"
  if (g_string.isStringInteger(k) || g_string.isStringFloat(k) ||
    [ "true", "false", "null" ].contains(k))
      return $"[\"{k}\"]"
  return k
}

let floatToStr = @(v) "".concat(v, v % 1 != 0 ? "" : ".0")

let DEBUG_TABLE_DATA_PARAMS = {
  recursionLevel = 4,
  addStr = "",
  showBlockBrackets = true,
  silentMode = false,
  printFn = null
}

function debugTableData(info, parameters = DEBUG_TABLE_DATA_PARAMS) {
  let showBlockBrackets = parameters?.showBlockBrackets ?? true
  let addStr = parameters?.addStr ?? ""
  let silentMode = parameters?.silentMode ?? false
  let recursionLevel = parameters?.recursionLevel ?? 4
  local printFn = parameters?.printFn
  let needUnfoldInstances = parameters?.needUnfoldInstances ?? false

  if (printFn == null)
    printFn = println

  if (addStr=="" && !silentMode)
    printFn("DD: START")

  let prefix = silentMode ? "" : "DD: ";

  if (info == null)
    printFn($"{prefix}null");
  else {
    if (isDataBlock(info) && u.isFunction(info?.getBlockName)) {
      let blockName = (info.getBlockName()!="") ? "".concat(info.getBlockName()," ") : ""
      if (showBlockBrackets)
        printFn("".concat(prefix, addStr, blockName, "{"))
      let addStr2 = "".concat(addStr, (showBlockBrackets? "  " : ""))
      for (local i = 0; i < info.paramCount(); i++) {
        let name = info.getParamName(i)
        local val = info.getParamValue(i)
        local vType = " "
        if (val == null) { val = "null" }
        else if (type(val)=="integer") vType = ":i"
        else if (type(val)=="float") { vType = ":r"; val = floatToStr(val) }
        else if (type(val)=="bool") vType = ":b"
        else if (type(val)=="string") { vType = ":t"; val = $"'{val}'" }
        else if (u.isPoint2(val)) { vType = ":p2"; val = format("%s, %s", floatToStr(val.x), floatToStr(val.y)) }
        else if (u.isPoint3(val)) { vType = ":p3"; val = format("%s, %s, %s", floatToStr(val.x), floatToStr(val.y), floatToStr(val.z)) }
        else if (u.isColor4(val)) { vType = ":c";  val = format("%d, %d, %d, %d", 255 * val.r, 255 * val.g, 255 * val.b, 255 * val.a) }
        else if (u.isTMatrix(val)) {
          vType = ":m"
          let arr = []
          for (local j = 0; j < 4; j++)
            arr.append("".concat("[", g_string.implode([ val[j].x, val[j].y, val[j].z ], ", "), "]"))
          val = "".concat("[", g_string.implode(arr, " "), "]")
        }
        else
          val = toString(val)
        printFn("".concat(prefix,addStr2,name,vType,"= ", val))
      }
      for (local j = 0; j < info.blockCount(); j++)
        if (recursionLevel)
          debugTableData(info.getBlock(j),
            {recursionLevel = recursionLevel-1, addStr = addStr2, showBlockBrackets = true, silentMode = silentMode, printFn = printFn})
        else
          printFn("".concat(prefix, addStr2, info.getBlock(j).getBlockName(), " = DataBlock()"))
      if (showBlockBrackets)
        printFn("".concat(prefix, addStr, "}"))
    }
    else if (type(info)=="array" || type(info)=="table" || (type(info)=="instance" && needUnfoldInstances)) {
      if (showBlockBrackets)
        printFn("".concat(prefix, addStr, (type(info) == "array" ? "[" : "{")))
      let addStr2 = "".concat(addStr, (showBlockBrackets? "  " : ""))
      foreach(id, data in info) {
        let dType = type(data)
        let isDataBlockType = isDataBlock(data)
        let idText = tableKeyToString(id)
        if (isDataBlockType || dType=="array" || dType=="table" || (dType=="instance" && needUnfoldInstances)) {
          let openBraket = isDataBlockType ? "DataBlock {" : dType == "array" ? "[" : "{"
          let closeBraket = ((dType=="array")? "]":"}")
          if (recursionLevel) {
            printFn("".concat(prefix, addStr2, idText, " = ", openBraket))
            debugTableData(data,
              {recursionLevel = recursionLevel - 1, addStr = "".concat(addStr2, "  "), showBlockBrackets = false,
                needUnfoldInstances, silentMode, printFn })

            printFn("".concat(prefix,addStr2,closeBraket))
          }
          else {
            let hasContent = (isDataBlockType && (data.paramCount() + data.blockCount()) > 0)
              || dType=="instance" || data.len() > 0
            printFn("".concat(prefix, addStr2, idText, " = ", openBraket, hasContent ? "..." : "", closeBraket))
          }
        }
        else if (dType=="instance")
          printFn("".concat(prefix,addStr2,idText," = ", toString(data, math.min(1, recursionLevel), addStr2)))
        else if (dType=="string")
          printFn("".concat(prefix, addStr2, idText, " = \"", data, "\""))
        else if (dType=="float")
          printFn("".concat(prefix, addStr2, idText, " = ", floatToStr(data)))
        else if (dType=="null")
          printFn("".concat(prefix, addStr2, idText, " = null"))
        else
          printFn("".concat(prefix,addStr2,idText," = ", data))
      }
      if (showBlockBrackets)
        printFn("".concat(prefix, addStr, (type(info) == "array" ? "]" : "}")))
    }
    else if (type(info)=="instance")
      printFn("".concat(prefix, addStr, toString(info, math.min(1, recursionLevel), addStr))) 
    else {
      let iType = type(info)
      if (iType == "string")
        printFn("".concat(prefix, addStr, "\"", info, "\""))
      else if (iType == "float")
        printFn("".concat(prefix, addStr, floatToStr(info)))
      else if (iType == "null")
        printFn("".concat(prefix, addStr, "null"))
      else
        printFn("".concat(prefix, addStr, info))
    }
  }
  if (addStr=="" && !silentMode)
    printFn("DD: DONE.")
}

toString = function (val, recursion = 1, addStr = "") {
  if (type(val) == "instance") {
    if (isDataBlock(val) && u.isFunction(val?.getBlockName)) {
      let rootBlockName = val.getBlockName() ?? ""
      let iv = []
      for (local i = 0; i < val.paramCount(); i++)
        iv.append("".concat(val.getParamName(i), " = ", toString(val.getParamValue(i))))
      for (local i = 0; i < val.blockCount(); i++)
        iv.append("".concat(val.getBlock(i).getBlockName(), " = ", toString(val.getBlock(i))))
      return format("DataBlock %s{ %s }", rootBlockName, g_string.implode(iv, ", "))
    }
    else if (u.isPoint2(val))
      return format("Point2(%s, %s)", floatToStr(val.x), floatToStr(val.y))
    else if (u.isPoint3(val))
      return format("Point3(%s, %s, %s)", floatToStr(val.x), floatToStr(val.y), floatToStr(val.z))
    else if (u.isPoint4(val))
      return format("Point4(%s, %s, %s, %s)", floatToStr(val.x), floatToStr(val.y), floatToStr(val.z), floatToStr(val.w))
    else if (u.isColor4(val))
      return format("Color4(%d/255.0, %d/255.0, %d/255.0, %d/255.0)", 255 * val.r, 255 * val.g, 255 * val.b, 255 * val.a)
    else if (u.isTMatrix(val)) {
      let arr = []
      for (local i = 0; i < 4; i++)
        arr.append(toString(val[i]))
      return "".concat("TMatrix(", g_string.implode(arr, ", "), ")")
    }
    else if (("isToStringForDebug" in val) && u.isFunction(val?.tostring))
      return val.tostring()
    else if ("DaGuiObject" in getroottable() && val instanceof getroottable()["DaGuiObject"])
      return val.isValid()
        ? "DaGuiObject(tag = {0}, id = {1} )".subst(val.tag, val?.id ?? "NULL")
        : "invalid DaGuiObject"
    else {
      local ret = u.isFunction(val?.getmetamethod) && val.getmetamethod("_tostring") != null
        ? "instance \"{0}\"".subst(val.tostring())
        : "instance"

      if (recursion > 0)
        foreach (idx, v in val) {
          
          
          
          if (type(v) != "function") {
            let index = [ "float", "null" ].contains(type(idx)) ? toString(idx) : idx
            ret = "".concat(ret, "\n", addStr, "  ", index, " = ", toString(v, recursion - 1, $"{addStr}  "))
          }
        }

      return ret;
    }
  }
  if (val == null)
    return "null"
  if (type(val) == "string")
    return format("\"%s\"", val)
  if (type(val) == "float")
    return floatToStr(val)
  if (type(val) != "array" && type(val) != "table")
    return $"{val}"
  let isArray = type(val) == "array"
  local str = ""
  if (recursion > 0) {
    let iv = []
    foreach (i,v in val) {
      let index = isArray ? ($"[{i}]") : tableKeyToString(i)
      iv.append("".concat(index, " = ", toString(v, recursion - 1, "")))
    }
    str = g_string.implode(iv, ", ")
  } else
    str = val.len() ? "..." : ""
  return isArray ? ($"[ {str} ]") : ($"{ {str} }")
}

function intToHexString(number) {
  if (number == 0)
    return "0"
  local res = ""
  while (number != 0) {
    let index = number & 0xF
    res = "".concat(hexNumbers.slice(index, index + 1), res)
    number = number >>> 4
  }
  return res
}

return {
  debugTableData
  toString
  intToHexString
}