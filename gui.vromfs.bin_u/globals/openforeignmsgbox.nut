
let { eventbus_subscribe, eventbus_send } = require("eventbus")

let openFMsgBox = @(cfg) eventbus_send("fMsgBox.open", cfg)
let closeFMsgBox = @(uid) eventbus_send("fMsgBox.close", { uid })

let allBtns = {}
let subscribeFMsgBtns = @(buttons)
  buttons.each(function(action, id) {
    if (id in allBtns) {
      assert(false, $"Button {id} for fMsgBox already registered")
      return
    }
    allBtns[id] <- true
    eventbus_subscribe($"fMsgBox.onClick.{id}", action)
  })

return {
  openFMsgBox
  closeFMsgBox
  subscribeFMsgBtns
}