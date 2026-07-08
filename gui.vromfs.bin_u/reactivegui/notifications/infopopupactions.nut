from "%globalsDarg/darg_library.nut" import *
let { curCampaign } = require("%appGlobals/pServer/campaign.nut")
let { eventLootboxesRaw } = require("%rGui/event/eventLootboxes.nut")
let { MAIN_EVENT_ID, shouldShowEventMechanics } = require("%rGui/event/eventState.nut")
let { openSeasonScene, LOOTBOX_TAB } = require("%rGui/seasonScene/seasonSceneState.nut")
let { openEventWndLootbox } = require("%rGui/shop/lootboxPreviewState.nut")
let { gmEventsList, openGmEventWnd } = require("%rGui/event/gmEventState.nut")

let actions = {
  open_event_lootbox = { 
    mkHasAction = @(p) Computed(@() shouldShowEventMechanics.get()
      && p?[curCampaign.get()] in eventLootboxesRaw.get())
    function exec(p) {
      let lootbox = eventLootboxesRaw.get()?[p?[curCampaign.get()]]
      if (lootbox == null)
        return
      openSeasonScene(LOOTBOX_TAB, null, lootbox?.meta.event_id ?? MAIN_EVENT_ID)
      openEventWndLootbox(lootbox.name)
    }
  },
  open_event_wnd = { 
    mkHasAction = @(p) Computed(@() shouldShowEventMechanics.get()
      && p?.event_id in gmEventsList.get())
    exec = @(p) openGmEventWnd(p?.event_id)
  }
}

return {
  getPopupActionCfg = @(id) actions?[id]
}