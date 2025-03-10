let { memoize } = require("%sqstd/functools.nut")

return memoize(@(realUnitName) realUnitName.endswith("_nc") ? realUnitName.slice(0, -3) : realUnitName)