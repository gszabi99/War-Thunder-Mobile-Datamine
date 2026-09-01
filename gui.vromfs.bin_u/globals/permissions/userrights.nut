from "%sqstd/globalState.nut" import hardPersistWatched


let rights = hardPersistWatched("rights", {})
let rightsError = hardPersistWatched("rightsError", null)

return {
  rights
  rightsError
}