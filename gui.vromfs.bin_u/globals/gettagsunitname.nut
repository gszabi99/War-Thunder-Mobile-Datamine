from "%sqstd/functools.nut" import memoize


return memoize(@(realUnitName) realUnitName.endswith("_nc") ? realUnitName.slice(0, -3) : realUnitName)