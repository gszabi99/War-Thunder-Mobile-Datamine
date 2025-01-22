let { loc } = require("dagor.localize")

let defCfg = {
  icon = "ui/gameuiskin/premium_active_big.avif"
  //locId - optional
}

let allPresentations = {
  vip = {
    icon = "ui/gameuiskin/vip_active_big.avif"
  }
}
  .map(@(cfg) defCfg.__merge(cfg))

let getSubsPresentation = @(id) allPresentations?[id] ?? defCfg

return {
  getSubsPresentation
  getSubsName = @(id) loc(getSubsPresentation(id)?.locId ?? $"subscription/{id}")
}