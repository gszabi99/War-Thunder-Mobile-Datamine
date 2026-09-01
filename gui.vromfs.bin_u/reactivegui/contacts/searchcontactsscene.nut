from "%globalsDarg/darg_library.nut" import *
from "dagor.workcycle" import resetTimeout
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/closeWndBtn.nut" import closeWndBtn
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow
from "%rGui/components/spinner.nut" import spinner, spinnerOpacityAnim
from "%rGui/components/textInput.nut" import floatingTextInput
from "%rGui/contacts/contactActions.nut" import INVITE_TO_FRIENDS, CANCEL_INVITE, ADD_TO_BLACKLIST,
  REMOVE_FROM_BLACKLIST, INVITE_TO_SQUAD, PROFILE_VIEW
from "%rGui/contacts/contactsState.nut" import searchContactsResult, isSearchInProgress, searchContacts, searchedNick,
  clearSearchData
from "%rGui/contacts/mkContactActionBtn.nut" import mkContactActionBtnPrimary, mkContactActionBtn
import "%rGui/contacts/mkContactRow.nut" as mkContactRow
from "%rGui/options/mkOptionsScene.nut" import topAreaSize, gradientHeightBottom
from "%rGui/style/stdColors.nut" import tabBgColor


const searchIconSize = hdpxi(40)
const gap = hdpx(24)
const textInputHeight = hdpx(60)

const onChangeDelay = 0.8 
let searchName = Watched("")
let playerSelectedUserId = mkWatched(persist, "playerSelectedUserId", null)
let selectedUserId = Computed(@() playerSelectedUserId.get() in searchContactsResult.get()
  ? playerSelectedUserId.get()
  : null)
let hasResult = Computed(@() searchContactsResult.get().len() > 0)
let isNotFound = Computed(@() !hasResult.get() && searchedNick.get() != null)

function startSearch() {
  if (searchName.get() != "" && searchName.get() != searchedNick.get())
    searchContacts(searchName.get())
}

searchName.subscribe(@(_) resetTimeout(onChangeDelay, startSearch))

let searchIcon = {
  size = const [searchIconSize, searchIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#btn_search.svg:{searchIconSize}:{searchIconSize}:P")
  color = 0xFFFFFFFF
}

let nameInput = floatingTextInput(searchName, {
  ovr = { size = const [FLEX, textInputHeight] }
  onReturn = startSearch
  mkEditContent = @(_, inputComp) {
    size = FLEX
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(35)
    children = [
      searchIcon
      inputComp
    ]
  }
})

let resetBtn = {
  size = const [textInputHeight, textInputHeight]
  rendObj = ROBJ_SOLID
  color = tabBgColor
  children = closeWndBtn(
    function() {
      clearSearchData()
      searchName.set(searchedNick.get() ?? "")
    },
    { size = evenPx(30), vplace = ALIGN_CENTER, hplace = ALIGN_CENTER })
}

let searchBlock = {
  size = const [FLEX, textInputHeight]
  flow = FLOW_HORIZONTAL
  gap
  children = [
    nameInput
    resetBtn
  ]
}

const pannableTopOffset = gap
let mkVerticalPannableArea = verticalPannableAreaCtor(sh(100) - topAreaSize - textInputHeight - defButtonHeight - gap * 2,
  [pannableTopOffset, gradientHeightBottom])
let scrollHandler = ScrollHandler()

let contactsList = {
  size = FLEX
  children = [
    mkVerticalPannableArea(
      @() {
        watch = searchContactsResult
        size = FLEX_H
        flow = FLOW_VERTICAL
        children = searchContactsResult.get()
          .map(@(name, uid) { uid, name })
          .values()
          .sort(@(a, b) a.name <=> b.name)
          .map(@(c, idx) mkContactRow(c.uid, idx,
            Computed(@() selectedUserId.get() == c.uid),
            @() playerSelectedUserId.set(c.uid)))
      }, {}, { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
    mkScrollArrow(scrollHandler, MR_B)
  ]
}

let inProgressInfo = {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow  = FLOW_VERTICAL
  gap
  children = [
    {
      rendObj = ROBJ_TEXT,
      text = loc("contacts/search_placeholder")
      animations = [spinnerOpacityAnim]
    }.__update(fontSmall)
    spinner
  ]
}

let notFoundMsg = {
  rendObj = ROBJ_TEXT,
  text = loc("contacts/searchNotFound")
}.__update(fontSmall)

let contactsBlock = @() {
  watch = [isSearchInProgress, hasResult, isNotFound]
  size = FLEX
  children = isSearchInProgress.get() ? inProgressInfo
    : hasResult.get() ? contactsList
    : isNotFound.get() ? notFoundMsg
    : null
}

let buttons = @() {
  watch = selectedUserId
  size = [saSize[0], SIZE_TO_CONTENT]
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap
  children = selectedUserId.get() == null ? null
    : [
        mkContactActionBtn(PROFILE_VIEW, selectedUserId.get(), { hotkeys = ["^J:LT"] })
        mkContactActionBtn(REMOVE_FROM_BLACKLIST, selectedUserId.get(), { hotkeys = ["^J:RB"] })
        mkContactActionBtn(ADD_TO_BLACKLIST, selectedUserId.get(), { hotkeys = ["^J:RT"] })
        mkContactActionBtnPrimary(INVITE_TO_SQUAD, selectedUserId.get(), { hotkeys = ["^J:Y"] })
        mkContactActionBtn(CANCEL_INVITE, selectedUserId.get(), { hotkeys = ["^J:RB"] })
        mkContactActionBtnPrimary(INVITE_TO_FRIENDS, selectedUserId.get(), { hotkeys = ["^J:X | Enter"] })
      ]
}

return {
  key = {}
  size = FLEX
  onAttach = @() searchName.set(searchedNick.get() ?? "")
  flow = FLOW_VERTICAL
  gap
  children = [
    searchBlock
    contactsBlock
    buttons
  ]
}