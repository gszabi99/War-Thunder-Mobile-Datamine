from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/backButton.nut" import backButton
from "%rGui/components/gradientDefComps.nut" import headerGradientWithRightBlock
import "%rGui/decorators/avatarScene.nut" as avatarScene
import "%rGui/decorators/changeNameScene.nut" as changeNameScene
from "%rGui/decorators/decoratorState.nut" import isDecoratorsSceneOpened, unseenDecorators, availNickFrames,
  availAvatars, availTitles
import "%rGui/decorators/nickFramesScene.nut" as nickFramesScene
import "%rGui/decorators/titlesScene.nut" as titlesScene
from "%rGui/mainMenu/gamercard.nut" import gamercardBalanceBtns
from "%rGui/options/mkOptionsScene.nut" import mkOptionsScene
from "%rGui/unseenPriority.nut" import SEEN, UNSEEN_HIGH


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

let header = headerGradientWithRightBlock(
  [
    backBtn
    {
      rendObj = ROBJ_TEXT
      text = loc("mainmenu/decorators")
    }.__update(fontBigShaded)
  ],
  gamercardBalanceBtns)

mkOptionsScene("decoratorsScene", tabs, isDecoratorsSceneOpened, curTabId, header)
