from "%globalsDarg/darg_library.nut" import *
let { txt, tagRedColor } = require("%rGui/shop/goodsView/sharedParts.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { gradTranspDoubleSideX } = require("%rGui/style/gradients.nut")
let { onSectionChange, curSectionId, hasUnseenQuestsBySection, sectionsCfg } = require("questsState.nut")
let { priorityUnseenMark } = require("%rGui/components/unseenMark.nut")
let { mkLockedIcon } = require("rewardsComps.nut")


let SECTION_OPACITY = 0.3
let bgGradColor = 0x990C1113
let gradColor = 0xFF52C4E4
let newMarkH = hdpxi(50)
let newMarkTexOffs = [0, newMarkH / 2, 0, newMarkH / 10]
let sectionBtnHeight = hdpx(70)
let sectionBtnMaxWidth = hdpx(400)
let lockedOpacity = 0.5
let sectionBtnGap = hdpx(10)

let newMark = {
  size  = [SIZE_TO_CONTENT, newMarkH]
  rendObj = ROBJ_9RECT
  image = Picture($"ui/gameuiskin#tag_popular.svg:{newMarkH}:{newMarkH}:P")
  keepAspect = KEEP_ASPECT_NONE
  screenOffs = newMarkTexOffs
  texOffs = newMarkTexOffs
  color = tagRedColor
  padding = [0, hdpx(30), 0, hdpx(20)]
  children = txt({
    text = utf8ToUpper(loc("shop/item/new"))
    vplace = ALIGN_CENTER
  })
}

let mkSectionBtn = @(id, width = sectionBtnMaxWidth, font = fontSmallShaded, isLocked = false) {
  size = [width, sectionBtnHeight]
  behavior = Behaviors.Button
  onClick = @() onSectionChange(id)
  children = [
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = bgGradColor
    }

    @() {
      watch = curSectionId
      size = flex()
      rendObj = ROBJ_IMAGE
      image = gradTranspDoubleSideX
      color = gradColor
      opacity = curSectionId.value == id ? 1 : 0
      transitions = [{ prop = AnimProp.opacity, duration = SECTION_OPACITY, easing = InOutQuad }]
    }

    {
      size = [width - sectionBtnGap, flex()]
      flow = FLOW_HORIZONTAL
      gap = sectionBtnGap
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        isLocked ? mkLockedIcon({ opacity = lockedOpacity }) : null
        @() {
          watch = sectionsCfg
          rendObj = ROBJ_TEXT
          opacity = isLocked ? lockedOpacity : 1.0
          text = sectionsCfg.value?[id].text
        }.__update(font)
      ]
    }

    @() {
      watch = [hasUnseenQuestsBySection, curSectionId]
      hplace = ALIGN_RIGHT
      margin = sectionBtnGap / 2
      children = hasUnseenQuestsBySection.value?[id] && id != curSectionId.value ? priorityUnseenMark : null
    }
  ]
}

let timeUntilTheEnd = @(time, ovr) {
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_TEXT
  text = "".concat(loc("quests/untilTheEnd"), " ", time)
}.__update(fontSmall, ovr)

let allQuestsCompleted = {
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  text = loc("quests/allCompleted")
}.__update(fontMedium)

return {
  newMark
  mkSectionBtn
  sectionBtnHeight
  sectionBtnMaxWidth
  sectionBtnGap
  timeUntilTheEnd
  allQuestsCompleted
}