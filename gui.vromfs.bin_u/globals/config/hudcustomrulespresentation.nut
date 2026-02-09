let defFlagPresentation = {
  mpStatIcon = "ui/gameuiskin#icon_hud_ctf.svg"
  icon = "ui/gameuiskin#icon_hud_ctf.svg"
  emptyIcon = "ui/gameuiskin#icon_hud_ctf_empty.svg"
  flagCapturedLocId = "hints/flag_captured"
}

let ctfFlagPresentations = {
  gift = {
    mpStatIcon = "ui/gameuiskin#icon_hud_gift.svg"
    icon = "ui/gameuiskin#icon_hud_gift.svg"
    emptyIcon = "ui/gameuiskin#empty_icon_hud_gift.svg"
    flagCapturedLocId = "hints/gift_captured"
  }
}.map(@(p) defFlagPresentation.__merge(p))

return {
  getCtfFlagPresentation = @(id) ctfFlagPresentations?[id] ?? defFlagPresentation
}
