
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/features/category/presentation/bloc/category_bloc.dart';
import 'package:stylish_admin/features/category/presentation/widgets/add_category_dialog.dart';
import 'package:stylish_admin/features/category/presentation/widgets/category_grid.dart';
import 'package:stylish_admin/features/category/presentation/widgets/category_stats.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    context.read<CategoryBloc>().add(LoadCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    return  FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildContent(),
            ],
          ),
        ),

    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F3460), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.15 * 255).round()),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage your product categories',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildAddButton(),
        const SizedBox(width: 8),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => _showAddCategoryDialog(context),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Add', style: TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 1,
      ),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: () => context.read<CategoryBloc>().add(LoadCategoriesEvent()),
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text('Refresh', style: TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 1,
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoriesLoading) {
        } else if (state is CategoriesLoaded ||
            state is CategoriesLoadingMore) {
          final hasMorePages = (state is CategoriesLoaded)
              ? state.hasMorePages
              : (state as CategoriesLoadingMore).hasMorePages;

          final categories = (state is CategoriesLoaded)
              ? state.categories
              : (state as CategoriesLoadingMore).categories;

          return Expanded(
            child: Column(
              children: [
                Flexible(
                  flex: 1,
                  child: CategoryStats(categories: categories),
                ),
                const SizedBox(height: 8),
                Flexible(
                  flex: 9,
                  child: CategoryGrid(
                    categories: categories,
                    hasMorePages: hasMorePages,
                    onLoadMore: () {
                      if (state is! CategoriesLoadingMore) {
                        context
                            .read<CategoryBloc>()
                            .add(LoadMoreCategoriesEvent());
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        } else if (state is CategoriesError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<CategoryBloc>().add(LoadCategoriesEvent());
                  },
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (dialogContext) => const AddCategoryDialog(),
    ).then((_) {

    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
