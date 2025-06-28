from "%globalsDarg/darg_library.nut" import *


let iconImg = {
  vip = "gamercard_subs_vip"
  prem = "gamercard_subs_prem"
  prem_deprecated = "premium_active"
  prem_inactive = "premium_inactive"
}

let iconScale = {
  vip = 1.3
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

function mkSubsIcon(id, sizeH) {
  let iconW = getSubsIconSize(id, sizeH * 1.3)
  let iconH = getSubsIconSize(id, sizeH)
  return {
    key = {}
    size = [iconW, iconH]
    rendObj = ROBJ_IMAGE
    keepAspect = true
    image = Picture($"ui/gameuiskin#{iconImg?[id] ?? "premium_inactive"}.svg:{iconW}:{iconH}:P")
  }
}

return {
  getSubsPresentation
  getSubsName = @(id) loc(getSubsPresentation(id)?.locId ?? $"subscription/{id}")
  mkSubsIcon
}