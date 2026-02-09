from "frp" import Computed
import "%globalScripts/sharedWatched.nut" as sharedWatched

let steamLanguages = {
  English = "english"
  French = "french"
  Italian = "italian"
  German = "german"
  Spanish = "spanish"
  Russian = "russian"
  Polish = "polish"
  Czech = "czech"
  Turkish = "turkish"
  Chinese = "schinese"
  Japanese = "japanese"
  Portuguese = "portuguese"
  Greek = "greek"
  Ukrainian = "ukrainian"
  Hungarian = "hungarian"
  Korean = "koreana"
  TChinese = "tchinese"
  HChinese = "schinese"
  Thai = "thai"
}

let currentLanguage = sharedWatched("currentLanguage", @() "")
let currentSteamLanguage = Computed(@() steamLanguages?[currentLanguage.get()] ?? "english")

return {
  currentLanguage
  currentSteamLanguage
}