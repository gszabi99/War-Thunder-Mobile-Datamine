
let { subscribe, send } = require("eventbus")

let openFMsgBox = @(cfg) send("fMsgBox.open", cfg)
let closeFMsgBox = @(uid) send("fMsgBox.close", { uid })

let allBtns = {}
let subscribeFMsgBtns = @(buttons)
  buttons.each(function(action, id) {
    if (id in allBtns) {
      assert(false, $"Button {id} for fMsgBox already registered")
      return
    }
    allBtns[id] <- true
    subscribe($"fMsgBox.onClick.{id}", action)
  })

return {
  openFMsgBox
  closeFMsgBox
  subscribeFMsgBtns
}