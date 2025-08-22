import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/variations/domain/entities/product_variant_entity.dart';
import 'package:stylish_admin/features/variations/presentation/bloc/product_variant_bloc.dart';
import 'package:stylish_admin/features/variations/presentation/pages/components/ui_components.dart';

class ProductVariationsScreen extends StatefulWidget {
  final String productId;
  final Map<String, List<String>> initialVariations;
  final List<ProductVariantEntity>? initialVariants;
  final List<String>? initialSizes;
  final double basePrice;
  final int currentStock;
  const ProductVariationsScreen({
    super.key,
    required this.productId,
    required this.initialVariations,
    this.initialVariants,
    required this.initialSizes,
    required this.basePrice,
    required this.currentStock,
  });

  @override
  State<ProductVariationsScreen> createState() =>
      _ProductVariationsScreenState();
}

class _ProductVariationsScreenState extends State<ProductVariationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();

  final bool _isSavingDialogShowing = false;
  @override
  void initState() {
    super.initState();
    context.read<ProductVariantBloc>().add(
      InitializeVariationsDataEvent(
        productId: widget.productId,
        initialVariations: widget.initialVariations,
        initialSizes: widget.initialSizes,
        basePrice: widget.basePrice,
        currentStock: widget.currentStock,
        initialVariants: widget.initialVariants, 
      ),
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    if (!context.read<ProductVariantBloc>().state.isDirty) return true;

    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes?', style: AppTheme.headingMedium()),
        content: Text(
          'You have unsaved changes. Are you sure you want to leave?',
          style: AppTheme.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.negative),
            child: const Text('DISCARD', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveChanges() async {
    final bloc = context.read<ProductVariantBloc>();
    if (bloc.state.isOperationLoading) return;

    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      bloc.add(SaveVariationsEvent());
    }
  }

  void _handleBlocState(BuildContext context, ProductVariantState state) {
    if (_isSavingDialogShowing &&
        !state.isOperationLoading &&
        (state.isOperationSuccess || state.errorMessage != null)) {}

    // show success message
    if (state.isOperationSuccess) {
      _showNotification('Variations saved successfully!');
      context.read<ProductVariantBloc>().add(
        ClearVariantOperationSuccessEvent(),
      );
    }
    // show error message
    else if (state.errorMessage != null) {
      _showNotification('Error: ${state.errorMessage}', isError: true);
      context.read<ProductVariantBloc>().add(ClearVariantErrorEvent());
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.negative : AppTheme.positive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocState = context.watch<ProductVariantBloc>().state;
    final bool hasChanges = blocState.isDirty;
    final bool isLoading = blocState.isOperationLoading;
    return PopScope(
      canPop: !hasChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: VariationsAppBar(
          hasChanges: hasChanges,
          onSave: _saveChanges,
          onShowHelp: () {
            /*Implement help dialog if needed */
          },
          onBack: () async {
            final shouldPop = await _confirmDiscard();
            if (shouldPop && mounted) Navigator.of(context).pop();
          },
        ),
        body: BlocListener<ProductVariantBloc, ProductVariantState>(
          listener: _handleBlocState,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: AppTheme.backgroundDark,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VariationsHeader(
                        onRefresh: () => context.read<ProductVariantBloc>().add(
                          GetProductVariantsEvent(widget.productId),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),
                      VariationsCard(
                        productId: widget.productId,
                        basePrice: widget.basePrice,
                        currentStock: widget.currentStock,
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),
                      BottomActionsBar(
                        hasChanges: hasChanges,
                        onSave: _saveChanges,
                        onCancel: () async {
                          final shouldPop = await _confirmDiscard();
                          if (shouldPop && mounted) Navigator.of(context).pop();
                        },
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: hasChanges
            ? FloatingActionButton(
                onPressed: isLoading ? null : _saveChanges,
                backgroundColor: AppTheme.accentGreen,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textPrimary,
                        ),
                      )
                    : const Icon(Icons.save),
              )
            : null,
      ),
    );
  }
}
