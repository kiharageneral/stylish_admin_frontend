import 'package:equatable/equatable.dart';
import 'package:stylish_admin/features/flash_sales/domain/entities/flash_sale_product.dart';

class FlashSaleItem extends Equatable {
  final String id;
  final FlashProduct product;
  final int? overrideDiscount;
  final int effectiveDiscount;
  final int? stockLimit;
  final int unitsSold;
  final int? itemPurchaseLimit;
  final int? effectivePurchaseLimit;
  final double revenue;
  final int? remainingStock;

  const FlashSaleItem({
    required this.id,
    required this.product,
    this.overrideDiscount,
    required this.effectiveDiscount,
    this.stockLimit,
    required this.unitsSold,
    this.itemPurchaseLimit,
    this.effectivePurchaseLimit,
    this.revenue = 0.0,
    this.remainingStock,
  });

  FlashSaleItem copyWith({
    String? id,
    FlashProduct? product,
    int? overrideDiscount,
    int? effectiveDiscount,
    int? stockLimit,
    int? unitsSold,
    int? itemPurchaseLimit,
    int? effectivePurchaseLimit,
    double? revenue,
    int? remainingStock,
  }) {
    return FlashSaleItem(
      id: id ?? this.id,
      product: product ?? this.product,
      effectiveDiscount: effectiveDiscount ?? this.effectiveDiscount,
      unitsSold: unitsSold ?? this.unitsSold,
      stockLimit: stockLimit ?? this.stockLimit,
      itemPurchaseLimit: itemPurchaseLimit ?? this.itemPurchaseLimit,
      revenue: revenue ?? this.revenue,
      remainingStock: remainingStock ?? this.remainingStock,
      overrideDiscount: overrideDiscount ?? this.overrideDiscount,
      effectivePurchaseLimit:
          effectivePurchaseLimit ?? this.effectivePurchaseLimit,
    );
  }

  bool get isStockLimited => stockLimit != null;
  bool get isPurchaseLimited =>
      itemPurchaseLimit != null || effectivePurchaseLimit != null;

  double get discountedPrice {
    return product.price * (1 - effectiveDiscount / 100);
  }

  double get averageRevenue {
    return unitsSold > 0 ? revenue / unitsSold : 0;
  }

  @override
  List<Object?> get props => [
    id,
    product,
    overrideDiscount,
    effectiveDiscount,
    stockLimit,
    unitsSold,
    itemPurchaseLimit,
    effectivePurchaseLimit,
    revenue,
    remainingStock,
  ];
}
