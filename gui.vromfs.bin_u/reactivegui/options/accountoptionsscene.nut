from "%globalsDarg/darg_library.nut" import *
let { is_ios, is_pc } = require("%sqstd/platform.nut")
let { has_game_center } = require("%appGlobals/permissions.nut")
let communityOptions = require("%rGui/options/options/communityOptions.nut")
let accountPage = require("%rGui/options/accountPage.nut")
let statisticsPage = require("%rGui/options/statisticsPage.nut")
let privacyPage = require("%rGui/options/privacyPage.nut")
let gameCenterPage = require("%rGui/options/gameCenterPage.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let { hasUnseenDecorators } = require("%rGui/decorators/decoratorState.nut")
let { UNSEEN_HIGH, SEEN } = require("%rGui/unseenPriority.nut")

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
]

if (is_ios || is_pc)
  tabs.append({
    locId = "options/gameCenter"
    image = "ui/gameuiskin#icon_gamecenter.svg"
    content = gameCenterPage
    isVisible = has_game_center
  })

return mkOptionsScene("accountOptionsScene", tabs)