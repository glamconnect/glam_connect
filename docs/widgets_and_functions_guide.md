# GlamConnect Widgets and Functions Guide

## Table of Contents
1. [Common Widgets](#common-widgets)
   - [CustomTextField](#customtextfield)
   - [Custom Buttons](#custom-buttons)
   - [Image Components](#image-components)
2. [Service Management](#service-management)
   - [Models](#models)
   - [Providers](#providers)
   - [Screens](#screens)
3. [Firebase Integration](#firebase-integration)
4. [State Management](#state-management)
5. [Best Practices](#best-practices)
6. [Error Handling](#error-handling)

## Common Widgets

### CustomTextField
A highly customizable text input widget with consistent styling and validation.

#### Features
- Built-in validation support
- Customizable styling
- Support for prefix and suffix icons
- Multiple input types
- Error handling and display

#### Implementation

```dart
class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final bool enabled;

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
```

#### Usage Examples

1. Basic Text Input
```dart
CustomTextField(
  controller: nameController,
  hintText: 'Enter your name',
  validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
)
```

2. Password Input
```dart
CustomTextField(
  controller: passwordController,
  hintText: 'Enter password',
  obscureText: true,
  prefixIcon: Icon(Icons.lock),
  suffixIcon: IconButton(
    icon: Icon(Icons.visibility),
    onPressed: () => togglePasswordVisibility(),
  ),
)
```

3. Number Input with Validation
```dart
CustomTextField(
  controller: priceController,
  hintText: 'Enter price',
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Price is required';
    if (double.tryParse(value!) == null) return 'Invalid price';
    return null;
  },
)
```

## Service Management

### Models

#### ServiceModel
Core data model for salon services.

```dart
class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isActive;
  final String salonId;
  final String categoryId;
  final String? base64Image;
  final DateTime createdAt;
  final String createdBy;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isActive,
    required this.salonId,
    required this.categoryId,
    this.base64Image,
    required this.createdAt,
    required this.createdBy,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      isActive: json['isActive'] ?? false,
      salonId: json['salonId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      base64Image: json['base64Image'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] ?? '',
    );
  }
}
```

### Providers

#### ServiceProvider
Manages service-related state and operations using Riverpod.

```dart
final serviceProvider = StateNotifierProvider<ServiceNotifier, AsyncValue<List<ServiceModel>>>((ref) {
  return ServiceNotifier();
});

class ServiceNotifier extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  final _firestore = FirebaseFirestore.instance;

  Future<List<ServiceModel>> getServicesBySalonId(String salonId) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.servicesCollection)
          .where('salonId', isEqualTo: salonId)
          .get();

      final services = snapshot.docs
          .map((doc) => ServiceModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();

      state = AsyncValue.data(services);
      return services;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return [];
    }
  }

  Future<bool> createService({
    required String name,
    required String description,
    required String price,
    required bool isActive,
    required String salonId,
    required String categoryId,
    String? base64Image,
    required String createdBy,
  }) async {
    try {
      final serviceData = {
        'name': name.trim(),
        'description': description.trim(),
        'price': price.trim(),
        'isActive': isActive,
        'salonId': salonId,
        'categoryId': categoryId,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
        if (base64Image != null) 'base64Image': base64Image,
      };

      await _firestore.collection(Constants.servicesCollection).add(serviceData);
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

## Firebase Integration

### Firestore Service
Example of Firebase integration for service management:

```dart
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get services by salon
  Future<QuerySnapshot> getServices(String salonId) {
    return _firestore
        .collection('services')
        .where('salonId', isEqualTo: salonId)
        .get();
  }

  // Create new service
  Future<DocumentReference> createService(Map<String, dynamic> data) {
    return _firestore.collection('services').add(data);
  }

  // Update service
  Future<void> updateService(String id, Map<String, dynamic> data) {
    return _firestore.collection('services').doc(id).update(data);
  }

  // Delete service
  Future<void> deleteService(String id) {
    return _firestore.collection('services').doc(id).delete();
  }
}
```

## State Management

### Using Riverpod
Example of state management implementation:

```dart
// Provider definition
final serviceProvider = StateNotifierProvider<ServiceNotifier, AsyncValue<List<ServiceModel>>>((ref) {
  return ServiceNotifier();
});

// Usage in widget
class ServiceList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(serviceProvider).when(
      data: (services) => ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) => ServiceCard(service: services[index]),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

## Best Practices

### 1. Error Handling
```dart
try {
  await serviceProvider.createService(serviceData);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Service created successfully')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}
```

### 2. Form Validation
```dart
final _formKey = GlobalKey<FormState>();

void submitForm() {
  if (_formKey.currentState?.validate() ?? false) {
    // Process form data
  }
}
```

### 3. Resource Management
```dart
@override
void dispose() {
  // Dispose controllers
  nameController.dispose();
  descriptionController.dispose();
  priceController.dispose();
  super.dispose();
}
```

## Error Handling

### 1. Service Operations
```dart
Future<void> handleServiceOperation(Future<bool> operation()) async {
  try {
    final success = await operation();
    if (success) {
      showSuccessMessage('Operation completed successfully');
    } else {
      showErrorMessage('Operation failed');
    }
  } catch (e) {
    showErrorMessage('Error: ${e.toString()}');
  }
}
```

### 2. Image Handling
```dart
Future<String?> handleImageUpload() async {
  try {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (pickedFile == null) return null;
    
    final bytes = await pickedFile.readAsBytes();
    return base64Encode(bytes);
  } catch (e) {
    showErrorMessage('Error uploading image: ${e.toString()}');
    return null;
  }
}
```
  validator: (value) => value?.isEmpty ?? true ? 'Field required' : null,
  maxLines: 1,  // Optional
  keyboardType: TextInputType.text,  // Optional
)
```

### 2. Service Management Widgets

#### ServiceManagerScreen
Main screen for managing salon services. Key features:
- Add/Edit services with image upload
- Toggle service active status
- Categorize services
- Price management

## Navigation System

### Bottom Navigation Bar

The app implements role-based navigation using a custom bottom navigation bar that adapts to different user types:
1. Salon Admin
2. Salon Staff
3. Customer
4. Guest User

#### Implementation

```dart
class CustomBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final UserType userType;

  const CustomBottomNavBar({
    required this.currentIndex,
    required this.userType,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _handleNavigation(context, index),
      items: _getNavigationItems(),
    );
  }

  List<BottomNavigationBarItem> _getNavigationItems() {
    switch (userType) {
      case UserType.salonAdmin:
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
        ];
      
      case UserType.salonStaff:
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      
      case UserType.customer:
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
      
      case UserType.guest:
        return [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Login',
          ),
        ];
    }
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (userType) {
      case UserType.salonAdmin:
        _handleSalonAdminNavigation(context, index);
        break;
      case UserType.salonStaff:
        _handleStaffNavigation(context, index);
        break;
      case UserType.customer:
        _handleCustomerNavigation(context, index);
        break;
      case UserType.guest:
        _handleGuestNavigation(context, index);
        break;
    }
  }

  void _handleSalonAdminNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StaffManagerScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ServiceManagerScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BookingsScreen()),
        );
        break;
    }
  }
}
```

#### Usage Example

```dart
class MainScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeProvider);
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: _buildBody(userType, currentIndex),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        userType: userType,
      ),
    );
  }

  Widget _buildBody(UserType userType, int currentIndex) {
    // Return appropriate screen based on userType and currentIndex
  }
}
```

### Screen Access Control

```dart
class NavigationGuard extends ConsumerWidget {
  final Widget child;
  final List<UserType> allowedUsers;

  const NavigationGuard({
    required this.child,
    required this.allowedUsers,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeProvider);

    if (!allowedUsers.contains(userType)) {
      return UnauthorizedScreen();
    }

    return child;
  }
}

// Usage with Service Management
NavigationGuard(
  allowedUsers: [UserType.salonAdmin],
  child: ServiceManagerScreen(),
)
```

### Service Management Integration

#### Salon Admin Service Flow
```dart
class SalonAdminDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(serviceProvider).value ?? [];
    
    return Scaffold(
      appBar: AppBar(title: Text('Salon Dashboard')),
      body: Column(
        children: [
          // Service Statistics
          ServiceStatsCard(
            totalServices: services.length,
            activeServices: services.where((s) => s.isActive).length,
          ),
          // Quick Actions
          GridView.count(
            crossAxisCount: 2,
            children: [
              ActionCard(
                icon: Icons.spa,
                title: 'Manage Services',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ServiceManagerScreen()),
                ),
              ),
              // Other action cards
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        userType: UserType.salonAdmin,
      ),
    );
  }
}
```

#### Staff Service View
```dart
class StaffServiceView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(serviceProvider).value ?? [];
    
    return Scaffold(
      appBar: AppBar(title: Text('Available Services')),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ServiceCard(
            service: service,
            // Staff can only view services, not edit
            onTap: () => showServiceDetails(context, service),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        userType: UserType.salonStaff,
      ),
    );
  }
}
```

#### Customer Service Booking
```dart
class CustomerServiceBooking extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(serviceProvider).value ?? [];
    
    return Scaffold(
      appBar: AppBar(title: Text('Book Services')),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ServiceBookingCard(
            service: service,
            onBookNow: () => navigateToBooking(context, service),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1, // Explore tab
        userType: UserType.customer,
      ),
    );
  }
}
```

#### Guest Service Preview
```dart
class GuestServicePreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(serviceProvider).value ?? [];
    
    return Scaffold(
      appBar: AppBar(title: Text('Explore Services')),
      body: Column(
        children: [
          // Limited preview of services
          Expanded(
            child: ListView.builder(
              itemCount: min(services.length, 5), // Show only first 5 services
              itemBuilder: (context, index) {
                final service = services[index];
                return ServicePreviewCard(
                  service: service,
                  onTap: () => showLoginPrompt(context),
                );
              },
            ),
          ),
          // Login prompt
          LoginPromptCard(
            message: 'Sign up to book services and get exclusive offers!',
            onLogin: () => Navigator.pushNamed(context, '/login'),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1, // Explore tab
        userType: UserType.guest,
      ),
    );
  }
}
```

## Authentication and User Management

### User Type Provider
```dart
enum UserType { salonAdmin, salonStaff, customer, guest }

final userTypeProvider = StateProvider<UserType>((ref) => UserType.guest);

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProvider = FutureProvider<UserModel?>((ref) async {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) {
    ref.read(userTypeProvider.notifier).state = UserType.guest;
    return null;
  }
  
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(auth.uid)
      .get();
      
  if (!doc.exists) return null;
  
  final user = UserModel.fromJson(doc.data()!);
  ref.read(userTypeProvider.notifier).state = user.type;
  return user;
});
```

### Role-Based Route Guard
```dart
class RoleBasedRoute extends ConsumerWidget {
  final Widget Function(UserType) builder;
  final List<UserType> allowedRoles;

  const RoleBasedRoute({
    required this.builder,
    required this.allowedRoles,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authStateProvider).when(
      data: (user) {
        if (user == null) {
          return LoginScreen();
        }
        
        return ref.watch(userProvider).when(
          data: (userData) {
            if (userData == null) return LoginScreen();
            
            if (!allowedRoles.contains(userData.type)) {
              return UnauthorizedScreen();
            }
            
            return builder(userData.type);
          },
          loading: () => LoadingScreen(),
          error: (_, __) => ErrorScreen(),
        );
      },
      loading: () => LoadingScreen(),
      error: (_, __) => ErrorScreen(),
    );
  }
}
```

### Authentication Flow
```dart
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserCredential> registerSalon({
    required String email,
    required String password,
    required String salonName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'type': 'salonAdmin',
      'salonId': credential.user!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('salons').doc(credential.user!.uid).set({
      'name': salonName,
      'ownerId': credential.user!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<UserCredential> registerCustomer({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'name': name,
      'type': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }
}
```

## Service Categories and Subcategories

### Models

#### Category Model
```dart
class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final List<ServiceSubcategory> subcategories;
  final String salonId;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.subcategories,
    required this.salonId,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
      salonId: json['salonId'] ?? '',
      subcategories: (json['subcategories'] as List<dynamic>? ?? [])
          .map((e) => ServiceSubcategory.fromJson(e))
          .toList(),
    );
  }
}

class ServiceSubcategory {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  ServiceSubcategory({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory ServiceSubcategory.fromJson(Map<String, dynamic> json) {
    return ServiceSubcategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}
```

### Category Management

#### Category Provider
```dart
final serviceCategoryProvider = StateNotifierProvider<ServiceCategoryNotifier, AsyncValue<List<ServiceCategory>>>((ref) {
  return ServiceCategoryNotifier();
});

class ServiceCategoryNotifier extends StateNotifier<AsyncValue<List<ServiceCategory>>> {
  final _firestore = FirebaseFirestore.instance;

  ServiceCategoryNotifier() : super(const AsyncValue.loading());

  Future<void> loadCategories(String salonId) async {
    try {
      final snapshot = await _firestore
          .collection('serviceCategories')
          .where('salonId', isEqualTo: salonId)
          .get();

      final categories = snapshot.docs
          .map((doc) => ServiceCategory.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      state = AsyncValue.data(categories);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<bool> createCategory({
    required String name,
    required String description,
    required String salonId,
  }) async {
    try {
      await _firestore.collection('serviceCategories').add({
        'name': name,
        'description': description,
        'isActive': true,
        'salonId': salonId,
        'subcategories': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await loadCategories(salonId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addSubcategory({
    required String categoryId,
    required String name,
    required String description,
    required String salonId,
  }) async {
    try {
      final subcategory = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'description': description,
        'isActive': true,
      };

      await _firestore.collection('serviceCategories').doc(categoryId).update({
        'subcategories': FieldValue.arrayUnion([subcategory]),
      });

      await loadCategories(salonId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

#### Category Selection in Service Form
```dart
class CategorySelector extends ConsumerWidget {
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final Function(String) onCategorySelected;
  final Function(String) onSubcategorySelected;

  const CategorySelector({
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.onCategorySelected,
    required this.onSubcategorySelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(serviceCategoryProvider).value ?? [];
    final selectedCategory = categories
        .firstWhere((c) => c.id == selectedCategoryId,
            orElse: () => categories.first);

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedCategoryId,
          decoration: const InputDecoration(labelText: 'Category'),
          items: categories
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ))
              .toList(),
          onChanged: (value) => onCategorySelected(value!),
        ),
        if (selectedCategory.subcategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedSubcategoryId,
            decoration: const InputDecoration(labelText: 'Subcategory'),
            items: selectedCategory.subcategories
                .map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    ))
                .toList(),
            onChanged: (value) => onSubcategorySelected(value!),
          ),
        ],
      ],
    );
  }
}
```

## Firebase Storage Integration

### Service Photo Management

#### Storage Service
```dart
class StorageService {
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<String?> uploadServicePhoto({
    required String salonId,
    required String serviceId,
    required String base64Image,
  }) async {
    try {
      // Convert base64 to bytes
      final imageBytes = base64Decode(base64Image);
      
      // Create storage reference
      final storageRef = _storage
          .ref()
          .child('salons')
          .child(salonId)
          .child('services')
          .child('$serviceId.jpg');

      // Upload image
      final uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'salonId': salonId,
            'serviceId': serviceId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get download URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update service with photo URL
      await _firestore
          .collection('services')
          .doc(serviceId)
          .update({'photoUrl': downloadUrl});

      return downloadUrl;
    } catch (e) {
      print('Error uploading service photo: $e');
      return null;
    }
  }

  Future<bool> deleteServicePhoto({
    required String salonId,
    required String serviceId,
  }) async {
    try {
      final storageRef = _storage
          .ref()
          .child('salons')
          .child(salonId)
          .child('services')
          .child('$serviceId.jpg');

      await storageRef.delete();

      await _firestore
          .collection('services')
          .doc(serviceId)
          .update({'photoUrl': null});

      return true;
    } catch (e) {
      print('Error deleting service photo: $e');
      return false;
    }
  }
}
```

#### Photo Upload Widget
```dart
class ServicePhotoUpload extends ConsumerStatefulWidget {
  final String? initialPhotoUrl;
  final Function(String) onPhotoSelected;

  const ServicePhotoUpload({
    this.initialPhotoUrl,
    required this.onPhotoSelected,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ServicePhotoUpload> createState() => _ServicePhotoUploadState();
}

class _ServicePhotoUploadState extends ConsumerState<ServicePhotoUpload> {
  String? _base64Image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _base64Image = base64Encode(bytes);
        });
        widget.onPhotoSelected(_base64Image!);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_base64Image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          base64Decode(_base64Image!),
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.initialPhotoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          widget.initialPhotoUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(child: CircularProgressIndicator());
          },
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_photo_alternate, size: 40),
        SizedBox(height: 8),
        Text('Add Photo'),
      ],
    );
  }
}
```

#### Usage in Service Form
```dart
ServicePhotoUpload(
  initialPhotoUrl: service?.photoUrl,
  onPhotoSelected: (base64Image) {
    setState(() {
      _photoBase64 = base64Image;
    });
  },
)
```

## Service Model

### Service Data Model
```dart
class ServiceModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isActive;
  final String salonId;
  final String categoryId;
  final String? subcategoryId;
  final String? photoUrl;
  final String createdBy;
  final DateTime createdAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isActive,
    required this.salonId,
    required this.categoryId,
    this.subcategoryId,
    this.photoUrl,
    required this.createdBy,
    required this.createdAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? false,
      salonId: json['salonId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      subcategoryId: json['subcategoryId'],
      photoUrl: json['photoUrl'],
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'isActive': isActive,
      'salonId': salonId,
      'categoryId': categoryId,
      if (subcategoryId != null) 'subcategoryId': subcategoryId,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    bool? isActive,
    String? salonId,
    String? categoryId,
    String? subcategoryId,
    String? photoUrl,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      salonId: salonId ?? this.salonId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      photoUrl: photoUrl ?? this.photoUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### Firestore Schema
```json
{
  "services": {
    "serviceId": {
      "name": "string",
      "description": "string",
      "price": "number",
      "isActive": "boolean",
      "salonId": "string (reference)",
      "categoryId": "string (reference)",
      "subcategoryId": "string (reference, optional)",
      "photoUrl": "string (optional)",
      "createdBy": "string (reference)",
      "createdAt": "timestamp"
    }
  }
}
```

## Service State Management

### Service Provider Implementation
```dart
final serviceProvider = StateNotifierProvider<ServiceNotifier, AsyncValue<List<ServiceModel>>>((ref) {
  return ServiceNotifier();
});

class ServiceNotifier extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  final _firestore = FirebaseFirestore.instance;

  ServiceNotifier() : super(const AsyncValue.loading());

  // Get services with category data
  Future<List<ServiceModel>> getServicesBySalonId(String salonId) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.servicesCollection)
          .where('salonId', isEqualTo: salonId)
          .get();

      // Get referenced categories
      final categoryIds = snapshot.docs
          .map((doc) => doc.data()['categoryId'] as String)
          .toSet();

      Map<String, Map<String, dynamic>> categoryMap = {};

      // Fetch categories in batches
      for (var i = 0; i < categoryIds.length; i += 10) {
        final batch = categoryIds.skip(i).take(10).toList();
        final batchSnapshot = await _firestore
            .collection(Constants.categoriesCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        categoryMap.addAll(
          Map.fromEntries(
            batchSnapshot.docs.map((doc) => MapEntry(doc.id, doc.data())),
          ),
        );
      }

      // Filter active services with active categories
      final services = snapshot.docs
          .where((doc) => doc.data()['isActive'] ?? false)
          .map((doc) {
            final data = doc.data();
            final categoryData = categoryMap[data['categoryId']];
            if (categoryData == null || !(categoryData['isActive'] ?? false)) {
              return null;
            }
            return ServiceModel.fromJson({'id': doc.id, ...data});
          })
          .where((service) => service != null)
          .cast<ServiceModel>()
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = AsyncValue.data(services);
      return services;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return [];
    }
  }

  // Create new service
  Future<bool> createService({
    required String name,
    required String description,
    required String price,
    required bool isActive,
    required String salonId,
    required String categoryId,
    String? base64Image,
    required String createdBy,
  }) async {
    try {
      // Verify category exists and is active
      final categoryDoc = await _firestore
          .collection(Constants.categoriesCollection)
          .doc(categoryId)
          .get();

      if (!categoryDoc.exists || !(categoryDoc.data()?['isActive'] ?? false)) {
        throw Exception('Selected category does not exist or is inactive');
      }

      final serviceData = <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'price': price.trim(),
        'isActive': isActive,
        'salonId': salonId.trim(),
        'categoryId': categoryId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy.trim(),
        if (base64Image != null && base64Image.isNotEmpty)
          'base64Image': base64Image,
      };

      await _firestore.collection(Constants.servicesCollection).add(serviceData);
      await getServicesBySalonId(salonId); // Refresh list
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update existing service
  Future<bool> updateService({
    required String id,
    required String name,
    required String description,
    required double price,
    required bool isActive,
    required String salonId,
    required String categoryId,
    String? base64Image,
  }) async {
    try {
      final updateData = {
        'name': name,
        'description': description,
        'price': price,
        'isActive': isActive,
        'categoryId': categoryId,
        if (base64Image != null) 'base64Image': base64Image,
      };

      await _firestore
          .collection(Constants.servicesCollection)
          .doc(id)
          .update(updateData);

      await getServicesBySalonId(salonId); // Refresh list
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete service
  Future<bool> deleteService(String id, String salonId) async {
    try {
      await _firestore.collection(Constants.servicesCollection).doc(id).delete();
      await getServicesBySalonId(salonId); // Refresh list
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

### Usage in Widgets

#### Service List with Role-Based Access
```dart
class ServiceList extends ConsumerWidget {
  final UserType userType;

  const ServiceList({required this.userType, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(serviceProvider).when(
      data: (services) {
        // Filter services based on user type
        final filteredServices = switch (userType) {
          UserType.salonAdmin => services,
          UserType.salonStaff => services,
          UserType.customer => services.where((s) => s.isActive).toList(),
          UserType.guest => services.where((s) => s.isActive).take(5).toList(),
        };

        return ListView.builder(
          itemCount: filteredServices.length,
          itemBuilder: (context, index) {
            final service = filteredServices[index];
            return ServiceCard(
              service: service,
              userType: userType,
              onEdit: userType == UserType.salonAdmin
                  ? () => _editService(context, service)
                  : null,
              onDelete: userType == UserType.salonAdmin
                  ? () => _deleteService(context, service)
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  void _editService(BuildContext context, ServiceModel service) {
    showDialog(
      context: context,
      builder: (_) => ServiceEditDialog(service: service),
    );
  }

  Future<void> _deleteService(BuildContext context, ServiceModel service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        title: 'Delete Service',
        content: 'Are you sure you want to delete ${service.name}?',
      ),
    );

    if (confirm ?? false) {
      final success = await ref
          .read(serviceProvider.notifier)
          .deleteService(service.id, service.salonId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Service deleted successfully' : 'Failed to delete service',
          ),
        ),
      );
    }
  }
}
```

## Service Display Components

### Service Card Widget
```dart
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final UserType userType;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onBook;

  const ServiceCard({
    required this.service,
    required this.userType,
    this.onEdit,
    this.onDelete,
    this.onBook,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (service.photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              child: Image.network(
                service.photoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error_outline),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (!service.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Inactive',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  service.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '\$${service.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const Spacer(),
                    if (userType == UserType.salonAdmin) ...[  
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: onDelete,
                      ),
                    ] else if (userType == UserType.customer && service.isActive) ...[  
                      ElevatedButton(
                        onPressed: onBook,
                        child: const Text('Book Now'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Service Grid View
```dart
class ServiceGrid extends StatelessWidget {
  final List<ServiceModel> services;
  final UserType userType;
  final Function(ServiceModel)? onServiceSelected;

  const ServiceGrid({
    required this.services,
    required this.userType,
    this.onServiceSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ServiceCard(
          service: service,
          userType: userType,
          onBook: onServiceSelected != null
              ? () => onServiceSelected!(service)
              : null,
        );
      },
    );
  }
}
```

### Usage Example
```dart
class ServiceExploreScreen extends ConsumerWidget {
  const ServiceExploreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeProvider);
    final services = ref.watch(serviceProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Explore Services')),
      body: ServiceGrid(
        services: services,
        userType: userType,
        onServiceSelected: (service) {
          if (userType == UserType.guest) {
            showDialog(
              context: context,
              builder: (_) => const LoginPromptDialog(),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServiceBookingScreen(service: service),
              ),
            );
          }
        },
      ),
    );
  }
}
```

### 3. Form Components

#### Image Picker Component
```dart
GestureDetector(
  onTap: pickImage,
  child: Container(
    height: 100,
    width: 100,
    decoration: BoxDecoration(
      color: AppColor.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: /* Image or Icon widget */,
  ),
)
```

#### Category Dropdown
```dart
DropdownButtonFormField<String>(
  value: selectedCategoryId,
  decoration: const InputDecoration(
    labelText: 'Category',
    border: OutlineInputBorder(),
  ),
  items: categories.map((category) {
    return DropdownMenuItem(
      value: category.id,
      child: Text(category.name),
    );
  }).toList(),
  onChanged: (value) => setState(() => selectedCategoryId = value),
)
```

## Important Functions

### 1. Image Handling
```dart
Future<void> pickImage() async {
  final pickedFile = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 85,
  );

  if (pickedFile != null) {
    final imageBytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    // Use base64Image as needed
  }
}
```

### 2. Service Management Functions

#### Load Services
```dart
// In your provider
Future<void> getServicesBySalonId(String salonId) async {
  // Implementation to fetch services from Firestore
}

// Usage in widget
ref.read(serviceProvider.notifier).getServicesBySalonId(salonId);
```

#### Add/Update Service
```dart
// Basic structure for service data
final serviceData = ServiceModel(
  name: nameController.text,
  description: descriptionController.text,
  price: double.parse(priceController.text),
  categoryId: selectedCategoryId,
  isActive: true,
  base64Image: profileImageBase64,
);

// Save to Firestore via provider
await ref.read(serviceProvider.notifier).addService(serviceData);
```

## State Management

The app uses Riverpod for state management. Key providers:
- `serviceProvider`: Manages service-related state and operations
- `serviceCategoryProvider`: Handles service categories
- `mainProvider`: Manages global app state

```dart
// Example provider usage
final services = ref.watch(serviceProvider).value;
final categories = ref.watch(serviceCategoryProvider).value;
```

## Best Practices

1. Always dispose controllers in StatefulWidget
```dart
@override
void dispose() {
  nameController.dispose();
  descriptionController.dispose();
  priceController.dispose();
  super.dispose();
}
```

2. Use Form validation
```dart
if (_formKey.currentState?.validate() ?? false) {
  // Proceed with form submission
}
```

3. Handle loading and error states
```dart
ref.watch(serviceProvider).when(
  data: (services) => /* Build UI with data */,
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```
