from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { SHOULD_USE_REVIEW_CUE, needRateGame, onRateGameOpen } = require("%rGui/feedback/rateGameState.nut")
let openReviewCueWnd = require("%rGui/feedback/reviewCueWnd.nut")
let openFeedbackWnd = require("%rGui/feedback/feedbackWnd.nut")

let function tryShowRateGame() {
  if (!needRateGame.value)
    return

  onRateGameOpen()

  if (SHOULD_USE_REVIEW_CUE)
    openReviewCueWnd()
  else
    openFeedbackWnd()
}

let requestShowRateGame = @() resetTimeout(0.1, tryShowRateGame)

return {
  requestShowRateGame
}
