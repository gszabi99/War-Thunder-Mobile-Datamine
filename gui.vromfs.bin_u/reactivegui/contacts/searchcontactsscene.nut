from "%globalsDarg/darg_library.nut" import *
let { resetTimeout } = require("dagor.workcycle")
let { searchContactsResult, isSearchInProgress, searchContacts, searchedNick, clearSearchData
} = require("contactsState.nut")
let { floatingTextInput, floatingTextInputHeight } = require("%rGui/components/textInput.nut")
let { spinner, spinnerOpacityAnim } = require("%rGui/components/spinner.nut")
let { closeWndBtn } = require("%rGui/components/closeWndBtn.nut")
let mkContactRow = require("mkContactRow.nut")
let { mkContactActionBtnPrimary, mkContactActionBtn } = require("mkContactActionBtn.nut")
let { INVITE_TO_FRIENDS, CANCEL_INVITE, ADD_TO_BLACKLIST, REMOVE_FROM_BLACKLIST,
  INVITE_TO_SQUAD, REVOKE_INVITE, PROFILE_VIEW
} = require("contactActions.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let { topAreaSize, gradientHeightBottom } = require("%rGui/options/mkOptionsScene.nut")

let searchIconSize = hdpxi(60)
let gap = hdpx(24)

let onChangeDelay = 0.8 
let searchName = Watched("")
let playerSelectedUserId = mkWatched(persist, "playerSelectedUserId", null)
let selectedUserId = Computed(@() playerSelectedUserId.value in searchContactsResult.value
  ? playerSelectedUserId.value
  : null)
let hasResult = Computed(@() searchContactsResult.value.len() > 0)
let isNotFound = Computed(@() !hasResult.value && searchedNick.value != null)

function startSearch() {
  if (searchName.value != "" && searchName.value != searchedNick.value)
    searchContacts(searchName.value)
}

searchName.subscribe(@(_) resetTimeout(onChangeDelay, startSearch))

let searchIcon = {
  size = [searchIconSize, searchIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/gameuiskin#btn_search.svg:{searchIconSize}:{searchIconSize}:P")
  color = 0xFFFFFFFF
}

let nameInput = floatingTextInput(searchName, {
  ovr = { size = [hdpx(750), floatingTextInputHeight] }
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
      searchName(searchedNick.value ?? "")
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
let mkVerticalPannableArea = verticalPannableAreaCtor(sh(100) - topAreaSize - floatingTextInputHeight,
  [pannableTopOffset, gradientHeightBottom])
let scrollHandler = ScrollHandler()

let contactsList = {
  size = flex()
  children = [
    mkVerticalPannableArea(
      @() {
        watch = searchContactsResult
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = searchContactsResult.value
          .map(@(name, uid) { uid, name })
          .values()
          .sort(@(a, b) a.name <=> b.name)
          .map(@(c, idx) mkContactRow(c.uid, idx,
            Computed(@() selectedUserId.value == c.uid),
            @() playerSelectedUserId(c.uid)))
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
  children = isSearchInProgress.value ? inProgressInfo
    : hasResult.value ? contactsList
    : isNotFound.value ? notFoundMsg
    : null
}

let buttons = @() {
  watch = selectedUserId
  size = [defButtonMinWidth, flex()]
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  gap
  children = selectedUserId.value == null ? null
    : [
        mkContactActionBtn(PROFILE_VIEW, selectedUserId.value, { hotkeys = ["^J:LT"] })
        mkContactActionBtn(REMOVE_FROM_BLACKLIST, selectedUserId.value, { hotkeys = ["^J:RB"] })
        mkContactActionBtn(ADD_TO_BLACKLIST, selectedUserId.value, { hotkeys = ["^J:RT"] })
        mkContactActionBtn(REVOKE_INVITE, selectedUserId.value, { hotkeys = ["^J:LB"] })
        mkContactActionBtnPrimary(INVITE_TO_SQUAD, selectedUserId.value, { hotkeys = ["^J:Y"] })
        mkContactActionBtn(CANCEL_INVITE, selectedUserId.value, { hotkeys = ["^J:RB"] })
        mkContactActionBtnPrimary(INVITE_TO_FRIENDS, selectedUserId.value, { hotkeys = ["^J:X | Enter"] })
      ]
}

return {
  key = {}
  size = flex()
  onAttach = @() searchName(searchedNick.value ?? "")
  flow = FLOW_VERTICAL
  gap
  children = [
    searchBlock
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap
      children = [
        contactsBlock
        buttons
      ]
    }
  ]
}