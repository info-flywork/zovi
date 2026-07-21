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
  stories('/stories'),
  chat('/chat'),
  profile('/profile'),
  editProfile('/profile/edit'),
  editProfileField('/profile/edit/field'),
  editProfileLinks('/profile/edit/links'),
  addProfileLink('/profile/edit/links/add'),
  addPlan('/profile/add-plan'),
  addPlanDetails('/profile/add-plan/details'),
  addPlanSuccess('/profile/add-plan/success'),
  discover('/discover');

  const RoutePaths(this.path);
  final String path;

  String get name => toString().split('.').last;
}
