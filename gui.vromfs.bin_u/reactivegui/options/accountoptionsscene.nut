let communityOptions = require("options/communityOptions.nut")
let accountPage = require("accountPage.nut")
let { mkOptionsScene } = require("mkOptionsScene.nut")

let tabs = [
  {
    id = "account"
    locId = "options/account"
    image = "ui/gameuiskin#menu_account.svg"
    content = accountPage
  }
  {
    locId = "options/community"
    image = "ui/gameuiskin#lobby_social_icon.svg"
    content = communityOptions
  }
]

return mkOptionsScene("accountOptionsScene", tabs)