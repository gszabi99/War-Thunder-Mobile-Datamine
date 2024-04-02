from "%globalsDarg/darg_library.nut" import *
let { specialEvents } = require("%rGui/event/eventState.nut")
let { getUnitLocId } = require("%appGlobals/unitPresentation.nut")
let {
  mkPlateText,
  mkPlateTextTimer,
  mkUnitBg,
  mkUnitImage
} = require("%rGui/unit/components/unitPlateComp.nut")
let { getRewardPlateSize, REWARD_STYLE_TINY } = require("%rGui/rewards/rewardStyles.nut")

function mkBattleModEventUnitText(battleMod, styles = REWARD_STYLE_TINY, slots = 1) {
  let eventEndsAt = Computed(@() specialEvents.value.findvalue(@(event) event.eventName == battleMod.eventId)?.endsAt ?? -1)

  let unit = battleMod.unitCtor()
  let size = getRewardPlateSize(slots, styles)
  let padding = [hdpx(5), hdpx(5)]
  let maxTextWidth = size[0] - 2 * padding[1] - styles.markSize
  let unitNameLoc = loc(getUnitLocId(unit.name))

  local nameText = mkPlateText(unitNameLoc, fontTiny).__update({
    behavior = Behaviors.Marquee,
    maxWidth = maxTextWidth,
    speed = hdpx(30),
    delay = defMarqueeDelay
  })

  return @() {
    size = flex()
    padding
    clipChildren = true
    watch = eventEndsAt
    halign = ALIGN_RIGHT
    children = [
      nameText
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
  mkBattleModEventUnitText,
  mkBattleModRewardUnitImage
}