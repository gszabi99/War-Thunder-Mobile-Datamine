from "%globalsDarg/darg_library.nut" import *
let communityOptions = require("options/communityOptions.nut")
let accountPage = require("accountPage.nut")
let statisticsPage = require("statisticsPage.nut")
let { mkOptionsScene } = require("mkOptionsScene.nut")
let { hasUnseenDecorators } = require("%rGui/decorators/decoratorState.nut")
let { UNSEEN_HIGH, SEEN } = require("%rGui/unseenPriority.nut")

let tabs = [
  {
    id = "account"
    locId = "options/account"
    image = "ui/gameuiskin#menu_account.svg"
    content = accountPage
    unseen = Computed(@() hasUnseenDecorators.value ? UNSEEN_HIGH : SEEN)
  }
  {
    locId = "options/community"
    image = "ui/gameuiskin#lobby_social_icon.svg"
    content = communityOptions
  }
  {
    locId = "flightmenu/btnStats"
    image = "ui/gameuiskin#menu_stats.svg"
    content = statisticsPage
  }
]

return mkOptionsScene("accountOptionsScene", tabs)