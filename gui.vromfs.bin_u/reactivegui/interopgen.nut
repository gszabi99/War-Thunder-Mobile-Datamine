let str = @(...) "".join(vargv)

let function makeSlotName(original_name, prefix, postfix) {
  let slotName = (prefix.len() > 0)
    ? str(prefix, original_name.slice(0, 1).toupper(), original_name.slice(1))
    : original_name
  return str(slotName, postfix)
}

let function generate(options) {
  let prefix = options?.prefix ?? ""
  let postfix = options?.postfix ?? ""

  foreach (stateName, stateObject in options.stateTable) {
    ::interop[ makeSlotName(stateName, prefix, postfix) ] <- stateObject
  }
}

return generate