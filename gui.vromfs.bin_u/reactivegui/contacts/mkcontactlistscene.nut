from "%globalsDarg/darg_library.nut" import *
let mkContactRow = require("%rGui/contacts/mkContactRow.nut")
let { defButtonHeight } = require("%rGui/components/buttonStyles.nut")
let { topAreaSize, gradientHeightBottom } = require("%rGui/options/mkOptionsScene.nut")
let { mkScrollArrow } = require("%rGui/components/scrollArrows.nut")
let mkContactsOrder = require("%rGui/contacts/mkContactsOrder.nut")
let { verticalPannableAreaCtor } = require("%rGui/components/pannableArea.nut")


let gap = hdpx(24)

let mkVerticalPannableArea = verticalPannableAreaCtor(sh(100) - topAreaSize - defButtonHeight - gap * 2,
  [gap, gradientHeightBottom])

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
          children = ordered.get()
            .map(@(uid, idx) mkContactRow(uid, idx,
              Computed(@() playerSelectedUserId.get() == uid),
              @() playerSelectedUserId.set(uid),
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
  let hasContacts = Computed(@() uidsList.get().len() != 0)
  return @() {
    watch = hasContacts
    size = flex()
    children = !hasContacts.get() ? noContactsMsg
      : contactsList(uidsList, playerSelectedUserId, responseAction)
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


function mkContactListScene(uidsList, mkContactActions, responseAction = null) {
  let selectedUserId = Computed(@() playerSelectedUserId.get() in uidsList.get()
    ? playerSelectedUserId.get()
    : null)
  return {
    key = uidsList
    size = flex()
    flow = FLOW_VERTICAL
    gap
    children = [
      contactsBlock(uidsList, playerSelectedUserId, responseAction)
      buttons(selectedUserId, mkContactActions)
    ]
  }
}

return mkContactListScene