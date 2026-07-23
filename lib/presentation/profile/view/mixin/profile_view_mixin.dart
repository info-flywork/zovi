part of '../profile_view.dart';

enum ProfileContentTab { pulse, stamps, checkIn }

mixin ProfileViewMixin on State<ProfileView>, TickerProvider {
  late final TabController tabController;

  ProfileContentTab get selectedTab =>
      ProfileContentTab.values[tabController.index.clamp(0, 2)];

  void initProfileTabs() {
    tabController = TabController(length: 3, vsync: this);
  }

  void onTabSelected(ProfileContentTab tab) {
    if (tabController.index == tab.index) return;
    tabController.animateTo(tab.index);
  }

  void disposeProfileTabs() {
    tabController.dispose();
  }
}
