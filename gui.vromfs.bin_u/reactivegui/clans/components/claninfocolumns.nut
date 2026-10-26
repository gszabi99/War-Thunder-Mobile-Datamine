from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%rGui/clans/components/clanComps.nut" import mkSectionText


const clanInfoIconSize = hdpx(50)
const clanInfoIconGap = hdpx(16)

let mkClanInfoIconsCell = @(itemsW, mkIcon) @() {
  watch = itemsW
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = clanInfoIconGap
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = itemsW.get().map(mkIcon)
}

let mkClanInfoTextCell = @(valueW) @() {
  watch = valueW
  size = FLEX_H
  halign = ALIGN_CENTER
  children = mkSectionText(valueW.get())
}

let mkClanCampaignIcon = @(c) {
  size = clanInfoIconSize
  rendObj = ROBJ_IMAGE
  image = Picture($"{getCampaignPresentation(c).clanIcon}:{clanInfoIconSize}:P")
}

let clanInfoColumns = [
  { locId = "clans/campaigns", mkCell = @(data) mkClanInfoIconsCell(data.campaignsW, mkClanCampaignIcon) }
  { locId = "clans/location", mkCell = @(data) mkClanInfoTextCell(data.locationW) }
  { locId = "clans/primaryLanguage", mkCell = @(data) mkClanInfoTextCell(data.languageW) }
]

return { clanInfoColumns }
