from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { defer, setTimeout, resetTimeout } = require("dagor.workcycle")
let { get_time_msec } = require("dagor.time")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { isInDebriefing } = require("%appGlobals/clientState/clientState.nut")
let { havePremium } = require("%rGui/state/profilePremium.nut")
let { serverConfigs } = require("%appGlobals/pServer/servConfigs.nut")
let { curUnit } = require("%appGlobals/pServer/profile.nut")
let { setHangarUnit } = require("%rGui/unit/hangarUnit.nut")
let { registerScene } = require("%rGui/navState.nut")
let { textButtonCommon, textButtonPrimary, buttonsHGap } = require("%rGui/components/textButton.nut")
let { translucentButton } = require("%rGui/components/translucentButton.nut")
let tryPremiumButton = require("%rGui/debriefing/tryPremiumButton.nut")
let { unitPlateWidth, unitPlateHeight, mkUnitBg, mkUnitImage, mkUnitTexts,
  mkPlatoonBgPlates, platoonPlatesGap, mkPlatoonPlateFrame
} = require("%rGui/unit/components/unitPlateComp.nut")
let { lerpClamped } = require("%sqstd/math.nut")
let { getUnitPresentation, getPlatoonName } = require("%appGlobals/unitPresentation.nut")
let { mkLevelBg, mkProgressLevelBg, maxLevelStarChar, playerExpColor, unitExpColor,
  levelProgressBarWidth, levelProgressBarFillWidth
} = require("%rGui/components/levelBlockPkg.nut")
let { WP } = require("%appGlobals/currenciesState.nut")
let { mkCurrencyComp, mkExp, CS_COMMON } = require("%rGui/components/currencyComp.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { premiumTextColor } = require("%rGui/style/stdColors.nut")
let { openUnitAttrWnd } = require("%rGui/unitAttr/unitAttrState.nut")
let { debriefingData } = require("debriefingState.nut")
let { randomBattleMode } = require("%rGui/gameModes/gameModeState.nut")
let { mkDebriefingStats } = require("mkDebriefingStats.nut")
let mpStatisticsStaticWnd = require("%rGui/mpStatistics/mpStatisticsStaticWnd.nut")
let offerMissingUnitItemsMessage = require("%rGui/shop/offerMissingUnitItemsMessage.nut")
let { playSound, startSound, stopSound } = require("sound_wt")
let { requestOpenUnitPurchEffect } = require("%rGui/unit/unitPurchaseEffectScene.nut")
let unitDetailsWnd = require("%rGui/unitDetails/unitDetailsWnd.nut")
let { get_local_custom_settings_blk } = require("blkGetters")

let closeDebriefing = @() send("Debriefing_CloseInDagui", {})
let startBattle = @() send("queueToGameMode", { modeId = randomBattleMode.value?.gameModeId }) //FIXME: Should to use game mode from debriefing

const SAVE_ID_UPGRADE_BUTTON_PUSHED = "debriefingUpgradeButtonPushed"
let countUpgradeButtonPushed = Watched(get_local_custom_settings_blk()?[SAVE_ID_UPGRADE_BUTTON_PUSHED] ?? 0)
let minCountUpgradeButtonPushed = 3

let rowGap = hdpx(32)
let columnGap = hdpx(100)
let contentWidth = hdpx(1200)
let levelBlockSize = hdpx(60)
let resultLineWidth = contentWidth + hdpx(250)
let resultLineHeight = hdpx(9)
let lineGlowHeight = 10 * resultLineHeight
let lineGlowWidth = (201.0 / 84.0 * lineGlowHeight).tointeger()
let totalRewardsVPad = hdpx(20)
let totalRewardsVPadSmall = hdpx(8)
let nextLevelBorderColor = Color(218, 218, 218)
let nextLevelBgColor = Color(71, 71, 70)
let nextLevelTextColor = Color(255, 255, 255)
let levelUpTextColor = Color(0, 0, 0)
let receivedExpProgressColor = Color(255, 255, 255)
let totalRewardsBgColor = 0x94090F16
let totalRewardsPremBgColor = 0x30453103

let resultTextAnimTime = 0.6
let reasonTextDelay = 0.15
let mainMissionResultAnimTime = 1.0
let mainMissionResultVisibleAnimTime = 0.2
let maxLevelProgressAnimTime = 2.0
let levelProgressSingleAnimTime = 1.0
let rewardAnimTime = 0.5
let deltaStartTimeRewards = rewardAnimTime / 2
let deltaStartTimeLevelReward = maxLevelProgressAnimTime/2
let premRewStartTime = 0.35

let CS_DEBRIEFING_REWARD = CS_COMMON.__update({
  fontStyle = fontTinyAccented
})


let missionResultParamsByType = {
  victory = {
    text = @(_) loc("debriefing/victory")
    reason = @(isDestroyed) loc(isDestroyed ? "winReason/destroy" : "winReason/retreat")
    color = Color(255, 183, 11)
    animTextColor = Color(255, 218, 131)
  }
  defeat = {
    text = @(_) loc("debriefing/defeat")
    reason = @(isDestroyed) loc(isDestroyed ? "loseReason/destroy" : "loseReason/retreat")
    color = Color(251, 95, 40)
    animTextColor = Color(255, 160, 127)
  }
  inProgress = {
    text = @(campaign) loc(campaign == "tanks" ? "debriefing/yourPlatoonDestroyed" : "debriefing/yourShipDestroyed")
    color = Color(255, 255, 255)
    animTextColor = Color(255, 255, 255)
  }
  deserter = {
    text = @(_) loc("debriefing/deserter")
    color = Color(251, 95, 40)
    animTextColor = Color(255, 160, 127)
  }
  disconnect = {
    text = @(_) loc("matching/CLIENT_ERROR_CONNECTION_CLOSED")
    color = 0XFFFFA406
    animTextColor = 0XFFFFA406
  }
  unknown = {
    text = @(_) loc("debriefing/dataNotReceived")
    color = Color(255, 255, 255)
    animTextColor = Color(255, 255, 255)
  }
}

let updateHangarUnit = @(unitId) unitId == null ? null : setHangarUnit(unitId)

let toHangarButton = @(campaign) textButtonCommon(
  utf8ToUpper(loc(campaign == "ships" ? "return_to_port/short" : "return_to_hangar/short")),
  closeDebriefing,
  { hotkeys = [btnBEscUp] })
let lvlUpButton = textButtonPrimary(utf8ToUpper(loc("msgbox/btn_get")), closeDebriefing,
  { hotkeys = ["^J:X | Enter"] })
let toBattleButton = textButtonPrimary(utf8ToUpper(loc("mainmenu/toBattle/short")),
  function() {
    offerMissingUnitItemsMessage(curUnit.value, startBattle)
    closeDebriefing()
  },
  { hotkeys = ["^J:X | Enter"] })
let upgradeUnitButton = @(campaign) textButtonCommon(
  utf8ToUpper(loc(campaign == "tanks" ? "mainmenu/btnUpgradePlatoon" : "mainmenu/btnUpgradeShip")),
  function() {
    countUpgradeButtonPushed(countUpgradeButtonPushed.value + 1)
    get_local_custom_settings_blk()[SAVE_ID_UPGRADE_BUTTON_PUSHED] = countUpgradeButtonPushed.value
    send("saveProfile", {})
    updateHangarUnit(debriefingData.value?.unit.name)
    openUnitAttrWnd()
    closeDebriefing()
  },
  { hotkeys = [btnBEscUp] }
)

let mkNewPlatoonUnitButton = @(newPlatoonUnit) textButtonPrimary(utf8ToUpper(loc("msgbox/btn_get")),
  function() {
    closeDebriefing()
    unitDetailsWnd({ name = debriefingData.value?.unit.name, selUnitName = newPlatoonUnit.name })
    requestOpenUnitPurchEffect(newPlatoonUnit)
  },
  { hotkeys = ["^J:X | Enter"] })

let headerText = @(missionResult, campaign, ovr = {}, delay = 0) {
  rendObj = ROBJ_TEXT
  color = missionResult.color
  text = missionResult.text(campaign)
  transform = {}
  animations = [
    {
      prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3],
      duration = resultTextAnimTime, delay, play = true, easing = CosineFull
    }
    {
      prop = AnimProp.color, from = missionResult.color, to = missionResult.animTextColor,
      duration = resultTextAnimTime, delay, play = true, easing = CosineFull
    }
  ]
}.__update(fontBig, ovr)

let function mkMissionResultText(missionResult, isAnyTeamDestroyed, campaign) {
  let reason = missionResult?.reason(isAnyTeamDestroyed)
  if (reason == null)
    return headerText(missionResult, campaign)
  return {
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    children = [
      headerText(missionResult, campaign)
      headerText(missionResult, campaign,
        { text = reason, opacity = 0.7 }.__update(fontSmall),
        reasonTextDelay)
    ]
  }
}

let mkMissionResultLine = @(missionResult) {
  size = [resultLineWidth, resultLineHeight]
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = gradTranspDoubleSideX
  color = missionResult.color
  children = {
    size = [lineGlowWidth, lineGlowHeight]
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture("!ui/gameuiskin#line_glow.avif")
    opacity = 0.0
    transform = {}
    animations = [
      {
        prop = AnimProp.translate, from = [-0.5 * lineGlowWidth, 0], to = [resultLineWidth - lineGlowWidth, 0],
        duration = mainMissionResultAnimTime, play = true
      }
      {
        prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = mainMissionResultVisibleAnimTime,
        play = true
      }
      {
        prop = AnimProp.opacity, from = 1.0, to = 1.0,
        duration = mainMissionResultAnimTime - 2 * mainMissionResultVisibleAnimTime,
        delay = mainMissionResultVisibleAnimTime, play = true
      }
      {
        prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = mainMissionResultVisibleAnimTime,
        delay = mainMissionResultAnimTime - mainMissionResultVisibleAnimTime, play = true
      }
    ]
  }
}

let playerLevelUpText = @(text) {
  size = SIZE_TO_CONTENT
  maxWidth = hdpx(350)
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
  color = 0xFFFFFFFF
}.__update(fontSmall)

let function mkUnitPlate(unit) {
  if (unit == null)
    return null
  let p = getUnitPresentation(unit)
  let platoonUnits = (unit?.platoonUnits ?? []).map(@(u) u.name)
    .extend((unit?.lockedUnits ?? []).map(@(u) u.name))
  let platoonSize = platoonUnits.len()
  let height = platoonSize == 0 ? unitPlateHeight
    : unitPlateHeight + platoonPlatesGap * platoonSize
  return {
    size = [ unitPlateWidth, height ]
    children = {
      size = [ unitPlateWidth, unitPlateHeight ]
      vplace = ALIGN_BOTTOM
      children = platoonSize > 0
        ? [
            mkPlatoonBgPlates(unit, platoonUnits)
            mkUnitBg(unit)
            mkUnitImage(unit)
            mkUnitTexts(unit, getPlatoonName(unit.name, loc))
            mkPlatoonPlateFrame()
          ]
        : [
            mkUnitBg(unit)
            mkUnitImage(unit)
            mkUnitTexts(unit, loc(p.locId))
          ]
    }
  }
}

let mkLevelMark = @(override = {}) {
  size = array(2, levelBlockSize)
  children = [
    mkLevelBg(override?.bgBlock ?? {})
    {
      rendObj = ROBJ_TEXT
      vplace = ALIGN_CENTER
      hplace = ALIGN_CENTER
      pos = [0, -hdpx(2)]
    }.__update(fontSmall, override?.textBlock ?? {})
  ]
}.__update(override?.ovr ?? {})

let mkTextUnderLevelLine = @(text, color, override = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = text
  color
}.__update(fontVeryTiny, override)

let expTextStarSize = hdpx(35)
let mkExpText = @(exp, color) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  gap = hdpx(5)
  children = [
    {
      rendObj = ROBJ_TEXT
      text = $"+ {exp}"
      color
    }.__update(fontTiny)
    {
      size = [expTextStarSize, expTextStarSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/gameuiskin#experience_icon.svg:{expTextStarSize}:{expTextStarSize}")
      color
    }
  ]
}

let stopLevelLineSound = @() stopSound("exp_bar")

let function levelLineSound(soundEndTime) {
  startSound("exp_bar")
  resetTimeout(soundEndTime, stopLevelLineSound)
}

let mkLevelLineProgress = @(curLevelIdxWatch, levelUpsArray, lineColor, animStartTime) function() {
  let { curLevel, isLevelUpCurStep, isLastLevelCurStep, curExpWidth, receivedExpWidth
  } = levelUpsArray[curLevelIdxWatch.value]

  let stepsCount = levelUpsArray.len()
  let levelProgressAnimTime = (stepsCount - 1) == curLevelIdxWatch.value ? levelProgressSingleAnimTime
    : min((maxLevelProgressAnimTime - levelProgressSingleAnimTime) / (stepsCount - 1), levelProgressSingleAnimTime)
  let levelProgressDelay = curLevelIdxWatch.value == 0 ? animStartTime : 0
  let animationTrigger = $"progressFillFinished_{lineColor}"
  return {
    watch = curLevelIdxWatch
    size = [levelProgressBarWidth + 2 * levelBlockSize, SIZE_TO_CONTENT]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    onDetach = stopLevelLineSound
    children = [
      mkProgressLevelBg({
        pos = [levelBlockSize, 0]
        children = [
          {
            key = $"line_{levelUpsArray[curLevelIdxWatch.value]}"
            size = [receivedExpWidth, flex()]
            rendObj = ROBJ_SOLID
            color = receivedExpProgressColor
            transform = { pivot = [0, 0] }
            animations = [
              {
                prop = AnimProp.scale, from = [0.0, 0.0],
                to = [0.0, 0.0], duration = levelProgressDelay,
                play = true
              }
              {
                prop = AnimProp.scale, from = [curExpWidth.tofloat() / (receivedExpWidth || 1), 1.0],
                to = [1.0, 1.0], duration = levelProgressAnimTime, delay = levelProgressDelay,
                easing = InOutQuart, play = true,
                onStart = @() levelLineSound(levelProgressAnimTime),
                onFinish = function() {
                  if (isLevelUpCurStep)
                    anim_start(animationTrigger)
                  if (levelUpsArray.len() > (curLevelIdxWatch.value + 1))
                    curLevelIdxWatch(curLevelIdxWatch.value + 1)
                }
              }
            ]
          }
          {
            size = [curExpWidth, flex()]
            rendObj = ROBJ_SOLID
            color = lineColor
          }
        ]
      })
      mkLevelMark({
        textBlock = { text = curLevel }
        bgBlock = { childOvr = { borderColor = lineColor } }
      })
      mkLevelMark({
        ovr = { hplace = ALIGN_RIGHT }
        textBlock = {
          text = isLastLevelCurStep ? maxLevelStarChar : curLevel + 1
          color = isLevelUpCurStep ? levelUpTextColor : nextLevelTextColor
          animations = [
            {
              prop = AnimProp.color, from = nextLevelTextColor,
              to = nextLevelTextColor, duration = levelProgressDelay + levelProgressAnimTime,
              play = true
            }
            {
              prop = AnimProp.color, from = nextLevelTextColor,
              to = levelUpTextColor, duration = levelProgressAnimTime * 0.5,
              easing = InQuad, trigger = animationTrigger
            }
          ]
        }
        bgBlock = {
          childOvr = {
            fillColor = isLevelUpCurStep ? receivedExpProgressColor : nextLevelBgColor
            borderColor = nextLevelBorderColor
            transform = {}
            animations = [
              {
                prop = AnimProp.fillColor, from = nextLevelBgColor,
                to = nextLevelBgColor, duration = levelProgressDelay + levelProgressAnimTime,
                play = true
              }
              {
                prop = AnimProp.fillColor, from = nextLevelBgColor,
                to = receivedExpProgressColor, duration = levelProgressAnimTime * 0.5,
                easing = InQuad, trigger = animationTrigger
              }
              {
                prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], easing = Blink,
                duration = levelProgressAnimTime * 0.5, trigger = animationTrigger
              }
            ]
          }
        }
      })
    ]
  }
}

let function mkLevelLine(curLevelConfig, reward, text, animStartTime , lineColor = playerExpColor, override = {}) {
  let { exp = 0, level = 1, nextLevelExp = 0, isLastLevel = false, levelsExp = [] } = curLevelConfig
  if (nextLevelExp == 0)
    return null

  let { totalExp = 0 } = reward
  let addExp = clamp(totalExp, 0, max(0, nextLevelExp - exp))
  let isLevelUp = addExp > 0 && nextLevelExp <= (exp + totalExp)
  let levelUpsArray = [{
    curLevel = level
    isLevelUpCurStep = isLevelUp
    isLastLevelCurStep = isLastLevel
    curExpWidth = lerpClamped(0, nextLevelExp, 0, levelProgressBarFillWidth, exp)
    receivedExpWidth = lerpClamped(0, nextLevelExp, 0, levelProgressBarFillWidth, exp + totalExp)
  }]
  if (isLevelUp && levelsExp.len() > 0) {
    local leftReceivedExp = totalExp - addExp
    foreach (idx, levelExp in levelsExp) {
      if (leftReceivedExp <= 0)
        break

      if (level >= idx)
        continue

      levelUpsArray.append({
        curLevel = idx
        isLevelUpCurStep = levelExp <= leftReceivedExp
        isLastLevelCurStep = (idx + 1) not in levelsExp
        curExpWidth = lerpClamped(0, levelExp, 0, levelProgressBarFillWidth, 0)
        receivedExpWidth = lerpClamped(0, levelExp, 0, levelProgressBarFillWidth, leftReceivedExp)
      })
      leftReceivedExp = leftReceivedExp - levelExp
    }
  }
  let fullLevelDelayAnimTime = mainMissionResultAnimTime
   + min(levelUpsArray.len() * levelProgressSingleAnimTime, maxLevelProgressAnimTime)
  let curLevelIdxWatch = Watched(0)
  return {
    size = [unitPlateWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      {
        rendObj = ROBJ_TEXT
        text = text
      }.__update(fontTiny)
      mkLevelLineProgress(curLevelIdxWatch, levelUpsArray, lineColor, animStartTime)
      {
        size = [flex(), SIZE_TO_CONTENT]
        transform = {}
        animations = [
          { prop = AnimProp.opacity, from = 0.0, to = 0.0, play = true duration = fullLevelDelayAnimTime }
          {
            prop = AnimProp.opacity, from = 0.0, to = 1.0, play = true, easing = InQuad
            duration = rewardAnimTime / 2, delay = fullLevelDelayAnimTime
          }
        ]
        children = isLevelUp ? mkTextUnderLevelLine(utf8ToUpper(loc("debriefing/newLevel")), lineColor,
            { animations = [
                {
                  prop = AnimProp.scale, from = [1.0, 1.0], to = [1.3, 1.3], duration = rewardAnimTime,
                  delay = fullLevelDelayAnimTime, easing = CosineFull, play = true, onStart = @() playSound("unit_level_up")
                }
              ]
              transform = { pivot = [1.0, 1.0] } })
          : addExp > 0 ? mkExpText(addExp, lineColor)
          : totalExp > 0 ? mkTextUnderLevelLine(loc("debriefing/lostExp"), lineColor)
          : null
      }
    ]
  }.__update(override)
}

let rewardsRowBg = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  gap = hdpx(50)
  image = gradTranspDoubleSideX
}

let rewardWatches = []
let function getRewardWatchData(idx, val) {
  if (idx >= rewardWatches.len())
    rewardWatches.resize(idx + 1)
  if (rewardWatches[idx] == null)
    rewardWatches[idx] = { watched = Watched(0) }
  rewardWatches[idx].val <- val
  return rewardWatches[idx]
}

let function mkRewardWithAnimation(reward, idx, animStartTime) {
  let { value, contentCtor } = reward
  let valueWatch = getRewardWatchData(idx, value).watched
  if (valueWatch.value != 0 && valueWatch.value != value) //data changed, but animation already finished
    defer(@() valueWatch(value))
  let size = calc_comp_size(contentCtor(value))
  let delayRewardAnim = animStartTime + idx * deltaStartTimeRewards

  return @() {
    watch = valueWatch
    size
    transform = {}
    animations = [
      {
        prop=AnimProp.scale, from =[1.0, 1.0], to = [1.3, 1.3], duration=rewardAnimTime,
        easing = CosineFull, onEnter = @() setTimeout(delayRewardAnim, @() valueWatch(rewardWatches?[idx].val ?? 0)),
        delay = delayRewardAnim,
        play = true,
        onStart = @() playSound("prize"),
      }
    ]
    children = contentCtor(valueWatch.value)
  }
}

let mkAnimatedRewards = @(idxShift, rewards, delayIconAnim) rewards.map(@(r, i) mkRewardWithAnimation(r, i + idxShift, delayIconAnim))

let function mkPlayerLevelLine(data, animStartTime) {
  let { reward = {}, player = {} } = data
  let { playerExp = {} } = reward
  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = mkLevelLine(player, playerExp, loc("debriefing/playerExp"), animStartTime)
  }
}

let function mkUnitLevelLine(data, animStartTime) {
  let { reward = {}, unit = null, campaign = "" } = data
  let { unitExp = {} } = reward
  return {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    children = mkLevelLine(unit, unitExp,
      loc(campaign == "tanks" ? "debriefing/platoonExp" : "debriefing/shipExp"),animStartTime,  unitExpColor)
  }
}

let mkUnitPlateBlock = @(unit) {
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  children = mkUnitPlate(unit)
}

let function getRewardsInfo(data) {
  let { reward = {}, player = {}, unit = null, premiumBonus = null, sessionId = null } = data
  let { unitExp = {}, playerExp = {}, playerWp = {} } = reward
  let hasPlayerExpProgress = (player?.nextLevelExp ?? 0) > 0
  let hasUnitExpProgress = (unit?.nextLevelExp ?? 0) > 0
  let totalPlayerExp = hasPlayerExpProgress ? max(0, playerExp?.totalExp ?? 0) : 0
  let totalUnitExp = hasUnitExpProgress ? max(0, unitExp?.totalExp ?? 0) : 0
  let totalWp = max(0, playerWp?.totalWp ?? 0)
  let needShowRewards = totalPlayerExp > 0 || totalUnitExp > 0 || totalWp > 0

  let isPremiumIncluded = (premiumBonus?.expMul ?? 1.0) > 1.0 || (premiumBonus?.wpMul ?? 1.0) > 1.0
  let isMultiplayerMission = sessionId != null

  let premiumBonusesCfg = serverConfigs.value?.gameProfile.premiumBonuses
  let premMulExp = premiumBonusesCfg?.expMul ?? 1.0
  let premMulWp = premiumBonusesCfg?.wpMul ?? 1.0

  let teaserPlayerExp = isPremiumIncluded ? totalPlayerExp : max(0, totalPlayerExp * premMulExp)
  let teaserUnitExp = isPremiumIncluded ? totalUnitExp : max(0, totalUnitExp * premMulExp)
  let teaserWp = isPremiumIncluded ? totalWp : max(0, totalWp * premMulWp).tointeger()
  let needShowPremiumTeaser = needShowRewards && !isPremiumIncluded && isMultiplayerMission
    && (teaserPlayerExp > totalPlayerExp || teaserUnitExp > totalUnitExp || teaserWp > totalWp)

  return {
    needShowRewards
    totalPlayerExp
    totalUnitExp
    totalWp
    isPremiumIncluded
    needShowPremiumTeaser
    teaserPlayerExp
    teaserUnitExp
    teaserWp
  }
}

let function mkContentBlock(data, rewardsInfo) {
  if (data == null)
    return null

  let { unit = null } = data
  let { needShowRewards, isPremiumIncluded, needShowPremiumTeaser,
    totalPlayerExp, totalUnitExp, totalWp,
    teaserPlayerExp, teaserUnitExp, teaserWp } = rewardsInfo

  let totalRewardsCtors = [
    totalPlayerExp <= 0 ? null : { value = totalPlayerExp, contentCtor = @(value) mkExp(value, playerExpColor, CS_DEBRIEFING_REWARD) }
    totalUnitExp <= 0 ? null : { value = totalUnitExp, contentCtor = @(value) mkExp(value, unitExpColor, CS_DEBRIEFING_REWARD) }
    totalWp <= 0 ? null : { value = totalWp, contentCtor = @(value) mkCurrencyComp(value, WP, CS_DEBRIEFING_REWARD) }
  ].filter(@(v) v != null)
  let premTeaserRewardsCtors = [
    teaserPlayerExp <= 0 ? null : { value = teaserPlayerExp, contentCtor = @(value) mkExp(value, playerExpColor, CS_DEBRIEFING_REWARD) }
    teaserUnitExp <= 0 ? null : { value = teaserUnitExp, contentCtor = @(value) mkExp(value, unitExpColor, CS_DEBRIEFING_REWARD) }
    teaserWp <= 0 ? null : { value = teaserWp, contentCtor = @(value) mkCurrencyComp(value, WP, CS_DEBRIEFING_REWARD) }
  ].filter(@(v) v != null)

  let { statsAnimEndTime, debriefingStats } = mkDebriefingStats(data, get_time_msec() + mainMissionResultAnimTime * 1000)
  let rewardsStartTime = statsAnimEndTime + deltaStartTimeLevelReward

  let totalRewardsCompsArr = mkAnimatedRewards(0, totalRewardsCtors, rewardsStartTime)
  let premTeaserRewardsCompsArr = mkAnimatedRewards(totalRewardsCtors.len(), premTeaserRewardsCtors, premRewStartTime + rewardsStartTime)


  return {
    size = [contentWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = columnGap
        children = [
          debriefingStats
          unit == null ? null : mkUnitPlateBlock(unit)
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        padding = [hdpx(22), 0, 0, 0]
        gap = columnGap
        children = [
          mkPlayerLevelLine(data, statsAnimEndTime)
          unit == null ? null : mkUnitLevelLine(data, statsAnimEndTime)
        ]
      }
      !needShowRewards
        ? null
        : {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            gap = hdpx(10)
            children = [
              {
                rendObj = ROBJ_TEXT
                text = loc(isPremiumIncluded ? "debriefing/battleReward/withPremium" : "debriefing/battleReward")
              }.__update(fontTinyAccented)
              rewardsRowBg.__merge({
                padding = [needShowPremiumTeaser ? totalRewardsVPadSmall : totalRewardsVPad, 0]
                color = totalRewardsBgColor
                children = totalRewardsCompsArr
              })
              !needShowPremiumTeaser
                ? null
                : {
                    rendObj = ROBJ_TEXT
                    text = loc("debriefing/battleReward/premiumNotEarned")
                    color = premiumTextColor
                  }.__update(fontTinyAccented)
              !needShowPremiumTeaser
                ? null
                : rewardsRowBg.__merge({
                    padding = [totalRewardsVPadSmall, 0]
                    color = totalRewardsPremBgColor
                    children = premTeaserRewardsCompsArr
                  })
            ]
          }
    ]
  }
}

let function isUnitReceiveLevel(data) {
  let { totalExp = 0 } = data?.reward.unitExp
  let { exp = 0, nextLevelExp = 0 } = data?.unit
  if (nextLevelExp <= 0 || totalExp <= 0)
    return false
  return exp + totalExp >= nextLevelExp
}

let function openMpStatistics() {
  let { campaign = "", userId = 0, userName = "", localTeam = 0, players = {}, playersCommonStats = {} } = debriefingData.value
  let mplayersList = players.values().map(function(p) {
    let isLocal = p.userId == userId
    let pUserIdStr = p.userId.tostring()
    let { level = 1, hasPremium = false } = playersCommonStats?[pUserIdStr]
    let pUnit = playersCommonStats?[pUserIdStr].unit
    let mainUnitName = pUnit?.name ?? (p.aircraftName ?? "")
    let isUnitPremium = pUnit?.isPremium ?? false
    return p.__merge({
      userId = pUserIdStr
      isLocal
      isDead = false
      name = isLocal ? userName
        : p.isBot ? loc(p.name)
        : p.name
      score = p?.dmgScoreBonus ?? 0.0
      level
      hasPremium
      isUnitPremium
      mainUnitName
    })
  })
  let teamsOrder = localTeam == 2 ? [ 2, 1 ] : [ 1, 2 ]
  let playersByTeam = teamsOrder.map(@(team) mplayersList.filter(@(v) v.team == team))
  mpStatisticsStaticWnd({ playersByTeam, campaign, title = loc("debriefing/players_stats") })
}

let function getNewPlatoonUnit(debrData) {
  let { unit = null, reward = null } = debrData
  let { level = 0, exp = 0, levelsExp = [], lockedUnits = [] } = unit
  let { totalExp = 0 } = reward?.unitExp
  if (totalExp == 0 || lockedUnits.len() == 0)
    return null
  local pReqLevel = -1
  local pUnitName = null
  foreach(pUnit in lockedUnits) {
    let { reqLevel = 0, name } = pUnit
    if (reqLevel > level && (pUnitName == null || reqLevel < pReqLevel)) {
      pReqLevel = reqLevel
      pUnitName = name
    }
  }
  if (pUnitName == null || levelsExp.len() < pReqLevel)
    return null

  local leftExp = totalExp + exp
  for (local l = level; l < pReqLevel; l++)
    leftExp -= levelsExp[l]
  return leftExp >= 0 ? unit.__merge({ name = pUnitName }) : null
}

let function debriefingWnd() {
  let { reward = {}, player = {}, isWon = false, isFinished = false, isDeserter = false, isDisconnected = false,
    teams = [], campaign = "", players = {}
  } = debriefingData.value
  let { exp = 0, nextLevelExp = 0 } = player
  let hasLevelUp = nextLevelExp != 0 && (nextLevelExp <= (exp + (reward?.playerExp.totalExp ?? 0)))
  let missionResult = debriefingData.value == null ? missionResultParamsByType.unknown
    : isDisconnected ? missionResultParamsByType.disconnect
    : isDeserter ? missionResultParamsByType.deserter
    : !isFinished ? missionResultParamsByType.inProgress
    : isWon ? missionResultParamsByType.victory
    : missionResultParamsByType.defeat
  let isAnyTeamDestroyed = null != teams.findvalue(@(t) (t?.tickets ?? 0) == 0)
  let rewardsInfo = getRewardsInfo(debriefingData.value)
  let newPlatoonUnit = getNewPlatoonUnit(debriefingData.value)
  return bgShaded.__merge({
    watch = debriefingData
    key = debriefingData
    onAttach = function() {
      updateHangarUnit(reward?.unitName)
      playSound(isWon ? "stats_winner_start" : "stats_looser_start")
    }
    size = flex()
    padding = saBordersRv
    children = [
      {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        hplace = ALIGN_CENTER
        gap = rowGap
        children = [
          mkMissionResultText(missionResult, isAnyTeamDestroyed, campaign)
          mkMissionResultLine(missionResult)
          mkContentBlock(debriefingData.value, rewardsInfo)
        ]
      }
      players.len() == 0 ? null : {
        hplace = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        children = translucentButton("ui/gameuiskin#menu_stats.svg", "", openMpStatistics)
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        vplace = ALIGN_BOTTOM
        flow = FLOW_VERTICAL
        gap = hdpx(60)
        children = [
          !rewardsInfo.needShowPremiumTeaser
            ? null
            : @() havePremium.value ? { watch = havePremium } : {
                watch = havePremium
                hplace = ALIGN_RIGHT
                children = tryPremiumButton()
              }
          {
            watch = countUpgradeButtonPushed
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_RIGHT
            flow = FLOW_HORIZONTAL
            gap = buttonsHGap
            children = hasLevelUp ? [
                  playerLevelUpText(loc("levelUp/playerLevelUp"))
                  lvlUpButton
                ]
              : newPlatoonUnit != null ? [
                  playerLevelUpText(loc("levelUp/receiveNewPlatoonUnit"))
                  mkNewPlatoonUnitButton(newPlatoonUnit)
                ]
              : isUnitReceiveLevel(debriefingData.value) ? [
                  upgradeUnitButton(campaign)
                  { size = flex() }
                  minCountUpgradeButtonPushed <= countUpgradeButtonPushed.value
                    ? toBattleButton
                    : null
                ]
              : [
                  toHangarButton(campaign)
                  { size = flex() }
                  toBattleButton
                ]
          }
        ]
      }
    ]
  })
}

isInDebriefing.subscribe(@(_) rewardWatches.clear())
registerScene("debriefingWnd", debriefingWnd, closeDebriefing, isInDebriefing)
