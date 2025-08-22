import 'package:equatable/equatable.dart';
import 'package:stylish_admin/features/flash_sales/domain/entities/flash_sale_item.dart';

class FlashSale extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final int discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<FlashSaleItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalRevenue;
  final double revenueIncrease;
  final int totalOrders;
  final double orderIncrease;
  final int unitsSold;
  final double unitsSoldIncrease;
  final double conversionRate;
  final double conversionRateIncrease;
  final int? purchaseLimit;
  final double? minimumOrderValue;
  final bool isPublic;
  final bool allowStackingDiscounts;
  final String timeRemainingStr;
  final bool isOngoing;
  final double averageOrderValue;

  const FlashSale({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.totalRevenue = 0.0,
    this.revenueIncrease = 0.0,
    this.totalOrders = 0,
    this.orderIncrease = 0.0,
    this.unitsSold = 0,
    this.unitsSoldIncrease = 0.0,
    this.conversionRate = 0.0,
    this.conversionRateIncrease = 0.0,
    this.purchaseLimit,
    this.minimumOrderValue,
    this.isPublic = true,
    this.allowStackingDiscounts = false,
    this.timeRemainingStr = '',
    this.isOngoing = false,
    this.averageOrderValue = 0.0,
  });

  FlashSale copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    int? discountPercentage,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    List<FlashSaleItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalRevenue,
    double? revenueIncrease,
    int? totalOrders,
    double? orderIncrease,
    int? unitsSold,
    double? unitsSoldIncrease,
    double? conversionRate,
    double? conversionRateIncrease,
    int? purchaseLimit,
    double? minimumOrderValue,
    bool? isPublic,
    bool? allowStackingDiscounts,
    double? averageOrderValue,
    String? timeRemainingStr,
    bool? isOngoing,
  }) {
    return FlashSale(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      revenueIncrease: revenueIncrease ?? this.revenueIncrease,
      totalOrders: totalOrders ?? this.totalOrders,
      orderIncrease: orderIncrease ?? this.orderIncrease,
      unitsSold: unitsSold ?? this.unitsSold,
      unitsSoldIncrease: unitsSoldIncrease ?? this.unitsSoldIncrease,
      conversionRate: conversionRate ?? this.conversionRate,
      conversionRateIncrease:
          conversionRateIncrease ?? this.conversionRateIncrease,
      purchaseLimit: purchaseLimit ?? this.purchaseLimit,
      minimumOrderValue: minimumOrderValue ?? this.minimumOrderValue,
      isPublic: isPublic ?? this.isPublic,
      allowStackingDiscounts:
          allowStackingDiscounts ?? this.allowStackingDiscounts,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      timeRemainingStr: timeRemainingStr ?? this.timeRemainingStr,
      isOngoing: isOngoing ?? this.isOngoing,
    );
  }

  bool get isCurrentlyOngoing {
    final now = DateTime.now();
    return isActive && startDate.isBefore(now) && endDate.isAfter(now);
  }

  Duration? get timeRemaining {
    if (!isCurrentlyOngoing) return null;
    return endDate.difference(DateTime.now());
  }

  String get status {
    final now = DateTime.now();
    if (!isActive) return 'inactive';
    if (startDate.isAfter(now)) return 'upcoming';
    if (endDate.isBefore(now) || endDate.isAtSameMomentAs(now)) {
      return 'expired';
    }
    return 'active';
  }

  int get totalProducts => items.length;

  int get totalUnitsSold => items.fold(0, (sum, item) => sum + item.unitsSold);

  double get calculatedAverageOrderValue =>
      totalOrders > 0 ? totalRevenue / totalOrders : 0;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    discountPercentage,
    startDate,
    endDate,
    isActive,
    items,
    createdAt,
    updatedAt,
    revenueIncrease,
    totalOrders,
    orderIncrease,
    unitsSold,
    unitsSoldIncrease,
    conversionRate,
    conversionRateIncrease,
    purchaseLimit,
    minimumOrderValue,
    isPublic,
    allowStackingDiscounts,
    averageOrderValue,
    timeRemainingStr,
    isOngoing,
  ];
}
