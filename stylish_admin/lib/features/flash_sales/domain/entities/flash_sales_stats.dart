import 'package:equatable/equatable.dart';

class TopSellingProduct extends Equatable {
  final String productId;
  final String productName;
  final int unitsSold;
  final int effectiveDiscount;
  final double revenue;
  final double conversionRate;

  const TopSellingProduct({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.effectiveDiscount,
    this.revenue = 0.0,
    this.conversionRate = 0.0,
  });

  TopSellingProduct copyWith({
    String? productId,
    String? productName,
    int? unitsSold,
    int? effectiveDiscount,
    double? revenue,
    double? conversionRate,
  }) {
    return TopSellingProduct(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitsSold: unitsSold ?? this.unitsSold,
      effectiveDiscount: effectiveDiscount ?? this.effectiveDiscount,
      revenue: revenue ?? this.revenue,
      conversionRate: conversionRate ?? this.conversionRate,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    unitsSold,
    effectiveDiscount,
    revenue,
    conversionRate,
  ];
}

class FlashSaleStats extends Equatable {
  final int totalFlashSales;
  final int activeFlashSales;
  final int upcomingFlashSales;
  final int expiredFlashSales;
  final String? title;
  final int? totalProducts;
  final int? totalUnitsSold;
  final int? averageDiscount;
  final bool? isActive;
  final bool? isOngoing;
  final Duration? timeRemaining;
  final List<TopSellingProduct>? topSellingProducts;
  final double? totalRevenue;
  final int? totalOrders;
  final double? revenueIncrease;
  final double? conversionRate;
  final double? conversionRateIncrease;
  final double? averageOrderValue;
  final int? publicFlashSales;
  final int? restrictedFlashSales;
  final double? orderIncrease;
  final double? unitsSoldIncrease;

  const FlashSaleStats({
    required this.totalFlashSales,
    required this.activeFlashSales,
    required this.upcomingFlashSales,
    required this.expiredFlashSales,
    this.isOngoing,
    this.title,
    this.totalProducts,
    this.totalUnitsSold,
    this.averageDiscount,
    this.isActive,
    this.timeRemaining,
    this.topSellingProducts,
    this.totalRevenue,
    this.revenueIncrease,
    this.conversionRate,
    this.conversionRateIncrease,
    this.averageOrderValue,
    this.publicFlashSales,
    this.restrictedFlashSales,
    this.totalOrders,
    this.orderIncrease,
    this.unitsSoldIncrease,
  });

  FlashSaleStats copyWith({
    int? totalFlashSales,
    int? activeFlashSales,
    int? upcomingFlashSales,
    int? expiredFlashSales,
    String? title,
    int? totalProducts,
    int? totalUnitsSold,
    int? averageDiscount,
    bool? isActive,
    bool? isOngoing,
    Duration? timeRemaining,
    List<TopSellingProduct>? topSellingProducts,
    double? totalRevenue,
    double? revenueIncrease,
    int? totalOrders,
    double? orderIncrease,
    double? unitsSoldIncrease,
    double? conversionRate,
    double? conversionRateIncrease,
    double? averageOrderValue,
    int? publicFlashSales,
    int? restrictedFlashSales,
  }) {
    return FlashSaleStats(
      totalFlashSales: totalFlashSales ?? this.totalFlashSales,
      activeFlashSales: activeFlashSales ?? this.activeFlashSales,
      upcomingFlashSales: upcomingFlashSales ?? this.upcomingFlashSales,
      expiredFlashSales: expiredFlashSales ?? this.expiredFlashSales,
      title: title ?? this.title,
      totalProducts: totalProducts ?? this.totalProducts,
      totalUnitsSold: totalUnitsSold ?? this.totalUnitsSold,
      averageDiscount: averageDiscount ?? this.averageDiscount,
      isActive: isActive ?? this.isActive,
      isOngoing: isOngoing ?? this.isOngoing,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      topSellingProducts: topSellingProducts ?? this.topSellingProducts,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      revenueIncrease: revenueIncrease ?? this.revenueIncrease,
      totalOrders: totalOrders ?? this.totalOrders,
      orderIncrease: orderIncrease ?? this.orderIncrease,
      unitsSoldIncrease: unitsSoldIncrease ?? this.unitsSoldIncrease,
      conversionRate: conversionRate ?? this.conversionRate,
      conversionRateIncrease:
          conversionRateIncrease ?? this.conversionRateIncrease,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      publicFlashSales: publicFlashSales ?? this.publicFlashSales,
      restrictedFlashSales: restrictedFlashSales ?? this.restrictedFlashSales,
    );
  }

  @override
  List<Object?> get props => [
    totalFlashSales,
    activeFlashSales,
    upcomingFlashSales,
    expiredFlashSales,
    title,
    totalProducts,
    totalUnitsSold,
    averageDiscount,
    isActive,
    isOngoing,
    timeRemaining,
    topSellingProducts,
    totalRevenue,
    revenueIncrease,
    totalOrders,
    orderIncrease,
    unitsSoldIncrease,
    conversionRate,
    conversionRateIncrease,
    averageOrderValue,
    publicFlashSales,
    restrictedFlashSales,
  ];
}
