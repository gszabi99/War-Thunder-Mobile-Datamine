from "%globalsDarg/darg_library.nut" import *
from "math" import min, max, round
from "hangar" import CHECK_PROT_RICOCHET_POSSIBLE, CHECK_PROT_RICOCHET_GUARANTEED
from "%sqstd/underscore.nut" import isEqual, prevIfEqual
from "%sqstd/string.nut" import utf8Capitalize
from "%rGui/style/stdColors.nut" import goodTextColor, badTextColor
from "%rGui/dmViewer/protectionAnalysisState.nut" import isSimulationMode, isHintVisible, probabilityColor
from "%rGui/dmViewer/dmViewerPkg.nut" import toggleSubscription, accentColor, hitProbPossibleColor, hitProbMinorColor

let resultTypesOrderedCfg = [
  {
    criticalDamageTestName = "ricochet"
    checkParams = @(params) params?.lower.ricochet == CHECK_PROT_RICOCHET_GUARANTEED &&
                            !params?.lower.effectiveHit &&
                            !params?.upper.effectiveHit
    color = hitProbMinorColor
    title = "hitcamera/result/ricochet"
    infoSrc = [ "lower", "upper" ]
    needPenetratedArmor = false
    needRicochetProb = true
    needParts = false
  },
  {
    criticalDamageTestName = "possibleEffective"
    checkParams = @(params) (params?.upper.effectiveHit ?? false)
      || ((params?.lower.effectiveHit ?? false) && params?.lower.ricochet == CHECK_PROT_RICOCHET_POSSIBLE)
    color = hitProbPossibleColor
    title = "protection_analysis/result/possible_effective"
    infoSrc = [ "lower", "upper" ]
    needPenetratedArmor = true
    needRicochetProb = false
    needParts = true
  },
  {
    criticalDamageTestName = "effective"
    checkParams = @(params) (params?.lower.effectiveHit ?? false)
      && params?.lower.ricochet != CHECK_PROT_RICOCHET_POSSIBLE
    color = goodTextColor
    title = "protection_analysis/result/effective"
    infoSrc = [ "lower", "upper" ]
    needPenetratedArmor = true
    needRicochetProb = false
    needParts = true
  },
  {
    criticalDamageTestName = "notPenetrate"
    checkParams = @(params) (params?.max.effectiveHit ?? false) &&
      ((params?.max.penetratedArmor.generic ?? false) ||
        (params?.max.penetratedArmor.genericLongRod ?? false) ||
        (params?.max.penetratedArmor.explosiveFormedProjectile ?? false) ||
        (params?.max.penetratedArmor.cumulative ?? false))
    color = badTextColor
    title = "protection_analysis/result/not_penetrated"
    infoSrc = [ "max" ]
    needPenetratedArmor = true
    needRicochetProb = true
    needParts = false
  },
  {
    criticalDamageTestName = "ineffective"
    checkParams = @(_params) true
    color = hitProbMinorColor
    title = "protection_analysis/result/ineffective"
    infoSrc = [ "max" ]
    needPenetratedArmor = false
    needRicochetProb = true
    needParts = false
  },
]
resultTypesOrderedCfg.each(@(v) v.title = colorize(v.color, loc(v.title)))

let resultTypeIneffective = resultTypesOrderedCfg[resultTypesOrderedCfg.len() - 1]

function getResultTypeByParams(params) {
  foreach (t in resultTypesOrderedCfg)
    if (params?.criticalDamageTest == t.criticalDamageTestName || t.checkParams(params))
      return t
  return resultTypeIneffective
}



let hintParams = Watched(null)
let resultCfg = Watched(resultTypeIneffective)

function onProtectionAnalysisResult(params) {
  if (isEqual(params, hintParams.get()))
    return
  let resCfg = getResultTypeByParams(params)
  isHintVisible.set(params != null)
  probabilityColor.set(resCfg.color)
  hintParams.set(params)
  resultCfg.set(resCfg)
}

let toggleSub = @(v) toggleSubscription("on_check_protection", onProtectionAnalysisResult, v)
isSimulationMode.subscribe(toggleSub)
if (isSimulationMode.get())
  toggleSub(true)



let strTitle = Computed(@() resultCfg.get().title)

let valAngle = Computed(@() round(max((hintParams.get()?.angle ?? 0.0), 0.0)))
let strAngle = Computed(@() "".concat(loc("bullet_properties/hitAngle"), colon,
    colorize(accentColor, valAngle.get()), loc("measureUnits/deg")))

let valHeadingAngle = Computed(@() round(max((hintParams.get()?.headingAngle ?? 0.0), 0.0)))
let strHeadingAngle = Computed(@() "".concat(loc("protection_analysis/hint/headingAngle"), colon,
    colorize(accentColor, valHeadingAngle.get()), loc("measureUnits/deg")))

let valPenetratedArmor = Computed(function() {
  local res = 0.0
  let { needPenetratedArmor, infoSrc } = resultCfg.get()
  if (needPenetratedArmor)
    foreach (src in infoSrc) {
      let source = hintParams.get()?[src].penetratedArmor
      res = max(res, (source?.generic ?? 0.0)
        + (source?.genericLongRod ?? 0.0)
        + (source?.explosiveFormedProjectile ?? 0.0)
        + (source?.cumulative ?? 0.0))
      res = max(res, (source?.explosion ?? 0.0))
      res = max(res, (source?.shatter ?? 0.0))
    }
  return round(res)
})
let strPenetratedArmor = Computed(function() {
  let val = valPenetratedArmor.get()
  return val == 0 ? "" : "".concat(loc("protection_analysis/hint/armor"), colon,
    colorize(accentColor, val), loc("measureUnits/mm"))
})

let valRicochetProb = Computed(function() {
  local res = 0.0
  let { needRicochetProb, infoSrc } = resultCfg.get()
  if (needRicochetProb)
    foreach (src in infoSrc)
      res = max(res, (hintParams.get()?[src].ricochetProb ?? 0.0))
  return round(res * 100)
})
let strRicochetProb = Computed(function() {
  let val = valRicochetProb.get()
  return val < 10 ? "" : "".concat(loc("protection_analysis/hint/ricochetProb"), colon,
    colorize(accentColor, val), loc("measureUnits/percent"))
})

let valParts = Computed(function(prev) {
  local res = {}
  let { needParts, infoSrc } = resultCfg.get()
  if (needParts)
    foreach (src in infoSrc)
      foreach (partId, isShow in (hintParams.get()?[src].parts ?? {}))
        res[partId] <- isShow
  res = res.filter(@(v) v)
  return prevIfEqual(prev, res)
})
let partPrefix = loc("ui/bullet")
let strParts = Computed(function() {
  let val = valParts.get()
  if (val.len() == 0)
    return ""
  let partNames = [ "".concat(loc("protection_analysis/hint/parts/list"), colon) ]
    .extend(val.keys().map(@(partId) "".concat(partPrefix, utf8Capitalize(loc($"dmg_msg_short/{partId}")))).sort())
  return "\n".join(partNames)
})

return {
  isHintVisible
  probabilityColor

  strTitle
  strAngle
  strHeadingAngle
  strPenetratedArmor
  strRicochetProb
  strParts
}
