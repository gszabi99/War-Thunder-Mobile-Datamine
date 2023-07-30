from "%globalsDarg/darg_library.nut" import *
let { screenlog } = require("dagor.debug")
let { tostring_r } = require("%sqstd/string.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let { set_purch_player_type, check_new_offer, debug_offer_generation_stats, shift_all_offers_time,
  generate_fixed_type_offer
} = require("%appGlobals/pServer/pServerApi.nut")
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { addModalWindow, removeModalWindow } = require("%rGui/components/modalWindows.nut")
let { closeButton } = require("%rGui/components/debugWnd.nut")
let { textButtonFaded } = require("%rGui/components/textButton.nut")
let { openMsgBox, msgBoxText } = require("%rGui/components/msgBox.nut")
let { btnBEscUp } = require("%rGui/controlsMenu/gpActBtn.nut")


let wndWidth = sh(130)
let gap = hdpx(10)

let wndUid = "debugOffersWnd"
let close = @() removeModalWindow(wndUid)
let slogRes = @(res) screenlog(res?.error == null ? "SUCCESS!" : "ERROR")
let function closeOnSuccess(res) {
  slogRes(res)
  if (res?.error == null)
    close()
}

let mkBtn = @(label, func) textButtonFaded(label, func, { ovr = { size = [flex(), hdpx(100)] } })
let infoTextOvr = { halign = ALIGN_LEFT, preformatted = FMT_KEEP_SPACES | FMT_NO_WRAP }.__update(fontTiny)

let commandsList = [
  { label = "gen_next_day_offer",
    func = @() shift_all_offers_time(86400, @(_) check_new_offer(curCampaign.value, closeOnSuccess))
  }
  { label = "debug_offer_generation_stats",
    func = @() debug_offer_generation_stats(curCampaign.value,
      function(res) {
        let data = clone res
        if ("isCustom" in data)
          delete data.isCustom
        openMsgBox({ text = msgBoxText(tostring_r(res), infoTextOvr) })
      })
  }
]

foreach (ot in ["start", "gold", "collection", "sidegrade", "upgrade"]) {
  let offerType = ot
  commandsList.append({
    label = $"generate {offerType}",
    func = @() generate_fixed_type_offer(curCampaign.value, offerType, closeOnSuccess)
  })
}

let pPlayerTypes = {
  newbie = ""
  standard = "standard"
  whale = "whale"
}
pPlayerTypes.each(@(pType, id) commandsList.append({
  label = $"set purch type {id}",
  func = @() set_purch_player_type(pType, slogRes)
}))

let function mkCommandsList() {
  let list = commandsList.map(@(c) mkBtn(c.label, c.func))
  let rows = arrayByRows(list, 2)
  if (rows.top().len() < 2)
    rows.top().resize(2, { size = flex() })

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    padding = gap
    gap
    children = rows.map(@(children) {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap
      children
    })
  }
}

return @() addModalWindow({
  key = wndUid
  size = flex()
  stopHotkeys = true
  hotkeys = [[btnBEscUp, { action = close, description = loc("Cancel") }]]
  children = {
    size = [wndWidth + 2 * gap, sh(90)]
    stopMouse = true
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = Color(30, 30, 30, 240)
    flow = FLOW_VERTICAL
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_TOP
        padding = gap
        children = [
          {
            rendObj = ROBJ_TEXT
            text = "Debug offers"
          }.__update(fontSmall)
          { size = flex() }
          closeButton(close)
        ]
      }
      mkCommandsList()
    ]
  }
})
