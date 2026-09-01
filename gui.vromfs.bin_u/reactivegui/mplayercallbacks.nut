let { eventbus_subscribe } = require("eventbus")
let { registerMplayerCallbacks } = require("mplayer_callbacks")
let { frameNick } = require("%appGlobals/decorators/nickFrames.nut")
let { getPlayerName } = require("%appGlobals/user/nickTools.nut")
let { myUserName, myUserRealName } = require("%appGlobals/profileStates.nut")
let { squadMembers } = require("%appGlobals/squadState.nut")
let { registerRespondent } = require("scriptRespondent")

eventbus_subscribe("register_mplayer_callbacks",
  @(_) registerMplayerCallbacks({
    frameNick = @(nick, frameId) frameNick(getPlayerName(nick, myUserRealName.get(), myUserName.get()), frameId)
  }))

registerRespondent("is_in_my_squad", @(userId, _checkAutosquad = true) userId in squadMembers.get())
