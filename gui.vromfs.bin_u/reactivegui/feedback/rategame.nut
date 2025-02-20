from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { needRateGame } = require("%rGui/feedback/rateGameState.nut")
let openReviewCueWnd = require("%rGui/feedback/reviewCueWnd.nut")

local onCloseCb = null

function tryShowRateGame() {
  if (!needRateGame.value)
    return

  openReviewCueWnd(onCloseCb)
}

let requestShowRateGame = function(cb = null) {
  onCloseCb = cb
  resetTimeout(0.1, tryShowRateGame)
}

return {
  requestShowRateGame
}
