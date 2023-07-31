
let regexp2 = require("regexp2")

let rePlatfomPostfixes = [
  regexp2("@googleplay$") // Google Play
  regexp2("@psn$") // PlayStation Network
  regexp2("@live$") // Xbox Live
  regexp2("@epic$") // Epic
  regexp2("@steam$") // Steam
]

let function getPlayerName(name, myUsernameReal = "", myUsername = "") {
  if (type(name) != "string" || name == "")
    return ""

  if (name == myUsernameReal && myUsername != "")
    return myUsername

  foreach (re in rePlatfomPostfixes)
    name = re.replace("", name)

  return name
}

return {
  getPlayerName
}
