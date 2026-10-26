from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/currencyStyles.nut" import CS_GAMERCARD
from "%rGui/components/unseenMark.nut" import priorityUnseenMark
from "%rGui/squad/squadChatState.nut" import hasSquadChatUnseen, isInSquadChat
import "%rGui/squad/squadChatWnd.nut" as squadChatWnd
from "%rGui/style/gradients.nut" import gradCircularSmallHorCorners, gradCircCornerOffset
from "%rGui/style/stdColors.nut" import hoverColor
from "%rGui/style/stdAnimations.nut" import mkPressTransitionScale


let iconSize = [CS_GAMERCARD.iconSize * 5 / 4, CS_GAMERCARD.iconSize]

let hoverBg = {
  size = const [pw(150), FLEX]
  hplace = ALIGN_CENTER
  color = hoverColor
  opacity = 1
  rendObj = ROBJ_9RECT
  image = gradCircularSmallHorCorners
  screenOffs = hdpx(100)
  texOffs = gradCircCornerOffset
}

let scbStateFlags = Watched(0)
function squadChatBtn() {
  let sf = scbStateFlags.get()
  return !isInSquadChat.get() ? { watch = isInSquadChat }
    : {
        watch = [isInSquadChat, scbStateFlags]
        key = scbStateFlags
        behavior = Behaviors.Button
        onClick = @(evt) squadChatWnd(evt.targetRect)
        onElemState = @(s) scbStateFlags.set(s)
        sound = const { click = "click" }

        children = [
          {
            size = FLEX
            children = sf & S_HOVER ? hoverBg : null
          }
          {
            size = iconSize
            rendObj = ROBJ_IMAGE
            image = Picture($"ui/gameuiskin#chat.svg:{iconSize[0]}:{iconSize[1]}")
            keepAspect = true
            ...mkPressTransitionScale(sf)
          }
          @() {
            watch = hasSquadChatUnseen
            pos = const [pw(50), ph(-50)]
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            children = hasSquadChatUnseen.get() ? priorityUnseenMark : null
          }
        ]
      }
}

return {
  squadChatBtn
}