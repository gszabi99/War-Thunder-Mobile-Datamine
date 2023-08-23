let defaultAvatar = "cardicon_silhouette"
let getAvatarImage = @(name) $"ui/images/avatars/{name ?? defaultAvatar}.avif"

return getAvatarImage
