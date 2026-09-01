from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%rGui/event/eventState.nut" import allSpecialEvents
from "%rGui/rewards/rewardStyles.nut" import getRewardPlateSize, REWARD_STYLE_TINY
from "%rGui/unit/components/unitPlateComp.nut" import mkPlateText, mkPlateTextTimer, mkUnitBg, mkUnitImage


const padding = hdpx(5)
const iconSize = hdpxi(90)

function calcMaxTextWidth(slots, styles) {
  let size = getRewardPlateSize(slots, styles)
  return size[0] - 2 * padding - styles.markSize
}

let mkNameText = @(nameLoc) mkPlateText(nameLoc, fontTiny).__update({
  behavior = Behaviors.Marquee
  speed = hdpx(30)
  delay = defMarqueeDelay
})


let mkBattleModCommonText = @(battleMod, _, __) {
  size = FLEX
  padding
  clipChildren = true
  halign = ALIGN_RIGHT
  children = mkNameText(loc(battleMod.locId)).__update({ size = FLEX_H })
}

let mkBattleModCommonImage = @(battleMod, styles, slots = 1) {
  size = getRewardPlateSize(slots, styles)
  children = {
    size = const [iconSize, iconSize]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{battleMod.icon}:{iconSize}:{iconSize}")
  }
}

function mkBattleModEventUnitText(battleMod, styles = REWARD_STYLE_TINY, slots = 1) {
  let eventEndsAt = Computed(@() allSpecialEvents.get().findvalue(@(event) event.eventName == battleMod.eventId)?.endsAt ?? -1)
  let unit = battleMod.unitCtor()

  return @() {
    watch = eventEndsAt
    size = FLEX
    padding
    clipChildren = true
    halign = ALIGN_RIGHT
    children = [
      mkNameText(getUnitName(unit.name)).__update({ maxWidth = calcMaxTextWidth(slots, styles) })
      mkPlateTextTimer(eventEndsAt.get(),{ vplace = ALIGN_BOTTOM })
    ]
  }
}

function mkBattleModRewardUnitImage(battleMod, styles, slots = 1) {
  let unit = battleMod.unitCtor()
  return {
    size = getRewardPlateSize(slots, styles)
    children = [
      mkUnitBg(unit)
      mkUnitImage(unit)
    ]
  }
}

return {
  mkBattleModCommonText,
  mkBattleModCommonImage,
  mkBattleModEventUnitText,
  mkBattleModRewardUnitImage
}