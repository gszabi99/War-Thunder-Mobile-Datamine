from "%globalsDarg/darg_library.nut" import *
let nickFramesScene  = require("nickFramesScene.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let titlesScene = require("titlesScene.nut")
let changeNameScene = require("changeNameScene.nut")
let { gamercardBalanceBtns } = require("%rGui/mainMenu/gamercard.nut")
let { isDecoratorsSceneOpened, unseenDecorators, availNickFrames,
availTitles } = require("decoratorState.nut")
let { authTags } = require("%appGlobals/loginState.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")

let tabs = [
  {
    locId = "decorators/nickFrame"
    image = "ui/gameuiskin#profile_decor_icon.svg"
    content = nickFramesScene
    isFullWidth = true
    unseen = Computed(@() availNickFrames.value.findindex(@(_, id) id in unseenDecorators.value) != null
      ? UNSEEN_HIGH : SEEN)
  }
  {
    locId = "decorators/title"
    image = "ui/gameuiskin#profile_tilte_icon.svg"
    content = titlesScene
    isFullWidth = true
    unseen = Computed(@() availTitles.value.findindex(@(_, id) id in unseenDecorators.value) != null
      ? UNSEEN_HIGH : SEEN)
  }
  {
    locId = "changeName"
    image = "ui/gameuiskin#profile_name_icon.svg"
    content = changeNameScene
    isVisible = Computed(@() !authTags.value.contains("gplogin"))
  }
]

mkOptionsScene("decoratorsScene", tabs, isDecoratorsSceneOpened, null, gamercardBalanceBtns)