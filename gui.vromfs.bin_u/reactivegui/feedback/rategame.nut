from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "%rGui/feedback/rateGameState.nut" import needRateGame
import "%rGui/feedback/reviewCueWnd.nut" as openReviewCueWnd


local onCloseCb = null

function tryShowRateGame() {
  if (!needRateGame.get())
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
