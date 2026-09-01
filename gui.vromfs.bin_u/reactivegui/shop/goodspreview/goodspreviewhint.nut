from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/config/skinPresentation.nut" import getSkinPresentation
import "%appGlobals/decorators/avatars.nut" as getAvatarImage
from "%appGlobals/decorators/nickFrames.nut" import frameNick
from "%appGlobals/rewardType.nut" import G_CURRENCY, G_ITEM, G_DECAL, G_SKIN, G_DECORATOR
from "%appGlobals/unitPresentation.nut" import getUnitName
from "%rGui/decorators/decoratorState.nut" import allDecorators
from "%rGui/event/eventLocName.nut" import getMainEventLoc
from "%rGui/event/eventState.nut" import eventSeason
from "%rGui/style/gradients.nut" import simpleHorGrad
from "%rGui/unitCustom/unitDecals/unitDecalsComps.nut" import mkDecalIcon


const hintPadding = hdpx(10)
let decalIconSize = [hdpxi(600), hdpxi(300)]
const avatarSize = hdpxi(250)
const skinIconSize = hdpxi(100)
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
  watch = eventSeason
  size = const [hdpx(500), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = "\n".concat(
    colorize(0xFFFFFFFF, loc($"item/{r.id}", { name = getMainEventLoc(eventSeason.get()) })),
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