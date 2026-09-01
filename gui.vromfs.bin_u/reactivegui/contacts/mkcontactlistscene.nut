from "%globalsDarg/darg_library.nut" import *
from "%rGui/components/buttonStyles.nut" import defButtonHeight
from "%rGui/components/pannableArea.nut" import verticalPannableAreaCtor
from "%rGui/components/scrollArrows.nut" import mkScrollArrow
import "%rGui/contacts/mkContactRow.nut" as mkContactRow
import "%rGui/contacts/mkContactsOrder.nut" as mkContactsOrder
from "%rGui/options/mkOptionsScene.nut" import topAreaSize, gradientHeightBottom


const gap = hdpx(24)

let mkVerticalPannableArea = verticalPannableAreaCtor(sh(100) - topAreaSize - defButtonHeight - gap * 2,
  [gap, gradientHeightBottom])

function contactsList(uidsList, playerSelectedUserId, responseAction, leftContent = null) {
  let ordered = mkContactsOrder(uidsList)
  let scrollHandler = ScrollHandler()
  return {
    size = FLEX
    children = [
      mkVerticalPannableArea(
        @() {
          watch = ordered
          size = FLEX_H
          flow = FLOW_VERTICAL
          children = ordered.get()
            .map(@(uid, idx) mkContactRow(uid, idx,
              Computed(@() playerSelectedUserId.get() == uid),
              @() playerSelectedUserId.set(uid),
              responseAction?(uid),
              leftContent?(uid)))
        }, {}, { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
      mkScrollArrow(scrollHandler, MR_B)
    ]
  }
}

let mkNoContactsMsg = @(text) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  text
}.__update(fontSmall)

function contactsBlock(uidsList, playerSelectedUserId, responseAction, emptyText = null, leftContent = null) {
  let hasContacts = Computed(@() uidsList.get().len() != 0)
  let emptyMsg = emptyText == null
    ? mkNoContactsMsg(loc("contacts/list_empty"))
    : mkNoContactsMsg(emptyText)
  return @() {
    watch = hasContacts
    size = FLEX
    children = !hasContacts.get()
      ? emptyMsg
      : contactsList(uidsList, playerSelectedUserId, responseAction, leftContent)
  }
}

let buttons = @(selectedUserId, mkContactActions) @() {
  watch = selectedUserId
  size = [saSize[0], SIZE_TO_CONTENT]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap
  children = selectedUserId.get() == null ? null
    : mkContactActions(selectedUserId.get())
}

let playerSelectedUserId = mkWatched(persist, "selectedUserId")


function mkContactListScene(uidsList, mkContactActions, responseAction = null, emptyText = null, leftContent = null) {
  let selectedUserId = Computed(@() playerSelectedUserId.get() in uidsList.get()
    ? playerSelectedUserId.get()
    : null)
  return {
    key = uidsList
    size = FLEX
    flow = FLOW_VERTICAL
    gap
    children = [
      contactsBlock(uidsList, playerSelectedUserId, responseAction, emptyText, leftContent)
      buttons(selectedUserId, mkContactActions)
    ]
  }
}

return {
  mkContactListScene
  contactsBlock
  mkNoContactsMsg
}
