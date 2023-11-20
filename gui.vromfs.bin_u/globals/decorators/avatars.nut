let defaultAvatar = "cardicon_silhouette"
let getAvatarImage = @(name) $"ui/images/avatars/{(name != null && name != "") ? name : defaultAvatar}.avif"

return getAvatarImage
