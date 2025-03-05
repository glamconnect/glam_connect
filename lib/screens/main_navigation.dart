import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/user_model.dart';
import 'package:glam_connect/providers/main_provider.dart';
import 'package:glam_connect/screens/admin/salon_list_screen.dart';
import 'package:glam_connect/screens/auth/login_screen.dart';
import 'package:glam_connect/utils/app_theme.dart';

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
        child: mainProviderData.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
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
      return const LoginScreen();
    } else {
      // Return the appropriate page based on user role and selected index
      return _getPageForUserRole(user.role, mainProviderData.selectedMainPageIndex);
    }
  }

  Widget _buildNavBar(UserModel? user) {
    if (user == null) return const SizedBox();
    
    // Different navigation bars based on user role
    switch (user.role) {
      case UserRole.normalUser:
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
    
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
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
          _buildNavItem(Icons.calendar_today, 0, mainProviderData, 'Calendar'),
          _buildNavItem(Icons.home, 1, mainProviderData, 'Home'),
          _buildNavItem(Icons.person, 2, mainProviderData, 'Profile'),
        ],
      ),
    );
  }

  // Navigation bar for employees
  Widget _buildEmployeeNavBar() {
    final mainProviderData = ref.watch(mainProvider);
    
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
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
          _buildNavItem(Icons.calendar_today, 0, mainProviderData, 'Schedule'),
          _buildNavItem(Icons.person, 1, mainProviderData, 'Profile'),
        ],
      ),
    );
  }

  // Navigation bar for salon admins
  Widget _buildSalonAdminNavBar() {
    final mainProviderData = ref.watch(mainProvider);
    
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
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
          _buildNavItem(Icons.calendar_today, 0, mainProviderData, 'Calendar'),
          _buildNavItem(Icons.people, 1, mainProviderData, 'Staff'),
          _buildNavItem(Icons.work, 2, mainProviderData, 'Services'),
          _buildNavItem(Icons.person, 3, mainProviderData, 'Profile'),
        ],
      ),
    );
  }

  // Navigation bar for super admins
  Widget _buildSuperAdminNavBar() {
    final mainProviderData = ref.watch(mainProvider);
    
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
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
          _buildNavItem(Icons.person, 2, mainProviderData, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, MainProviderState mainProviderData, String label) {
    final isSelected = mainProviderData.selectedMainPageIndex == index;
    
    return GestureDetector(
      onTap: () => ref.read(mainProvider.notifier).setSelectedPage(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.black : Colors.white,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Return the appropriate page based on user role and index
  Widget _getPageForUserRole(UserRole role, int index) {
    // Placeholder screens - you'll need to implement these
    switch (role) {
      case UserRole.normalUser:
        switch (index) {
          case 0: return const Center(child: Text('User Calendar Page'));
          case 1: return const Center(child: Text('User Home Page'));
          case 2: return const Center(child: Text('User Profile Page'));
          default: return const Center(child: Text('User Home Page'));
        }
      
      case UserRole.employee:
        switch (index) {
          case 0: return const Center(child: Text('Employee Schedule Page'));
          case 1: return const Center(child: Text('Employee Profile Page'));
          default: return const Center(child: Text('Employee Schedule Page'));
        }
      
      case UserRole.salonAdmin:
        switch (index) {
          case 0: return const Center(child: Text('Salon Admin Calendar Page'));
          case 1: return const Center(child: Text('Salon Admin Staff Page'));
          case 2: return const Center(child: Text('Salon Admin Services Page'));
          case 3: return const Center(child: Text('Salon Admin Profile Page'));
          default: return const Center(child: Text('Salon Admin Calendar Page'));
        }
      
      case UserRole.superAdmin:
        switch (index) {
          case 0: return const SalonListScreen();
          case 1: return const Center(child: Text('Super Admin Analytics Page'));
          case 2: return const Center(child: Text('Super Admin Profile Page'));
          default: return const SalonListScreen();
        }
      
      default:
        return const Center(child: Text('Home Page'));
    }
  }
}
