from "%globalsDarg/darg_library.nut" import *
let { HangarCameraControl } = require("wt.behaviors")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene } = require("%rGui/navState.nut")
let { isLvlUpOpened, upgradeUnitName, closeLvlUpWnd } = require("levelUpState.nut")
let { buyUnitsData } = require("%appGlobals/unitsState.nut")
let { WP, GOLD } = require("%appGlobals/currenciesState.nut")
let { mkCurrencyBalance } = require("%rGui/mainMenu/balanceComps.nut")
let { CS_GAMERCARD } = require("%rGui/components/currencyStyles.nut")
let { levelUpFlag, flagAnimFullTime, flagHeight } = require("levelUpFlag.nut")
let { mkLinearGradientImg } = require("%darg/helpers/mkGradientImg.nut")
let levelUpChooseUnits = require("levelUpChooseUnits.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { hasAddons, addonsSizes } = require("%appGlobals/updater/addonsState.nut")
let { getUnitPkgs } = require("%appGlobals/updater/campaignAddons.nut")
let { localizeAddons, getAddonsSizeStr } = require("%appGlobals/updater/addons.nut")
let { textButtonBattle } = require("%rGui/components/textButton.nut")
let { openDownloadAddonsWnd } = require("%rGui/updater/updaterState.nut")
let { maxRewardLevelInfo } = require("%rGui/levelUp/levelUpState.nut")
let { sendNewbieBqEvent } = require("%appGlobals/pServer/bqClient.nut")


let headerLineColor = 0xFFFFB70B
let lineTexW = hdpx(100)
let lineSize = [hdpx(800) * 2, hdpx(4)]

let animStartDelay = 0.3
let lineAnimTime = 0.5
let balanceAppearDelay = animStartDelay + flagAnimFullTime
let balanceAppearTime = 2.0

let lineGradient = mkLinearGradientImg({
  points = [{ offset = 0, color = colorArr(0) }, { offset = 100, color = colorArr(headerLineColor) }]
  width = lineTexW
  height = 4
  x1 = 0
  y1 = 0
  x2 = lineTexW
  y2 = 0
})

let headerLine = @(delay) {
  size = lineSize
  pos = [0, ph(20)]
  vplace = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    {
      size = flex()
      rendObj = ROBJ_IMAGE
      image = lineGradient
    }
    {
      size = flex()
      rendObj = ROBJ_IMAGE
      image = lineGradient
      flipX = true
    }
  ]
  transform = {}
  animations = [
    { prop = AnimProp.scale, from = [0, 0], to = [0, 0], duration = delay, play = true }
    { prop = AnimProp.scale, from = [0, 0], to = [1, 1], delay, duration = lineAnimTime,
      easing = OutQuad, play = true }
  ]
}

function closeByBackButton() {
  sendNewbieBqEvent("pressBackInLevelUpWnd")
  closeLvlUpWnd()
}

let wpStyle = CS_GAMERCARD.__merge({ iconKey = "levelUpWp" })
let goldStyle = CS_GAMERCARD.__merge({ iconKey = "levelUpGold" })
let headerPanel = @(hasLvlUpPkgs) @() {
  watch = maxRewardLevelInfo
  size = FLEX_H
  halign = ALIGN_CENTER
  children = [
    @() {
      watch = upgradeUnitName
      hplace = ALIGN_LEFT
      children = upgradeUnitName.get() != null ? backButton(@() upgradeUnitName(null))
        : !hasLvlUpPkgs ? backButton(closeByBackButton)
        : null
    }
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      gap = hdpx(70)
      children = [
        mkCurrencyBalance(WP, null, wpStyle)
        mkCurrencyBalance(GOLD, null, goldStyle)
      ]
      transform = {}
      animations = appearAnim(balanceAppearDelay, balanceAppearTime)
    }
    headerLine(animStartDelay)
    levelUpFlag(flagHeight, maxRewardLevelInfo.get().level, maxRewardLevelInfo.get().starLevel, animStartDelay)
  ]
}

let levelUpRequirePkgDownload = @(lvlUpUnitsPkgs) {
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = [
    @() {
      watch = addonsSizes
      size = const [hdpx(600), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = loc("msg/needDownloadPackForLevelUp", {
        pkg = localizeAddons(lvlUpUnitsPkgs)?[0] ?? "???"
        size = getAddonsSizeStr(lvlUpUnitsPkgs, addonsSizes.get())
      })
      fontFxColor = Color(0, 0, 0, 255)
      fontFxFactor = 50
      fontFx = FFT_GLOW
    }.__update(fontSmall)
    textButtonBattle(utf8ToUpper(loc("msgbox/btn_download")),
      @() openDownloadAddonsWnd(lvlUpUnitsPkgs, "level_up_wnd",
        { paramInt1 = buyUnitsData.get().canBuyOnLvlUp.findvalue(@(_) true)?.mRank ?? 0 }))
  ]
}

function levelUpWnd() {
  let lvlUpUnitsPkgs = buyUnitsData.get().canBuyOnLvlUp
    .reduce(function(res, u) {
        let pkgs = getUnitPkgs(u.name, u.mRank)
        foreach (pkg in pkgs)
          res[pkg] <- true
        return res
      }, {})
    .keys()
    .filter(@(v) !hasAddons.get()?[v])
  let hasLvlUpPkgs = lvlUpUnitsPkgs.len() == 0

  return {
    watch = [upgradeUnitName, buyUnitsData, hasAddons]
    key = isLvlUpOpened
    onAttach = @() sendNewbieBqEvent("openLevelUpWnd")
    onDetach = @() sendNewbieBqEvent("closeLevelUpWnd")
    size = flex()
    padding = saBordersRv
    behavior = HangarCameraControl
    touchMarginPriority = TOUCH_BACKGROUND
    flow = FLOW_VERTICAL
    children = [
      headerPanel(hasLvlUpPkgs)
      hasLvlUpPkgs ? levelUpChooseUnits
        : levelUpRequirePkgDownload(lvlUpUnitsPkgs)
    ]
  }.__update(upgradeUnitName.get() != null ? bgShaded : {})
}

registerScene("levelUpWnd", levelUpWnd, closeLvlUpWnd, isLvlUpOpened)
