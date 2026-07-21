part of '../profile_view.dart';

enum ProfileContentTab { pulse, stamps, checkIn }

mixin ProfileViewMixin on State<ProfileView> {
  ProfileContentTab selectedTab = ProfileContentTab.pulse;

  void onTabSelected(ProfileContentTab tab) {
    if (selectedTab == tab) return;
    setState(() => selectedTab = tab);
  }
}
