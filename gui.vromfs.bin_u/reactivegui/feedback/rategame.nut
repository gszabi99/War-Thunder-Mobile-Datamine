from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { SHOULD_USE_REVIEW_CUE, needRateGame, onRateGameOpen } = require("%rGui/feedback/rateGameState.nut")
let openReviewCueWnd = require("%rGui/feedback/reviewCueWnd.nut")
let openFeedbackWnd = require("%rGui/feedback/feedbackWnd.nut")

local onCloseCb = null

function tryShowRateGame() {
  if (!needRateGame.value)
    return

  onRateGameOpen()

  if (SHOULD_USE_REVIEW_CUE)
    openReviewCueWnd(onCloseCb)
  else
    openFeedbackWnd() // TODO: This wnd is deprecated, need to remove it from scripts.
}

let requestShowRateGame = function(cb = null) {
  onCloseCb = cb
  resetTimeout(0.1, tryShowRateGame)
}

return {
  requestShowRateGame
}
