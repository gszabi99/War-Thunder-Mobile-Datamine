from "%globalsDarg/darg_library.nut" import *
let { allSpecialEvents } = require("%rGui/event/eventState.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let {
  mkPlateText,
  mkPlateTextTimer,
  mkUnitBg,
  mkUnitImage
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getRewardPlateSize, REWARD_STYLE_TINY } = require("%rGui/rewards/rewardStyles.nut")

let padding = [hdpx(5), hdpx(5)]
let iconSize = hdpxi(90)

function calcMaxTextWidth(slots, styles) {
  let size = getRewardPlateSize(slots, styles)
  return size[0] - 2 * padding[1] - styles.markSize
}

let mkNameText = @(nameLoc) mkPlateText(nameLoc, fontTiny).__update({
  behavior = Behaviors.Marquee
  speed = hdpx(30)
  delay = defMarqueeDelay
})


let mkBattleModCommonText = @(battleMod, _, __) {
  size = flex()
  padding
  clipChildren = true
  halign = ALIGN_RIGHT
  children = mkNameText(loc(battleMod.locId)).__update({ size = [flex(), SIZE_TO_CONTENT] })
}

let mkBattleModCommonImage = @(battleMod, styles, slots = 1) {
  size = getRewardPlateSize(slots, styles)
  children = {
    size = [iconSize, iconSize]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{battleMod.icon}:{iconSize}:{iconSize}")
  }
}

function mkBattleModEventUnitText(battleMod, styles = REWARD_STYLE_TINY, slots = 1) {
  let eventEndsAt = Computed(@() allSpecialEvents.value.findvalue(@(event) event.eventName == battleMod.eventId)?.endsAt ?? -1)
  let unit = battleMod.unitCtor()

  return @() {
    watch = eventEndsAt
    size = flex()
    padding
    clipChildren = true
    halign = ALIGN_RIGHT
    children = [
      mkNameText(loc(getUnitLocId(unit.name))).__update({ maxWidth = calcMaxTextWidth(slots, styles) })
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