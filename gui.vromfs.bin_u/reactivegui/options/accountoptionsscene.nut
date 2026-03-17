from "%globalsDarg/darg_library.nut" import *
let { is_ios, is_pc } = require("%sqstd/platform.nut")
let { has_game_center, can_view_replays } = require("%appGlobals/permissions.nut")
let communityOptions = require("%rGui/options/options/communityOptions.nut")
let accountPage = require("%rGui/options/accountPage.nut")
let statisticsPage = require("%rGui/options/statisticsPage.nut")
let privacyPage = require("%rGui/options/privacyPage.nut")
let gameCenterPage = require("%rGui/options/gameCenterPage.nut")
let replaysPage = require("%rGui/options/replaysPage.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { hasUnseenDecorators } = require("%rGui/decorators/decoratorState.nut")
let { UNSEEN_HIGH, SEEN } = require("%rGui/unseenPriority.nut")


let SCENE_ID = "accountOptionsScene"
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
    image = "ui/gameuiskin#watch_ads.svg"
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
