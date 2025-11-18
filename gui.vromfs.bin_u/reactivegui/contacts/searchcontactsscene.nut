from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { searchContactsResult, isSearchInProgress, searchContacts, searchedNick, clearSearchData
} = require("%rGui/contacts/contactsState.nut")
let { floatingTextInput, floatingTextInputHeight } = require("%rGui/components/textInput.nut")
let { spinner, spinnerOpacityAnim } = require("%rGui/components/spinner.nut")
let { closeWndBtn } = require("%rGui/components/closeWndBtn.nut")
let mkContactRow = require("%rGui/contacts/mkContactRow.nut")
let { mkContactActionBtnPrimary, mkContactActionBtn } = require("%rGui/contacts/mkContactActionBtn.nut")
let { INVITE_TO_FRIENDS, CANCEL_INVITE, ADD_TO_BLACKLIST, REMOVE_FROM_BLACKLIST,
  INVITE_TO_SQUAD, REVOKE_INVITE, PROFILE_VIEW
} = require("%rGui/contacts/contactActions.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { topAreaSize, gradientHeightBottom } = require("%rGui/options/mkOptionsScene.nut")

let searchIconSize = hdpxi(60)
let gap = hdpx(24)

let onChangeDelay = 0.8 
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
  size = [searchIconSize, searchIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#btn_search.svg:{searchIconSize}:{searchIconSize}:P")
  color = 0xFFFFFFFF
}

let nameInput = floatingTextInput(searchName, {
  ovr = { size = [flex(), floatingTextInputHeight] }
  onReturn = startSearch
  mkEditContent = @(_, inputComp) {
    size = flex()
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
  size = [floatingTextInputHeight, floatingTextInputHeight]
  rendObj = ROBJ_SOLID
  color = 0x990C1113
  children = closeWndBtn(
    function() {
      clearSearchData()
      searchName.set(searchedNick.get() ?? "")
    },
    { vplace = ALIGN_CENTER, hplace = ALIGN_CENTER })
}

let searchBlock = {
  size = [flex(), floatingTextInputHeight]
  flow = FLOW_HORIZONTAL
  gap
  children = [
    nameInput
    resetBtn
  ]
}

let pannableTopOffset = gap
let mkVerticalPannableArea = verticalPannableAreaCtor(sh(100) - topAreaSize - floatingTextInputHeight - defButtonHeight - gap * 2,
  [pannableTopOffset, gradientHeightBottom])
let scrollHandler = ScrollHandler()

let contactsList = {
  size = flex()
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
  size = flex()
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
  size = flex()
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
        mkContactActionBtn(REVOKE_INVITE, selectedUserId.get(), { hotkeys = ["^J:LB"] })
        mkContactActionBtnPrimary(INVITE_TO_SQUAD, selectedUserId.get(), { hotkeys = ["^J:Y"] })
        mkContactActionBtn(CANCEL_INVITE, selectedUserId.get(), { hotkeys = ["^J:RB"] })
        mkContactActionBtnPrimary(INVITE_TO_FRIENDS, selectedUserId.get(), { hotkeys = ["^J:X | Enter"] })
      ]
}

return {
  key = {}
  size = flex()
  onAttach = @() searchName.set(searchedNick.get() ?? "")
  flow = FLOW_VERTICAL
  gap
  children = [
    searchBlock
    contactsBlock
    buttons
  ]
}