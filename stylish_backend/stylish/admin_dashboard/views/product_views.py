from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.forms import ValidationError
from django.db import transaction
import time
import logging
from admin_dashboard.pagination import CustomResultsSetPagination

from ecommerce.models import Product
from  inventory.services import InventoryService
from admin_dashboard.services.products.product_service import ProductService
from admin_dashboard.services.image_service import ImageService
from admin_dashboard.core.cache_util import CacheUtil
from admin_dashboard.product_serializers import (ProductCreateSerializer, ProductDetailSerializer, ProductFullSerializer, ProductListSerializer, ProductImageSerializer, ProductVariantSerializer, ProductUpdateSerializer)

logger = logging.getLogger(__name__)

class AdminProductViewSet(viewsets.ModelViewSet):
    """ViewSet for managin products in the admin dashboard"""
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    permission_classes = [IsAdminUser]
    pagination_class = CustomResultsSetPagination
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.inventory_service = InventoryService()
        self.product_service = ProductService()
        self.image_service = ImageService()
        
        self.cache_util = CacheUtil(model_name = 'product')
        
    def get_serializer_context(self):
        """Add request to serializer context"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
    
    def get_queryset(self):
        return self.product_service.get_filtered_products(self.request.query_params)
    
    
    def get_serializer_class(self):
        """Return the appropriate serializer class based on the action"""
        if self.action == 'create':
            return ProductCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return ProductUpdateSerializer
        elif self.action == 'list':
            return ProductListSerializer
        elif self.action == 'retrieve':
            return ProductFullSerializer
        return super().get_serializer_class()
    
    def create(self, request, *args, **kwargs):
        try:
            data = request.data.copy()
            
            if 'stock' in data and not data.get('initial_stock'):
                data['initial_stock'] = data['stock']
                
            # Create product with serializer
            serializer = self.get_serializer(data = data)
            serializer.is_valid(raise_exception = True)
            
            with transaction.atomic():
                product = serializer.save()
                
                
                # Process images if provided in request
                image_files = self.image_service.extract_files_from_request(request)
                if image_files:
                    created_images = self.image_service.process_images(product, image_files)
                else:
                    logger.warning('No image files found in request')
                    
            # Clear all product caches
            self.product_service.clear_product_cache()
            self._clear_related_caches(product.id)
            
            product=Product.objects.get(id = product.id)
            return Response(
                ProductFullSerializer(product, context = self.get_serializer_context()).data,
                status= status.HTTP_201_CREATED
            )
            
        except ValidationError as e:
            return Response({
                'error': 'Validation error', 
                'details': str(e)
            }, status= status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            import traceback
            logger.error(f"Error creating product: {str(e)}")
            logger.debug(traceback.format_exc())
            return Response({
                'error': 'Server error', 
                'details': str(e)
            }, status= status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()    
        
        try:
            # first clear all product caches immediately
            self.product_service.clear_product_cache(instance.id)
            
            data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
            
            if 'stock' in data and not data.get('initial_stock'):
                data['initial_stock'] = data['stock']
                
                
            # Update product
            serializer = self.get_serializer(instance, data = data, partial = partial)
            serializer.is_valid(raise_exception = True)
            
            with transaction.atomic():
                product = serializer.save()
                
                image_files = self.image_service.extract_files_from_request(request)
                if image_files:
                    created_images = self.image_service.process_images(product, image_files)
                    logger.info(f"Updated with {len(created_images)} images for produt {product.id}")
                else:
                    logger.info("No image files found in update request")
                    
            self.product_service.clear_product_cache(product.id)
            self._clear_related_caches(product.id)
            
            return Response(ProductFullSerializer(product, context = self.get_serializer_context()).data)
        
        except ValidationError as e:
            return Response({
                'error': 'Validation error', 
                'details': str(e)
            }, status= status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            import traceback
            logger.error(f"Error updating product: {str(e)}")
            logger.error(traceback.format_exc())
            return Response({
                'error': 'Server error', 
                'details': str(e)
            }, status= status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    def _clear_related_caches(self, product_id):
        """Clear all caches related to a product update"""
        from django.core.cache import cache
        
        filter_patterns = [
            'product_*_query_*', 
            'category_*_products_*', 
            'inventory_*', 
            'product_stats_*'
        ]
        
        if hasattr(cache, '_cache') and hasattr(cache._cache, 'get_client'): 
            try:
                redis_client = cache._cache.get_client()
                for pattern in filter_patterns:
                    cursor = 0
                    while True:
                        cursor, keys = redis_client.scan(cursor= cursor, match = pattern, count = 100)
                        if keys:
                            redis_client.delete(*keys)
                            
                        if cursor == 0:
                            break
                        
            except Exception:
                common_keys = [
                    'product_filters', 'category_list', 'inventory_summary', f'produt_{product_id}_related', f'produt_{product_id}_stats'
                ]
                
                cache.delete_many(common_keys)
                
        cache.set('cache_invalidated_at', time.time(), timeout = 3600)
        
        
    def destroy(self, request, *args, **kwargs):
        """Override destroy to clear cache before and after deletion"""
        instance = self.get_object()
        instance_id = instance.id 
        
        category_id = instance.category_id if instance.category else None
        
        self.product_service.clear_product_cache(instance_id)
        
        # Perform the deletion
        response = super().destroy(request, *args, **kwargs)
        
        self.product_service.clear_product_cache()
        
        if category_id:
            category_cache = CacheUtil(model_name= 'category')
            category_cache.clear_item_cache(category_id)
            category_cache.clear_cache()
            
        return response
    
    @action(detail= False, methods=['post'])
    @transaction.atomic
    def bulk_delete(self, request):
        """Bulk delete products"""
        self.product_service.request = request
        response = self.product_service.bulk_delete_products()
        self.product_service.clear_product_cache()
        return response
    
    
    @action(detail= True, methods= ['post'])
    def stock_adjustment(self, request, pk = None):
        """Adjust product stock with reason"""
        product = self.get_object()
        self.product_service.request = request
        return self.product_service.adjust_stock(product.id)
    
    @action(detail= False, methods= ['get'])
    def filters(self, request):
        """Get available filter options"""
        return self.product_service.get_filter_options()
    
    @action(detail = True, methods= ['post'])
    def manage_images(self, request, pk = None):
        """Add or update product images using the image service"""
        return self.image_service.manage_product_images(pk, request)
    
    @action(detail = True, methods= ['delete'])
    def delete_image(self, request, pk = None):
        """Delete a product image"""
        product = self.get_object()
        image_id = request.data.get('image_id')
        if not image_id:
            return Response({
                'error': 'image_id is required', 
                
            }, status= status.HTTP_400_BAD_REQUEST)
        return self.image_service.delete_product_image(product.id, image_id)
    
    @action(detail = True, methods= ['get'])
    def variants(self, request, pk = None):
        """Get all variants for a product"""
        product = self.get_object()
        variants = product.variants.all()
        serializer = ProductVariantSerializer(variants, many = True)
        return Response(serializer.data)
    
    
    @action(detail = True, methods= ['post'])
    def manage_variants(self, request, pk = None):
        """Manage variants for a product"""
        product = self.get_object()
        self.product_service.request = request
        return self.product_service.manage_product_variants(product, request.data)
    
    @action(detail = True, methods= ['post'])
    def distribute_stock(self, request, pk = None):
        """Endpoint to redistribute existing stock across variants
        This doesn't change the total inventory, only how it's distributed
        """
        product = self.get_object()
        data = request.data.copy()
        
        # Determine if this is a stock distribution or new stock assignment
        user_existing_stock = data.get('use_existing_stock', True)
        
        # Mark this as a stock distribution operation
        data['is_stock_distribution'] = user_existing_stock
        
        
        if 'variants' not in data or not data['variants']:
            return Response({
                'error': 'No variants provided for stock distribution'
            }, status = status.HTTP_400_BAD_REQUEST)
            
        if user_existing_stock:
            current_inventory = getattr(product, 'inventory', None)
            current_total = current_inventory.current_stock if current_inventory else 0
            requested_total = sum(variant.get('stock', 0) for variant in data['variants'])
            
            if abs(current_total - requested_total) > 0.01:
                return Response({
                    'error': f"Total distributed stock ({requested_total}) must match current inventory ({current_total}) when using existing stock", 
                    'detail': 'Set use_existing_stock = false to override this validation'
                }, status = status.HTTP_400_BAD_REQUEST)
                
        self.product_service.request  = request
        return self.product_service.manage_product_variants(product, data)