from "%globalsDarg/darg_library.nut" import *
from "%sqstd/platform.nut" import is_ios, is_pc
from "%appGlobals/permissions.nut" import has_game_center, can_view_replays
from "%rGui/decorators/decoratorState.nut" import hasUnseenDecorators
import "%rGui/options/accountPage.nut" as accountPage
import "%rGui/options/gameCenterPage.nut" as gameCenterPage
from "%rGui/options/mkOptionsScene.nut" import mkOptionsScene
import "%rGui/options/options/communityOptions.nut" as communityOptions
import "%rGui/options/privacyPage.nut" as privacyPage
import "%rGui/options/replaysPage.nut" as replaysPage
import "%rGui/options/statisticsPage.nut" as statisticsPage
from "%rGui/unseenPriority.nut" import UNSEEN_HIGH, SEEN


const SCENE_ID = "accountOptionsScene"
let isOpened = mkWatched(persist, $"{SCENE_ID}_isOpened", false)
let curTabId = Watched(null)

let tabs = [
  {
    id = "account"
    locId = "options/account"
    image = "ui/gameuiskin#menu_account.svg"
    content = accountPage
    unseen = Computed(@() hasUnseenDecorators.get() ? UNSEEN_HIGH : SEEN)
  }
  {
    locId = "options/community"
    image = "ui/gameuiskin#lobby_social_icon.svg"
    content = communityOptions
  }
  {
    locId = "flightmenu/btnStats"
    image = "ui/gameuiskin#menu_stats.svg"
    isFullWidth = true
    content = statisticsPage
  }
  {
    locId = "mainmenu/tabPrivacy"
    image = "ui/gameuiskin#icon_privacy.svg"
    content = privacyPage
  }
  {
    id = "replays"
    locId = "mainmenu/btnReplays"
    image = "ui/gameuiskin#icon_menu_replay.svg"
    isFullWidth = true
    isVisible = can_view_replays
    content = replaysPage
  }
]

if (is_ios || is_pc)
  tabs.append({
    locId = "options/gameCenter"
    image = "ui/gameuiskin#icon_gamecenter.svg"
    content = gameCenterPage
    isVisible = has_game_center
  })

return {
  accountOptionsScene = mkOptionsScene("accountOptionsScene", tabs, isOpened, curTabId)
  setCurTabId = @(id) curTabId.set(id)
}
