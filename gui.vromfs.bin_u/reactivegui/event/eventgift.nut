from "%globalsDarg/darg_library.nut" import *
let { send } = require("eventbus")
let { eventSeason } = require("eventState.nut")
let { SEND_GIFT_URL } = require("%appGlobals/commonUrl.nut")
let { imageBtn } = require("%rGui/components/imageButton.nut")

return @() {
  watch = eventSeason
  hplace = ALIGN_RIGHT
  children = eventSeason.value == "season_3"
             ? imageBtn("ui/gameuiskin#icon_gift.avif",
                        @() send("openUrl", { baseUrl = SEND_GIFT_URL }),
                        { size = [hdpx(193), hdpx(190)] },
                        {
                          size = [flex(), SIZE_TO_CONTENT]
                          rendObj = ROBJ_TEXTAREA
                          behavior = Behaviors.TextArea
                          halign = ALIGN_CENTER
                          vplace = ALIGN_BOTTOM
                          text = loc("mainmenu/btnSendGift")
                        }.__update(fontSmall)
                       )
             : null
}