from "%globalsDarg/darg_library.nut" import *
from "%sqstd/string.nut" import utf8ToUpper
from "%appGlobals/clanConsts.nut" import PRIVACY_OPEN, PRIVACY_REQUEST
from "%appGlobals/config/campaignPresentation.nut" import getCampaignPresentation
from "%appGlobals/pServer/campaign.nut" import campaignsList
from "%appGlobals/pServer/servConfigs.nut" import serverConfigs
from "%rGui/clans/clanCfg.nut" import languagesCfg, languageValues, clanLocations
from "%rGui/clans/components/clanPropertyBtn.nut" import mkClanPropertyBtnWithTitle
from "%rGui/clans/components/chooseValueWnd.nut" import openChooseValueWnd


const MAX_NAME_CHARS = 16
const MAX_DESCRIPTION_CHARS = 256

const badgeSize = hdpx(200)
const campaignIconSize = hdpx(70)
const propertyBtnWidth = hdpx(260)
let propertyBtnSize = [propertyBtnWidth, hdpx(80)]

let mkVerOption = @(label, opt, ovr = {}) {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = hdpx(15)
  children = [
    label
    opt
  ]
}.__update(ovr)

let sectionLabel = @(text, ovr = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontTinyAccented, ovr)

function mkCampaignToggle(key, campaignsW) {
  let bit = Computed(@() serverConfigs.get()?.campaignCfg?[key].bit ?? 0)
  let isActive = Computed(@() (campaignsW.get() & bit.get()) != 0)
  let icon = Picture($"{getCampaignPresentation(key).clanIcon}:{campaignIconSize}:P")

  return @() {
    watch = [isActive, bit]
    size = campaignIconSize
    rendObj = ROBJ_IMAGE
    image = icon
    opacity = isActive.get() ? 1 : 0.3
    behavior = Behaviors.Button
    sound = const { click = "click" }
    onClick = @() campaignsW.set(campaignsW.get() ^ bit.get())
  }
}

let mkTypePropertyRow = @(typeW) @() {
  watch = typeW
  children = mkClanPropertyBtnWithTitle(
    const { locTitle = "clans/type" },
    utf8ToUpper(loc($"clans/type/{typeW.get()}")),
    @() typeW.set(typeW.get() == PRIVACY_OPEN ? PRIVACY_REQUEST
      : PRIVACY_OPEN),
    propertyBtnSize)
}

let mkLocationPropertyRow = @(locationW) @() {
  watch = locationW
  children = mkClanPropertyBtnWithTitle(
    const { locTitle = "clans/location" },
    utf8ToUpper(loc($"region/{locationW.get()}")),
    @() openChooseValueWnd(
      {
        locTitle = "clans/location"
        values = clanLocations.get()
        valToString = @(v) $"region/{v}"
        btnMinWidth = propertyBtnWidth
        col = 4
      },
      locationW,
      @(v) locationW.set(v)),
    propertyBtnSize)
}

let mkLanguagePropertyRow = @(languageW) @() {
  watch = languageW
  children = mkClanPropertyBtnWithTitle(
    const { locTitle = "clans/primaryLanguage" },
    utf8ToUpper(languagesCfg?[languageW.get()].title ?? languageW.get()),
    @() openChooseValueWnd(
      {
        locTitle = "clans/primaryLanguage"
        values = languageValues.get().filter(@(v) v != null)
        valToString = @(v) languagesCfg?[v].title ?? v
        textToUpper = false
        btnMinWidth = propertyBtnWidth
        col = 5
      },
      languageW,
      @(v) languageW.set(v)),
    propertyBtnSize)
}

let mkCampaignsPropertyRow = @(campaignsW) mkVerOption(
  sectionLabel(utf8ToUpper(loc("clans/campaigns"))),
  @() {
    watch = campaignsList
    flow = FLOW_HORIZONTAL
    gap = hdpx(20)
    valign = ALIGN_CENTER
    children = campaignsList.get().map(@(k) mkCampaignToggle(k, campaignsW))
  },
  { gap = hdpx(20) })

return {
  MAX_NAME_CHARS
  MAX_DESCRIPTION_CHARS
  badgeSize
  campaignIconSize
  propertyBtnWidth
  mkVerOption
  sectionLabel
  mkCampaignToggle
  mkTypePropertyRow
  mkLocationPropertyRow
  mkLanguagePropertyRow
  mkCampaignsPropertyRow
}
