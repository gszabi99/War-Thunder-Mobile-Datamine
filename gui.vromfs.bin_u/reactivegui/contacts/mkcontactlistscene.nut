from "%globalsDarg/darg_library.nut" import *
let mkContactRow = require("mkContactRow.nut")
let { defButtonMinWidth } = require("%rGui/components/buttonStyles.nut")
let { mkVerticalPannableArea } = require("%rGui/options/mkOptionsScene.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let mkContactsOrder = require("mkContactsOrder.nut")

let gap = hdpx(24)

function contactsList(uidsList, playerSelectedUserId, responseAction) {
  let ordered = mkContactsOrder(uidsList)
  let scrollHandler = ScrollHandler()
  return {
    size = flex()
    children = [
      mkVerticalPannableArea(
        @() {
          watch = ordered
          size = FLEX_H
          flow = FLOW_VERTICAL
          children = ordered.value
            .map(@(uid, idx) mkContactRow(uid, idx,
              Computed(@() playerSelectedUserId.value == uid),
              @() playerSelectedUserId(uid),
              responseAction?(uid)))
        }, {}, { behavior = [ Behaviors.Pannable, Behaviors.ScrollEvent ], scrollHandler })
      mkScrollArrow(scrollHandler, MR_B)
    ]
  }
}

let noContactsMsg = {
  hplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT,
  text = loc("contacts/list_empty")
}.__update(fontSmall)

function contactsBlock(uidsList, playerSelectedUserId, responseAction) {
  let hasContacts = Computed(@() uidsList.value.len() != 0)
  return @() {
    watch = hasContacts
    size = flex()
    children = !hasContacts.value ? noContactsMsg
      : contactsList(uidsList, playerSelectedUserId, responseAction)
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

let playerSelectedUserId = mkWatched(persist, "selectedUserId")


function mkContactListScene(uidsList, mkContactActions, responseAction = null) {
  let selectedUserId = Computed(@() playerSelectedUserId.value in uidsList.value
    ? playerSelectedUserId.value
    : null)
  return {
    key = uidsList
    size = flex()
    flow = FLOW_HORIZONTAL
    gap
    children = [
      contactsBlock(uidsList, playerSelectedUserId, responseAction)
      buttons(selectedUserId, mkContactActions)
    ]
  }
}

return mkContactListScene