from "%globalsDarg/darg_library.nut" import *
let { allow_subscriptions } = require("%appGlobals/permissions.nut")

let iconImg = {
  vip = "gamercard_subs_vip.svg"
  prem = "gamercard_subs_prem.svg"
  prem_deprecated = "premium_active.svg"
  prem_inactive = "premium_inactive.svg"
}

let iconImgDeprecated = {
  vip = "gamercard_subs_vip.avif"
  prem = "gamercard_subs_prem.avif"
  prem_deprecated = "premium_active.svg"
  prem_inactive = "premium_inactive.avif"
}

let iconScale = {
  vip = 1.4
  prem = 1.4
  prem_inactive = 1.4
}

let defCfg = {
  icon = "ui/gameuiskin/subs_prem.avif"
  
}

let allPresentations = {
  vip = {
    icon = "ui/gameuiskin/subs_vip.avif"
  }
}
  .map(@(cfg) defCfg.__merge(cfg))

let getSubsPresentation = @(id) allPresentations?[id] ?? defCfg

let getSubsIconSize = @(id, size) (size * (iconScale?[id] ?? 1) + 0.5).tointeger()

let getPremIcon = @(allowSub, id) (allowSub ? iconImgDeprecated?[id] : null)
  ?? iconImg?[id]
  ?? "premium_inactive.svg"

let mkSubsIcon = @(id, sizeH, ovr = {}) function() {
  let iconW = getSubsIconSize(id, sizeH * 1.3)
  let iconH = getSubsIconSize(id, sizeH)
  let image = getPremIcon(allow_subscriptions.get(), id)
  return {
    key = {}
    watch = allow_subscriptions
    size = [iconW, iconH]
    rendObj = ROBJ_IMAGE
    keepAspect = true
    image = Picture($"ui/gameuiskin#{image}:{iconW}:{iconH}:P")
  }.__update(ovr)
}

return {
  getSubsPresentation
  getSubsName = @(id) loc(getSubsPresentation(id)?.locId ?? $"subscription/{id}")
  mkSubsIcon
  getPremIcon
}