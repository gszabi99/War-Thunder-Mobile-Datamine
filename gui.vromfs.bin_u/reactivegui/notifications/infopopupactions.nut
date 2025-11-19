from "%globalsDarg/darg_library.nut" import *
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { eventLootboxesRaw } = require("%rGui/event/eventLootboxes.nut")
let { openEventWnd, MAIN_EVENT_ID } = require("%rGui/event/eventState.nut")
let { openEventWndLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let { gmEventsList, openGmEventWnd } = require("%rGui/event/gmEventState.nut")

let actions = {
  open_event_lootbox = { 
    mkHasAction = @(p) Computed(@() p?[curCampaign.get()] in eventLootboxesRaw.get())
    function exec(p) {
      let lootbox = eventLootboxesRaw.get()?[p?[curCampaign.get()]]
      if (lootbox == null)
        return
      openEventWnd(lootbox?.meta.event_id ?? MAIN_EVENT_ID)
      openEventWndLootbox(lootbox.name)
    }
  },
  open_event_wnd = { 
    mkHasAction = @(p) Computed(@() p?.event_id in gmEventsList.get())
    exec = @(p) openGmEventWnd(p?.event_id)
  }
}

return {
  getPopupActionCfg = @(id) actions?[id]
}