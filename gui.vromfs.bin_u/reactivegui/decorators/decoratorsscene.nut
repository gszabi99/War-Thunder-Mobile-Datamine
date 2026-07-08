from "%globalsDarg/darg_library.nut" import *
let avatarScene = require("%rGui/decorators/avatarScene.nut")
let nickFramesScene  = require("%rGui/decorators/nickFramesScene.nut")
let { mkOptionsScene } = require("%rGui/options/mkOptionsScene.nut")
let titlesScene = require("%rGui/decorators/titlesScene.nut")
let changeNameScene = require("%rGui/decorators/changeNameScene.nut")
let { gamercardBalanceBtns } = require("%rGui/mainMenu/gamercard.nut")
let { isDecoratorsSceneOpened, unseenDecorators, availNickFrames, availAvatars,
availTitles } = require("%rGui/decorators/decoratorState.nut")
let { SEEN, UNSEEN_HIGH } = require("%rGui/unseenPriority.nut")
let { backButton } = require("%rGui/components/backButton.nut")
let { headerGradientBg } = require("%rGui/components/gradientDefComps.nut")


let curTabId = Watched(null)

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

let backBtn = backButton(function() {
  curTabId.set(null)
  isDecoratorsSceneOpened.set(false)
})

let header = {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    headerGradientBg([
      backBtn
      {
        rendObj = ROBJ_TEXT
        text = loc("mainmenu/decorators")
      }.__update(fontBigShaded)
    ])
    {
      size = FLEX_H
      halign = ALIGN_RIGHT
      children = gamercardBalanceBtns
    }
  ]
}

mkOptionsScene("decoratorsScene", tabs, isDecoratorsSceneOpened, curTabId, header)
