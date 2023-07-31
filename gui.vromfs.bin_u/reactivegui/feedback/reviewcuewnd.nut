from "%globalsDarg/darg_library.nut" import *
let { register_command } = require("console")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { registerScene } = require("%rGui/navState.nut")
let { wndSwitchAnim } = require("%rGui/style/stdAnimations.nut")
let { bgShaded } = require("%rGui/style/backgrounds.nut")
let { gradTranspDoubleSideX, gradDoubleTexOffset } = require("%rGui/style/gradients.nut")
let { textButtonBattle, textButtonPrimary, textButtonCommon } = require("%rGui/components/textButton.nut")
let { textInput } = require("%rGui/components/textInput.nut")
let { isRateGameSeen, sendGameRating, platformAppReview } = require("%rGui/feedback/rateGameState.nut")

const RATE_STARS_TOTAL = 5

let contentW = hdpx(1064)
let contentH = hdpx(660)
let wndLineW = contentW * 0.8
let starIconSize = hdpxi(80)
let starIconGap = hdpx(60)
let starIconSizeSmall = hdpxi(64)
let starIconGapSmall = hdpx(48)

let isOpened = mkWatched(persist, "isOpened", false)

let fieldRating = Watched(0)
let fieldComment = Watched("")
let hasSelectedRating = Computed(@() fieldRating.value > 0)
let hasAppliedRating = Watched(false)
let isRatedExcellent = Computed(@() hasAppliedRating.value && fieldRating.value == RATE_STARS_TOTAL)

let function close() {
  isOpened(false)
  isRateGameSeen(true)
}

let function resetForm() {
  fieldRating(0)
  fieldComment("")
  hasAppliedRating(false)
}
isOpened.subscribe(@(v) v ? resetForm() : null)

let function onBtnApply(isApply = true) {
  if (isApply) {
    if (!hasSelectedRating.value)
      return
    if (hasSelectedRating.value && !hasAppliedRating.value)
      return hasAppliedRating(true)
  }
  if (!isApply && !hasAppliedRating.value) // Close btn pressed
    return close()

  // It doesn't matter which btn pressed (Apply/Close), now sending the result.
  sendGameRating(fieldRating.value, fieldComment.value)
  platformAppReview(isRatedExcellent.value)
  close()
}

let btnClose = {
  size  = [hdpx(30), hdpx(30)]
  margin = [hdpx(35), hdpx(45)]
  hplace = ALIGN_RIGHT
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [
    [VECTOR_LINE, 0, 0, 100, 100],
    [VECTOR_LINE, 0, 100, 100, 0]
  ]
  color = 0xFFA0A0A0
  lineWidth = hdpx(6)
  behavior = Behaviors.Button
  onClick = @() onBtnApply(false)
}

let textarea = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = 0xFFFFFFFF
}.__update(fontSmall)

let mkTitle = @(text) textarea.__merge({
  pos = [0, hdpx(20)]
  text
}, fontMedium)

let function mkRateStarsRow(valueWatch, needInteractive, needBig) {
  let iconSize = needBig ? starIconSize : starIconSizeSmall
  let iconGap = needBig ? starIconGap : starIconGapSmall
  return {
    vplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = iconGap
    children = array(RATE_STARS_TOTAL).map(@(_, idx) function() {
      let rating = idx + 1
      let icon = rating <= valueWatch.value ? "rate_star_filled" : "rate_star_empty"
      let res = {
        watch = valueWatch
        rendObj = ROBJ_IMAGE
        size = [ iconSize, iconSize ]
        image = Picture($"ui/gameuiskin#{icon}.svg:{iconSize}:{iconSize}")
      }
      if (needInteractive)
        res.__update({
          behavior = Behaviors.Button
          onClick = @() valueWatch(rating)
        })
      return res
    })
  }
}

let mkBtnPlace = @(children) {
  vplace = ALIGN_BOTTOM
  pos = [0, -hdpx(80)]
  children
}

let pageRating = {
  size = flex()
  halign = ALIGN_CENTER
  children = [
    mkTitle(loc("rateGame/title"))
    textarea.__merge({
      vplace = ALIGN_CENTER
      pos = [0, -hdpx(150)]
      text = "\n".concat(loc("rateGame/did_you_like"), loc("rateGame/your_opinion"))
    })
    mkRateStarsRow(fieldRating, true, true)
    mkBtnPlace(@() {
      watch = hasSelectedRating
      children = hasSelectedRating.value
        ? textButtonBattle(utf8ToUpper(loc("msgbox/btn_rate")), onBtnApply)
        : textButtonCommon(utf8ToUpper(loc("msgbox/btn_rate")), onBtnApply)
    })
  ]
}

let pageThankYou = {
  size = flex()
  halign = ALIGN_CENTER
  children = [
    mkTitle(loc("rateGame/thanks_for_rating"))
    mkRateStarsRow(fieldRating, false, true)
    mkBtnPlace(textButtonPrimary(utf8ToUpper(loc("msgbox/btn_excellent")), onBtnApply))
  ]
}

let pageComment = {
  size = flex()
  halign = ALIGN_CENTER
  children = [
    mkTitle(loc("rateGame/thanks_for_rating"))
    mkRateStarsRow(fieldRating, false, false).__update({
      pos = [0, -hdpx(200)]
    })
    textarea.__merge({
      vplace = ALIGN_CENTER
      pos = [0, -hdpx(100)]
      text = loc("rateGame/what_did_not_like")
    })
    {
      size = [flex(), SIZE_TO_CONTENT]
      pos = [0, hdpx(300)]
      children = textInput(fieldComment, {
        placeholder = loc("feedback/editbox/placeholder")
        onChange = @(value) fieldComment(value)
      })
    }
    mkBtnPlace(textButtonPrimary(utf8ToUpper(loc("msgbox/btn_leave_feedback")), onBtnApply))
  ]
}

let doubleSideGradBase = {
  rendObj = ROBJ_9RECT
  image = gradTranspDoubleSideX
  texOffs = [0, gradDoubleTexOffset]
}
let doubleSideGradLine = doubleSideGradBase.__merge({
  size = [wndLineW, hdpx(8)]
  screenOffs = [0, 0.4 * wndLineW]
  color = 0xFF949494
})
let bgGradientComp = doubleSideGradBase.__merge({
  size = [contentW, contentH]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  color = 0xFF000000
  screenOffs = [0, 0.06 * contentW]
  children = [
    doubleSideGradLine
    doubleSideGradLine.__merge({ vplace = ALIGN_BOTTOM })
  ]
})

let imagesPreloadComp = {
  children = array(5).map(@(_, i) {
    size = [1, 1]
    rendObj = ROBJ_IMAGE
    image = Picture($"!ui/images/review_cue_{i + 1}.avif")
    opacity = 0.01
  })
}

let girlImage = @() {
  watch = [fieldRating, hasAppliedRating, isRatedExcellent]
  size = [hdpxi(644), hdpxi(914)]
  vplace = ALIGN_BOTTOM
  pos = [ sw(50) - (contentW / 2) - hdpxi(444), 0 ]
  rendObj = ROBJ_IMAGE
  image = !hasAppliedRating.value && fieldRating.value == 0 ? Picture($"!ui/images/review_cue_2.avif")
    : !hasAppliedRating.value && fieldRating.value < RATE_STARS_TOTAL ? Picture($"!ui/images/review_cue_4.avif")
    : !hasAppliedRating.value && fieldRating.value == RATE_STARS_TOTAL ? Picture($"!ui/images/review_cue_5.avif")
    : isRatedExcellent.value ? Picture($"!ui/images/review_cue_3.avif")
    : Picture($"!ui/images/review_cue_1.avif")
}

let reviewCueWnd = bgShaded.__merge({
  key = {}
  size = flex()
  children = [
    imagesPreloadComp
    bgGradientComp
    girlImage
    {
      size = [contentW, contentH]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = [
        @() {
          watch = [hasAppliedRating, isRatedExcellent]
          size = flex()
          margin = [0, hdpx(100)]
          halign = ALIGN_CENTER
          children = !hasAppliedRating.value ? pageRating
            : isRatedExcellent.value ? pageThankYou
            : pageComment
        }
        btnClose
      ]
    }
  ]
  animations = wndSwitchAnim
})

register_command(function() {
  isRateGameSeen(false)
  isOpened(!isOpened.value)
}, "ui.debug.review_cue.show")

registerScene("reviewCueWnd", reviewCueWnd, close, isOpened)

return @() isOpened(true)
