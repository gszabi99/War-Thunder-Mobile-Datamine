from "%globalsDarg/darg_library.nut" import *
from "%appGlobals/pServer/campaign.nut" import curCampaign
from "%rGui/event/eventLootboxes.nut" import eventLootboxesRaw
from "%rGui/event/eventState.nut" import MAIN_EVENT_ID
from "%rGui/event/gmEventState.nut" import gmEventsList
import "%rGui/event/shouldShowEventMechanics.nut" as shouldShowEventMechanics
from "%rGui/seasonScene/seasonSceneState.nut" import openSeasonScene, LOOTBOX_TAB, openGmEventWnd
from "%rGui/shop/lootboxPreviewState.nut" import openEventWndLootbox


let actions = {
  open_event_lootbox = { 
    mkHasAction = @(p) Computed(@() shouldShowEventMechanics.get()
      && p?[curCampaign.get()] in eventLootboxesRaw.get())
    function exec(p) {
      let lootbox = eventLootboxesRaw.get()?[p?[curCampaign.get()]]
      if (lootbox == null)
        return
      openSeasonScene(lootbox?.meta.event_id ?? MAIN_EVENT_ID, LOOTBOX_TAB)
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