from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let backButton = require("%rGui/components/backButton.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM, mkRewardPlate
} = require("%rGui/rewards/rewardPlateComp.nut")

let dbgRewardsTbl = {
  gold = 9999
  wp = 10000
  premiumDays = 14
  items = {
    ship_tool_kit = 50
    ship_smoke_screen_system_mod = 50
    tank_tool_kit_expendable = 50
    tank_extinguisher = 50
    spare = 50
  }
  lootboxes = {
    every_day_award_big_pack_1 = 3
    every_day_award_small_pack = 3
  }
  decorators = [
    "cardicon_crosspromo"
    "captain-lieutenant"
    "pilot"
    "cannon"
    "bullet"
  ]
  units = [
    "uk_battlecruiser_invincible"
  ]
  unitUpgrades = [
    "fr_panhard_ebr_1951"
  ]
}

let dbgRewardsInfo = getRewardsViewInfo(dbgRewardsTbl).sort(sortRewardsViewInfo)

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened(false)

let wndHeaderHeight = hdpx(60)
let wndHeaderGap = hdpx(30)
let wndHeader = {
  size = [flex(), wndHeaderHeight]
  valign = ALIGN_CENTER
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = "ui.debug.reward_plate_comp"
      margin = [0, 0, 0, hdpx(15)]
    }.__update(fontBig)
  ]
}

let mkRewardPlateCompsByStyle = @(rStyle) {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  margin = hdpx(50)
  flow = FLOW_HORIZONTAL
  children = wrap(dbgRewardsInfo.map(@(r) mkRewardPlate(r, rStyle))
    { width = saSize[0], hGap = rStyle.boxGap, vGap = rStyle.boxGap })
}

let wndContentHeight = saSize[1] - wndHeaderHeight - wndHeaderGap
let wndContent = verticalPannableAreaCtor(wndContentHeight, [hdpx(30), hdpx(30)])({
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    REWARD_STYLE_SMALL
    REWARD_STYLE_MEDIUM
  ].map(@(rStyle) mkRewardPlateCompsByStyle(rStyle))
})

let debugRewardPlateCompWnd = bgShaded.__merge({
  key = isOpened
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  gap = wndHeaderGap
  children = [
    wndHeader
    wndContent
  ]
  animations = wndSwitchAnim
})

registerScene("debugRewardPlateCompWnd", debugRewardPlateCompWnd, close, isOpened)

register_command(@() isOpened(true), "ui.debug.reward_plate_comp")