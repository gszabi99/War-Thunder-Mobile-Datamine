from "blkGetters" import get_cur_circuit_block

let getCurCircuitOverride = @(urlId, defValue = null)
  get_cur_circuit_block()?[urlId] ?? defValue

let isExternalOperator = @() getCurCircuitOverride("operatorName") != null

function addPublisherToHeaders(headers) {
  let publisher = getCurCircuitOverride("publisher")
  if (publisher != null)
    headers.publisher <- publisher
  return headers
}

return {
  getCurCircuitOverride
  isExternalOperator
  addPublisherToHeaders
}
