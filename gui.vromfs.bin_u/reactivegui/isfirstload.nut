let { ndbExists, ndbWrite } = require("nestdb")

let isFirstLoad = !ndbExists("isLoadedOnce")
ndbWrite("isLoadedOnce", true)

return isFirstLoad