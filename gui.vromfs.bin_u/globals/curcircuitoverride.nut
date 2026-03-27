let { get_cur_circuit_block } = require("blkGetters")

let getCurCircuitOverride = @(urlId, defValue = null)
  get_cur_circuit_block()?[urlId] ?? defValue

function isExternalOperator() {
  return getCurCircuitOverride("operatorName") != null
}

return {
  getCurCircuitOverride
  isExternalOperator
}