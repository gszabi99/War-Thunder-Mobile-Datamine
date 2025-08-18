from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { getRewardsViewInfo, sortRewardsViewInfo } = require("%rGui/rewards/rewardViewInfo.nut")
let { REWARD_STYLE_SMALL, REWARD_STYLE_MEDIUM, mkRewardPlate
} = require("%rGui/rewards/rewardPlateComp.nut")

let dbgRewardsTbl = []

function apendDbgRewards(gType, list) {
  if (type(list) == "table")
    foreach(id, count in list)
      dbgRewardsTbl.append({ gType, id, count, subId = "" })
  else
    foreach(id in list)
      dbgRewardsTbl.append({ gType, id, count = 0, subId = "" })
}

apendDbgRewards("premium", { [""] = 14 })

apendDbgRewards("currency", {
  gold = 9999
  wp = 10000
  warbond = 100
  eventKey = 50
})

apendDbgRewards("item", {
  ship_tool_kit = 50
  ship_smoke_screen_system_mod = 50
  tank_tool_kit_expendable = 50
  tank_extinguisher = 50
  spare = 50
  firework_kit = 3
  ircm_kit = 3
})
apendDbgRewards("lootbox", {
  every_day_award_big_pack_1 = 3
  every_day_award_first = 3
})
apendDbgRewards("decorator", [
  "cardicon_crosspromo"
  "captain-lieutenant"
  "pilot"
  "cannon"
  "bullet"
])
apendDbgRewards("unit", [
  "ussr_sub_pr641"
  "ussr_t_34_85_d_5t"
])
apendDbgRewards("unitUpgrade", [
  "uk_destroyer_tribal"
  "ussr_t_34_85_d_5t"
])

let dbgRewardsInfo = getRewardsViewInfo(dbgRewardsTbl).sort(sortRewardsViewInfo)

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened.set(false)

let opacityGradientSize = saBorders[1]
let wndHeaderHeight = hdpx(60)
let wndContentWidth = saSize[0]
let wndContentHeight = saSize[1] - wndHeaderHeight + opacityGradientSize

let wndHeader = {
  size = [flex(), wndHeaderHeight]
  valign = ALIGN_CENTER
  children = [
    backButton(close)
    {
      rendObj = ROBJ_TEXT
      size = FLEX_H
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = "ui.debug.reward_plate_comp"
      margin = const [0, 0, 0, hdpx(15)]
    }.__update(fontBig)
  ]
}

let mkRewardPlateCompsByStyle = @(rStyle) {
  size = FLEX_H
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = wrap(dbgRewardsInfo.map(@(r) mkRewardPlate(r, rStyle)),
    { flow = FLOW_HORIZONTAL, width = wndContentWidth, hGap = rStyle.boxGap, vGap = rStyle.boxGap })
}

let pannableArea = verticalPannableAreaCtor(wndContentHeight, [opacityGradientSize, opacityGradientSize])
let mkWndContent = @() pannableArea({
  size = FLEX_H
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  children = [
    REWARD_STYLE_SMALL
    REWARD_STYLE_MEDIUM
  ].map(@(rStyle) mkRewardPlateCompsByStyle(rStyle))
})

let mkDebugRewardPlateCompWnd = @() bgShaded.__merge({
  key = isOpened
  size = flex()
  padding = saBordersRv
  flow = FLOW_VERTICAL
  children = [
    wndHeader
    mkWndContent()
  ]
  animations = wndSwitchAnim
})

registerScene("debugRewardPlateCompWnd", mkDebugRewardPlateCompWnd, close, isOpened)

register_command(@() isOpened.set(true), "ui.debug.reward_plate_comp")
