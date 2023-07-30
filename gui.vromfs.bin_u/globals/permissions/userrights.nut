//checked for explicitness
#no-root-fallback
#explicit-this

let sharedWatched = require("%globalScripts/sharedWatched.nut")

let rights = sharedWatched("rights", @() {})
let rightsError = sharedWatched("rightsError", @() null)

return {
  rights
  rightsError
}