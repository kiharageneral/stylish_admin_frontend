import logging
from django.db import transaction
from rest_framework import status
from rest_framework.exceptions import ValidationError
from ecommerce.models import Product
from inventory.models import InventoryRecord
from inventory.services import InventoryService
from admin_dashboard.product_serializers import (ProductFullSerializer, ProductUpdateSerializer, ProductVariantSerializer)
from .base_service import BaseService
from .product_cache_service import ProductCacheService
from .product_filter_service import ProductFilterService
from .product_variant_service import ProductVariantService

logger = logging.getLogger(__name__)

class ProductService(BaseService):
    """Main service for product operations"""
    def __init__(self,request = None):
        super().__init__()
        self.request = request
        self.user = request.user if request else None
        
        # Initialize dependent serives
        self.cache_service = ProductCacheService()
        self.filter_service = ProductFilterService()
        self.inventory_service = InventoryService()
        self.variant_service = ProductVariantService()
        
        # For tracking current product ID in operations
        self.current_product_id = None
        
    def get_filtered_products(self, query_params):
        """Get filtered products using filter service"""
        return self.filter_service.get_filtered_products(query_params)
    def get_filter_options(self):
        """Get filter options using filter service"""
        return self.filter_service.get_filter_options()
    def clear_product_cache(self, product_id = None):
        """Clear product cache using cache service"""
        self.cache_service.clear_product_cache(product_id)
        
    def bulk_delete_products(self):
        """Bulk delete products"""
        product_ids = self.request.data.get('product_ids', [])
        if not product_ids:
            return self.error_response(error = 'No product IDs provided')
        
        try:
            with transaction.atomic():
                # Clear individual caches first
                for product_id in product_ids:
                    self.cache_service.clear_single_product_cache(product_id)
                    
                    
                # First delete associated inventory records to avoid foreign key issues
                InventoryRecord.objects.filter(product__id__in = product_ids).delete()
                deleted_count = Product.objects.filter(id__in=product_ids).delete()[0]
                
                # clear all product and category caches to ensure consistency
                self.cache_service.clear_general_product_cache()
                
                return self.success_response({
                    'message': f'Successfully deleted {deleted_count} products', 
                    'deleted_count': deleted_count
                })
        except Exception as e:
            self.log_exception(e, "Failed to delete products")
            return self.error_response(
                error='Failed to delete products',
                details = str(e)
            )
            
            
    def adjust_stock(self, product_id):
        """Adjust stock for a product"""
        try:
            product = self.get_object(product_id)
            inventory = getattr(product, 'inventory', None)
            
            if not inventory:
                # Create inventory record if it doesn't exist
                inventory = self._initialize_inventory(product)
                
                return self.success_response({
                    'message': 'Inventory record created successfully', 
                    'inventory_id': str(inventory.id), 
                    'current_stock': inventory.current_stock, 
                    'initial_stock': inventory.initial_stock
                })
              
            # Adjust existing inventory stock
            result = self.inventory_service.adjust_stock(inventory.id, self.request.data, self.user)
            
            if result.get('success', False):
                # Clear cache
                self.cache_service.clear_single_product_cache(product.id)
                return self.success_response(data = result)
            
            return self.error_response(
                error = result.get('error', 'Failed to adjust stock')
            )
        except Exception as e:
            self.log_exception(e, f"Failed to adjust stock for product {product_id}")
            return self.error_response(
                error= str(e), 
                status_code= status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
    
    def _initialize_inventory(self, product):
        """Initialize inventory for a product"""
        initial_stock = self.request.data.get('initial_stock', 0)
        quantity = self.request.data.get('quantity', 0)
        
        try:
            quantity = int(quantity)
            initial_stock = int(initial_stock)
        except ValueError:
            raise ValidationError('Invalid quantity or initial stock value')
        
        # Create inventory record using service
        inventory , _ = self.inventory_service.initialize_inventory(product, initial_stock= initial_stock or quantity)
        
        return inventory
    
    def manage_product_variants(self, product, variant_data):
        """manage variants and variations for a product"""
        try:
            # Get the serializer context to pass down to the next service
            serializer_context = self.get_serializer_context()
            
            
            # Delegate to variant service, passing the context
            result = self.variant_service.manage_variants(
                product, 
                variant_data, 
                serializer_context= serializer_context
            )
            
            self.cache_service.clear_single_product_cache(product.id)
            
            if isinstance(result, dict) and result.get('error'):
                return self.error_response(**result)
            
            return result
        
        except Exception as e:
            product_id_for_logging = getattr(product, 'id', 'unknown')
            
            self.log_exception(e, f"Failed to manage variants for product {product_id_for_logging}")
            
            return self.error_response(
                error = str(e), 
                status_code= status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            
            
            
    def get_object(self, product_id = None):
        """Get product instance by ID"""
        if not product_id and hasattr(self, 'current_product_id'):
            product_id = self.current_product_id
            
        if not product_id:
            raise ValidationError("Product ID is required")
        
        try:
            return Product.objects.get(id = product_id)
        except Product.DoesNotExist:
            raise ValidationError(f"product with ID {product_id} not found")
        
    def get_serializer_context(self):
        """Return context for serializers"""
        return {'request': self.request}
        
    