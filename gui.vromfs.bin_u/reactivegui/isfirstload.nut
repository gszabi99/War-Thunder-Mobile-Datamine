from "nestdb" import ndbExists, ndbWrite


let isFirstLoad = !ndbExists("isLoadedOnce")
ndbWrite("isLoadedOnce", true)

return isFirstLoad