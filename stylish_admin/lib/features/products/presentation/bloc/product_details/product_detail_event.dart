part of 'product_details_bloc.dart';

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();
  @override  
  List<Object?> get props => [];
}

class GetProductByIdEvent extends ProductDetailEvent{
  final String id;

  const GetProductByIdEvent(this.id);
  
  @override  
  List<Object?> get props => [id];
}

class CreateProductEvent extends ProductDetailEvent{
  final ProductEntity product;
  final List<dynamic>? images;

  const CreateProductEvent({required this.product,  this.images});

  @override  
  List<Object?> get props => [product, images];
}

class UpdateProductEvent extends ProductDetailEvent{
  final String id;
  final ProductEntity product;
  final List<dynamic>? newImages;

  const UpdateProductEvent({required this.id, required this.product,  this.newImages});

  @override  
  List<Object?> get props => [id, product, newImages];
  
}

class DeleteProductEvent extends ProductDetailEvent{
  final String productId;

  const DeleteProductEvent({required this.productId});

  @override  
  List<Object?> get props => [productId];
}

class ToggleProductStatusEvent extends ProductDetailEvent {
  final String id;

  const ToggleProductStatusEvent(this.id);

  @override  
  List<Object?> get props => [id];
}

class UpdateProductStockEvent extends ProductDetailEvent {
  final String id;
  final int newStock;
  final String? reason;

  const UpdateProductStockEvent({required this.id, required this.newStock,  this.reason});
  @override  
  List<Object?> get props => [id, newStock, reason];
}

class UpdateProductPriceEvent extends ProductDetailEvent {
  final String id;
  final double price;
  final double? discountPrice;

  const UpdateProductPriceEvent({required this.id, required this.price,  this.discountPrice});

  @override  
  List<Object?> get props => [id, price, discountPrice];
}

class UpdateProductProfitMarginEvent extends ProductDetailEvent {
  final String id;
  final double cost;
  final double price;
  final double? discountPrice;
  final double profitMargin;

  const UpdateProductProfitMarginEvent({required this.id, required this.cost, required this.price,  this.discountPrice, required this.profitMargin});

  @override  
  List<Object?> get props => [id, cost, price, discountPrice, profitMargin];
}

class ManageProductImagesEvent extends ProductDetailEvent{
  final String id;
  final List<dynamic> images;
  final List<bool> isPrimaryList;

  const ManageProductImagesEvent({required this.id, required this.images, required this.isPrimaryList});

  @override  
  List<Object?> get props => [id, images, isPrimaryList];
}

class DeleteProductImageEvent extends ProductDetailEvent {
  final String productId;
  final String imageId;

  const DeleteProductImageEvent({required this.productId, required this.imageId});

  @override  
  List<Object?> get props => [productId, imageId];
}

class ClearProductDetailErrorEvent extends ProductDetailEvent{}

class ClearProductDetailOperationSuccessEvent extends ProductDetailEvent{}

class ResetProductDetailStateEvent extends ProductDetailEvent{}