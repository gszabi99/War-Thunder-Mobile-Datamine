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
let levelUpChooseUpgrade = require("levelUpChooseUpgrade.ui.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let hasAddons = require("%appGlobals/updater/hasAddons.nut")
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

let lvlUpUnitsPkgs = Computed(@() buyUnitsData.value.canBuyOnLvlUp
  .reduce(function(res, u) {
      let pkgs = getUnitPkgs(u.name, u.mRank)
      foreach (pkg in pkgs)
        res[pkg] <- true
      return res
    }, {})
  .keys()
  .filter(@(v) !hasAddons.value?[v]))
let hasLvlUpPkgs = Computed(@() lvlUpUnitsPkgs.value.len() == 0)

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
let headerPanel = @() {
  watch = maxRewardLevelInfo
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  children = [
    @() {
      watch = [upgradeUnitName, hasLvlUpPkgs]
      hplace = ALIGN_LEFT
      children = upgradeUnitName.value != null ? backButton(@() upgradeUnitName(null))
        : !hasLvlUpPkgs.value ? backButton(closeByBackButton)
        : null
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
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
    levelUpFlag(flagHeight, maxRewardLevelInfo.value.level, maxRewardLevelInfo.value.starLevel, animStartDelay)
  ]
}

let levelUpRequirePkgDownload = {
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = hdpx(40)
  children = [
    @() {
      watch = lvlUpUnitsPkgs
      size = [hdpx(600), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      color = 0xFFFFFFFF
      text = loc("msg/needDownloadPackForLevelUp", {
        pkg = localizeAddons(lvlUpUnitsPkgs.value)?[0] ?? "???"
        size = getAddonsSizeStr(lvlUpUnitsPkgs.value)
      })
      fontFxColor = Color(0, 0, 0, 255)
      fontFxFactor = 50
      fontFx = FFT_GLOW
    }.__update(fontSmall)
    textButtonBattle(utf8ToUpper(loc("msgbox/btn_download")), @() openDownloadAddonsWnd(lvlUpUnitsPkgs.value))
  ]
}

let levelUpWnd = @() {
  watch = [upgradeUnitName, hasLvlUpPkgs]
  key = isLvlUpOpened
  onAttach = @() sendNewbieBqEvent("openLevelUpWnd")
  onDetach = @() sendNewbieBqEvent("closeLevelUpWnd")
  size = flex()
  padding = saBordersRv
  behavior = HangarCameraControl
  eventPassThrough = true //compatibility with 2024.09.26 (before touchMarginPriority introduce)
  touchMarginPriority = TOUCH_BACKGROUND
  flow = FLOW_VERTICAL
  children = [
    headerPanel
    upgradeUnitName.value != null ? levelUpChooseUpgrade
      : hasLvlUpPkgs.value ? levelUpChooseUnits
      : levelUpRequirePkgDownload
  ]
}.__update(upgradeUnitName.value != null ? bgShaded : {})

registerScene("levelUpWnd", levelUpWnd, closeLvlUpWnd, isLvlUpOpened)
