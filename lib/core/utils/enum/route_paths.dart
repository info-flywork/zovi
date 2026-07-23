enum RoutePaths {
  splash('/'),
  intro('/intro'),
  onboarding('/onboarding'),
  otp('/otp'),
  phoneVerified('/phone-verified'),
  createProfile('/create-profile'),
  birthday('/birthday'),
  notificationPermission('/notification-permission'),
  locationPermission('/location-permission'),
  home('/home'),
  checkInSuccess('/home/check-in/success'),
  notifications('/notifications'),
  stories('/stories'),
  storyDetail('/stories/detail'),
  chat('/chat'),
  chatDetail('/chat/detail'),
  chatRequests('/chat/requests'),
  profile('/profile'),
  profileConnections('/profile/connections'),
  userProfile('/profile/user'),
  editProfile('/profile/edit'),
  editProfileField('/profile/edit/field'),
  editProfileLinks('/profile/edit/links'),
  addProfileLink('/profile/edit/links/add'),
  addPlan('/profile/add-plan'),
  addPlanDetails('/profile/add-plan/details'),
  addPlanSuccess('/profile/add-plan/success'),
  settings('/profile/settings'),
  personalInfo('/profile/settings/personal-info'),
  changePassword('/profile/settings/change-password'),
  stickers('/profile/stickers'),
  createSticker('/profile/stickers/create'),
  createStickerSuccess('/profile/stickers/create/success'),
  tribe('/tribe'),
  groupInfo('/chat/group-info'),
  groupGallery('/chat/group-info/gallery'),
  discover('/discover');

  const RoutePaths(this.path);
  final String path;

  String get name => toString().split('.').last;
}
