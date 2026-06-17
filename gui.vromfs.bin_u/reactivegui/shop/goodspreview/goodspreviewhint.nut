from "%globalsDarg/darg_library.nut" import *
let { G_CURRENCY, G_ITEM, G_DECAL, G_SKIN, G_DECORATOR } = require("%appGlobals/rewardType.nut")
let { getUnitName } = require("%appGlobals/unitPresentation.nut")
let { getSkinPresentation } = require("%appGlobals/config/skinPresentation.nut")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let getAvatarImage = require("%appGlobals/decorators/avatars.nut")
let { simpleHorGrad } = require("%rGui/style/gradients.nut")
let { allDecorators } = require("%rGui/decorators/decoratorState.nut")
let { mkDecalIcon } = require("%rGui/unitCustom/unitDecals/unitDecalsComps.nut")
let { getEventLoc, MAIN_EVENT_ID, eventSeason, allSpecialEvents } = require("%rGui/event/eventState.nut")


let hintPadding = hdpx(10)
let decalIconSize = [hdpxi(600), hdpxi(300)]
let avatarSize = hdpxi(250)
let skinIconSize = hdpxi(100)
let skinBorderRadius = (skinIconSize * 0.2 + 0.5).tointeger()

let activeRewardInfo = Watched(null)

let decoratorHintImageCtors = {
  avatar = @(id) {
    size = avatarSize
    rendObj = ROBJ_IMAGE
    image = Picture($"{getAvatarImage(id)}:0:P")
  }

  title = @(id) { rendObj = ROBJ_TEXT, text = loc($"title/{id}") }.__update(fontSmall)

  nickFrame = @(id) {
    rendObj = ROBJ_TEXT
    text = frameNick("", id)
  }.__update(fontLarge)
}

let decoratorHint = @(r) function() {
  let { dType = "" } = allDecorators.get()?[r.id]
  return {
    watch = allDecorators
    flow = FLOW_VERTICAL
    gap = hintPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc($"decorator/{dType}")
      }.__update(fontTiny)
      decoratorHintImageCtors?[dType](r.id)
    ]
  }
}

let itemOrCurrnecyHint = @(r) @() {
  watch = [eventSeason, allSpecialEvents]
  size = const [hdpx(500), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = "\n".concat(
    colorize(0xFFFFFFFF, loc($"item/{r.id}",
      { name = getEventLoc(MAIN_EVENT_ID, eventSeason.get(), allSpecialEvents.get()) })),
    loc($"item/{r.id}/desc")
  )
  color = 0xFFD0D0D0
}.__update(fontTiny)

let decalHint = @(r) mkDecalIcon(r.id, decalIconSize).__update({ imageHalign = ALIGN_LEFT })

let skinHint = @(r) {
  flow = FLOW_VERTICAL
  gap = hintPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("reward/skin_for", { unitName = getUnitName(r.id) })
    }.__update(fontTiny)
    {
      size = skinIconSize
      rendObj = ROBJ_BOX
      fillColor = 0xFFFFFFFF
      borderRadius = skinBorderRadius
      image = Picture($"ui/gameuiskin#{getSkinPresentation(r.id, r.subId).image}:{skinIconSize}:P")
    }
  ]
}

let rewardHintCtors = {
  [G_CURRENCY] = itemOrCurrnecyHint,
  [G_ITEM] = itemOrCurrnecyHint,
  [G_DECAL] = decalHint,
  [G_SKIN] = skinHint,
  [G_DECORATOR] = decoratorHint,
}

function activeRewardHint() {
  let ctor = rewardHintCtors?[activeRewardInfo.get()?.rType]
  if (ctor == null)
    return { watch = activeRewardInfo }
  return {
    watch = activeRewardInfo
    rendObj = ROBJ_IMAGE
    image = simpleHorGrad
    flipX = true
    color = 0xAA000000
    padding = hintPadding
    children = ctor(activeRewardInfo.get())
  }
}

return {
  activeRewardInfo
  activeRewardHint
}