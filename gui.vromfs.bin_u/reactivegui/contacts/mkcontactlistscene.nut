from "%globalsDarg/darg_library.nut" import *
let mkContactRow = require("mkContactRow.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { mkVerticalPannableArea } = require("%rGui/options/mkOptionsScene.nut")
let mkContactsOrder = require("mkContactsOrder.nut")

let gap = hdpx(24)

function contactsList(uidsList, playerSelectedUserId) {
  let ordered = mkContactsOrder(uidsList)
  return mkVerticalPannableArea(
    @() {
      watch = ordered
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = ordered.value
        .map(@(uid, idx) mkContactRow(uid, idx,
          Computed(@() playerSelectedUserId.value == uid),
          @() playerSelectedUserId(uid)))
    })
}

let noContactsMsg = {
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT,
  text = loc("contacts/list_empty")
}.__update(fontSmall)

function contactsBlock(uidsList, playerSelectedUserId) {
  let hasContacts = Computed(@() uidsList.value.len() != 0)
  return @() {
    watch = hasContacts
    size = flex()
    children = !hasContacts.value ? noContactsMsg
      : contactsList(uidsList, playerSelectedUserId)
  }
}

let buttons = @(selectedUserId, mkContactActions) @() {
  watch = selectedUserId
  size = [defButtonMinWidth, flex()]
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  gap
  children = selectedUserId.value == null ? null
    : mkContactActions(selectedUserId.value)
}

function mkContactListScene(uidsList, mkContactActions, selectedId = "selectedUserId") {
  let playerSelectedUserId = mkWatched(persist, selectedId, null)
  let selectedUserId = Computed(@() playerSelectedUserId.value in uidsList.value
    ? playerSelectedUserId.value
    : null)
  return {
    key = uidsList
    size = flex()
    flow = FLOW_HORIZONTAL
    gap
    children = [
      contactsBlock(uidsList, playerSelectedUserId)
      buttons(selectedUserId, mkContactActions)
    ]
  }
}

return mkContactListScene