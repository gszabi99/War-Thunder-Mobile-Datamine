from "%globalsDarg/darg_library.nut" import *
let avatarScene = require("avatarScene.nut")
let nickFramesScene  = require("nickFramesScene.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let titlesScene = require("titlesScene.nut")
let changeNameScene = require("changeNameScene.nut")
let { gamercardBalanceBtns } = require("%rGui/mainMenu/gamercard.nut")
let { isDecoratorsSceneOpened, unseenDecorators, availNickFrames, availAvatars,
availTitles } = require("decoratorState.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")

let tabs = [
  {
    locId = "decorator/avatar"
    image = "ui/gameuiskin#profile_avatar_icon.svg"
    content = avatarScene
    isFullWidth = true
    unseen = Computed(@() availAvatars.get().findindex(@(_, id) id in unseenDecorators.get()) != null
      ? UNSEEN_HIGH : SEEN)
  }
  {
    locId = "decorator/nickFrame"
    image = "ui/gameuiskin#profile_decor_icon.svg"
    content = nickFramesScene
    isFullWidth = true
    unseen = Computed(@() availNickFrames.get().findindex(@(_, id) id in unseenDecorators.get()) != null
      ? UNSEEN_HIGH : SEEN)
  }
  {
    locId = "decorator/title"
    image = "ui/gameuiskin#profile_tilte_icon.svg"
    content = titlesScene
    isFullWidth = true
    unseen = Computed(@() availTitles.get().findindex(@(_, id) id in unseenDecorators.get()) != null
      ? UNSEEN_HIGH : SEEN)
  }
  {
    locId = "changeName"
    image = "ui/gameuiskin#profile_name_icon.svg"
    content = changeNameScene
  }
]

mkOptionsScene("decoratorsScene", tabs, isDecoratorsSceneOpened, null, gamercardBalanceBtns)