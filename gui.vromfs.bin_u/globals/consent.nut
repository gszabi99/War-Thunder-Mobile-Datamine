from "frp" import Computed
from "%appGlobals/curCircuitOverride.nut" import getCurCircuitOverride
from "%appGlobals/permissions.nut" import tcf_consent_enabled


let isTcfConsentDisabledOnCircuit = getCurCircuitOverride("tcfConsentDisabled", false)

let isTcfConsentEnabled = Computed(@() !isTcfConsentDisabledOnCircuit && tcf_consent_enabled.get())

return {
  isTcfConsentEnabled
  isTcfConsentDisabledOnCircuit
}
