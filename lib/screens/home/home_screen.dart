import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam_connect/models/service_category_model.dart';
import 'package:glam_connect/providers/service_category_provider.dart';
import '../../utils/app_colors.dart';
import '../services/category_services_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final categoriesAsyncValue = ref.watch(serviceCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glam Connect'),
        backgroundColor: AppColor.primary,
      ),
      body: categoriesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (categories) {
          // Filter main categories (no parent) and exclude "Services" category
          final mainCategories =
              categories
                  .where(
                    (category) =>
                        category.parentCategoryId == null &&
                        category.isActive &&
                        category.name.toLowerCase() != 'services',
                  )
                  .toList();

          // Get "Services" category
          final servicesCategory = categories.firstWhere(
            (category) =>
                category.name.toLowerCase() == 'services' &&
                category.parentCategoryId == null,
            orElse:
                () => ServiceCategory(
                  id: 'services',
                  name: 'Services',
                  isActive: true,
                  createdAt: DateTime.now(),
                  createdBy: 'system',
                ),
          );

          // Get subcategories of "Services"
          final serviceSubcategories =
              categories
                  .where(
                    (category) =>
                        category.parentCategoryId == servicesCategory.id &&
                        category.isActive,
                  )
                  .toList();

          return CustomScrollView(
            slivers: [
              // Top Categories
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: mainCategories.length,
                    itemBuilder: (context, index) {
                      final category = mainCategories[index];

                      return Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CategoryServicesScreen(
                                      category: category,
                                    ),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (category.base64Image != null)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(category.base64Image!),
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.category,
                                  size: 32,
                                  color: Theme.of(context).primaryColor,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Services Section Title
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Services',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Services Grid
              SliverPadding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 120,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final category = serviceSubcategories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    CategoryServicesScreen(category: category),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 175,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child:
                                    category.base64Image != null
                                        ? Image.memory(
                                          base64Decode(category.base64Image!),
                                          fit: BoxFit.cover,
                                        )
                                        : Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.spa,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: serviceSubcategories.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
