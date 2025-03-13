import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/user_model.dart';
import 'package:glam_connect/providers/main_provider.dart';
import 'package:glam_connect/screens/admin/analytics_screen.dart';
import 'package:glam_connect/screens/customer/appointments_screen.dart';
import 'package:glam_connect/screens/salon/staff_schedule_screen.dart';
import 'package:glam_connect/screens/salon/staff_list_screen.dart';
import 'package:glam_connect/screens/admin/salon_list_screen.dart';
import 'package:glam_connect/screens/admin/service_categories_screen.dart';
import 'package:glam_connect/screens/profile/profile_screen.dart';
import 'package:glam_connect/screens/salon/service_manager_screen.dart';

import '../features/auth/auth_page.dart';
import '../utils/app_colors.dart';
import 'home/home_screen.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(mainProvider.notifier).getIfUserLoggedIn();
      if (mounted) ref.read(mainProvider.notifier).setIsLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainProviderData = ref.watch(mainProvider);
    final bool showNavBar = mainProviderData.isUserLoggedIn;
    final UserModel? user = mainProviderData.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child:
            mainProviderData.isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppColor.primary),
                )
                : Stack(
                  children: [
                    _buildBody(mainProviderData, user),
                    if (showNavBar)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildNavBar(user),
                      ),
                  ],
                ),
      ),
    );
  }

  Widget _buildBody(MainProviderState mainProviderData, UserModel? user) {
    if (!mainProviderData.isUserLoggedIn || user == null) {
      return const AuthPage();
    } else {
      // Return the appropriate page based on user role and selected index
      return _getPageForUserRole(
        user.role,
        mainProviderData.selectedMainPageIndex,
        user,
      );
    }
  }

  Widget _buildNavBar(UserModel? user) {
    if (user == null) return const SizedBox();

    // Different navigation bars based on user role
    switch (user.role) {
      case UserRole.customer:
        return _buildUserNavBar();
      case UserRole.employee:
        return _buildEmployeeNavBar();
      case UserRole.salonAdmin:
        return _buildSalonAdminNavBar();
      case UserRole.superAdmin:
        return _buildSuperAdminNavBar();
      default:
        return _buildUserNavBar();
    }
  }

  // Navigation bar for normal users
  Widget _buildUserNavBar() {
    final mainProviderData = ref.watch(mainProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
            topLeft: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.calendar_today,
              0,
              mainProviderData,
              'Calendar',
            ),
            _buildNavItem(Icons.home, 1, mainProviderData, 'Home'),
            _buildNavItem(Icons.person, 2, mainProviderData, 'Profile'),
          ],
        ),
      ),
    );
  }

  // Navigation bar for employees
  Widget _buildEmployeeNavBar() {
    final mainProviderData = ref.watch(mainProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
            topLeft: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.calendar_today,
              0,
              mainProviderData,
              'Schedule',
            ),
            _buildNavItem(Icons.person, 1, mainProviderData, 'Profile'),
          ],
        ),
      ),
    );
  }

  // Navigation bar for salon admins
  Widget _buildSalonAdminNavBar() {
    final mainProviderData = ref.watch(mainProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
            topLeft: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.calendar_today,
              0,
              mainProviderData,
              'Calendar',
            ),
            _buildNavItem(Icons.people, 1, mainProviderData, 'Staff'),
            _buildNavItem(Icons.work, 2, mainProviderData, 'Services'),
            _buildNavItem(Icons.person, 3, mainProviderData, 'Profile'),
          ],
        ),
      ),
    );
  }

  // Navigation bar for super admins
  Widget _buildSuperAdminNavBar() {
    final mainProviderData = ref.watch(mainProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.store, 0, mainProviderData, 'Salons'),
            _buildNavItem(Icons.bar_chart, 1, mainProviderData, 'Analytics'),
            _buildNavItem(Icons.category, 2, mainProviderData, 'Categories'),
            _buildNavItem(Icons.person, 3, mainProviderData, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    int index,
    MainProviderState mainProviderData,
    String label,
  ) {
    final isSelected = mainProviderData.selectedMainPageIndex == index;

    return GestureDetector(
      onTap: () => ref.read(mainProvider.notifier).setSelectedPage(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Return the appropriate page based on user role and index
  Widget _getPageForUserRole(UserRole role, int index, UserModel? user) {
    // Placeholder screens - you'll need to implement these
    switch (role) {
      case UserRole.customer:
        switch (index) {
          case 0:
            return const AppointmentsScreen();
          case 1:
            return const HomeScreen();
          case 2:
            return const ProfileScreen();
          default:
            return const HomeScreen();
        }

      case UserRole.employee:
        switch (index) {
          case 0:
            return const Center(child: Text('Schedule Coming Soon'));
          case 1:
            return const ProfileScreen();
          default:
            return const Center(child: Text('Schedule Coming Soon'));
        }

      case UserRole.salonAdmin:
        switch (index) {
          case 0:
            final salonId = user?.salonId;
            if (salonId == null) {
              return const Center(child: Text('Salon ID not found'));
            }
            return StaffScheduleScreen(salonId: salonId);
          case 1:
            final salonId = user?.salonId;
            if (salonId == null) {
              return const Center(child: Text('Salon ID not found'));
            }
            return StaffListScreen(salonId: salonId);
          case 2:
            return const ServiceManagerScreen();
          case 3:
            return const ProfileScreen();
          default:
            return const Center(child: Text('Calendar Coming Soon'));
        }

      case UserRole.superAdmin:
        switch (index) {
          case 0:
            return const SalonListScreen();
          case 1:
            return const AnalyticsScreen();
          case 2:
            return const ServiceCategoriesScreen();
          case 3:
            return const ProfileScreen();
          default:
            return const SalonListScreen();
        }

      default:
        return const Center(child: Text('Home Page'));
    }
  }
}
