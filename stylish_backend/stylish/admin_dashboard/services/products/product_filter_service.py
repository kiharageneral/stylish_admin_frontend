import json
import logging
from django.db.models import Q, F
from django.core.exceptions import FieldError
from ecommerce.models import Product, Category
from rest_framework.response import Response
from rest_framework import status
from .base_service import BaseService
from .product_cache_service import ProductCacheService

logger = logging.getLogger(__name__)

class ProductFilterService(BaseService):
    """Service for handling product filtering operations"""
    def __init__(self):
        super().__init__()
        self.cache_service = ProductCacheService()
        
    def get_filtered_products(self, query_params):
        """Get filtered products with robust parameter handling"""
        
        # Log incoming parameters for debugging
        logger.debug(f"Filtering parameters: {json.dumps(query_params, default = str)}")
        # Use cache service to get or generate queryset
        return self.cache_service.get_cached_queryset(query_params, lambda: self._build_filtered_queryset(query_params))
    
    def _build_filtered_queryset(self, query_params):
        """Build filtered product queryset based on query parameters"""
        # select appropriate query strategy
        queryset = self._get_base_queryset(query_params)
        
        # Apply filters in sequence
        queryset = self._apply_search_filter(queryset, query_params)
        queryset = self._apply_category_filter(queryset, query_params)
        queryset = self._apply_stock_status_filter(queryset, query_params)
        queryset = self._apply_price_filter(queryset, query_params)
        queryset = self._apply_sorting(queryset, query_params)
        
        logger.debug(f"Final result count : {queryset.count()}")
        return queryset
    
    def _get_base_queryset(self, query_params):
        """Get base queryset with appropriate selects and prefetches"""
        if query_params.get('loadBasicInfo')=='true':
            return Product.objects.only('id', 'name', 'price', 'discount_price', 'is_active', 'category__name', 'category__id', 'created_at').select_related('category')
        else:
            return Product.objects.select_related('category', 'inventory').prefetch_related('images', 'variants', 'variation_types')
        
    def _apply_search_filter(self, queryset, query_params):
        """Apply search filter to queryset"""
        search = query_params.get('search', '')
        if search:
            queryset = queryset.filter(Q(name__icontains=search) | Q(description__icontains= search) | Q(category__name__icontains = search))
            logger.debug(f"Applied search filter: '{search}', results {queryset.count()}")
            
        return queryset
    
    def _apply_category_filter(self, queryset, query_params):
        """Apply category filter with multiple strategies"""
        category_id = query_params.get('category_id')
        if category_id:
            try:
                # Strategy 1: Direct UUID matching (case insensitive)
                queryset = queryset.filter(category__id__iexact = category_id)
                
                # Strategy 2: String-based exact matching if no results
                if not queryset.exists():
                    queryset = queryset.filter(category__id = str(category_id))
                
                # Strategy 3: Perform additonal validation
                category_exists = Category.objects.filter(id = category_id).exists()
                if not category_exists:
                    queryset = queryset.none()
                    
                logger.debug(f"Applied category filter: {category_id}, results: {queryset.count()}")
                
            except Exception as e:
                logger.error(f"Category Filtering Error: {e}")
                queryset = queryset.none()
                
        return queryset
    
    def _apply_stock_status_filter(self, queryset, query_params):
        """Apply stock status filter with robust enum handling """
        stock_status = query_params.get('stock_status')
        
        if stock_status:
            if stock_status.startswith('StockStatus.'):
                stock_status = stock_status.split('.')[-1].lower()
                
            stock_status = stock_status.lower()
            
            if stock_status == 'outofstock':
                queryset = queryset.filter(inventory__current_stock__lte=0)
            elif stock_status == 'lowstock':
                queryset = queryset.filter(inventory__current_stock__gt = 0, inventory__current_stock_lte = F('inventory__low_stock_threshold'))
            elif stock_status == 'instock':
                queryset = queryset.filter(inventory__current_stock__gt = 0)
                
            logger.debug(f"Applied stock status filter: {stock_status}, results : {queryset.count()}")
        return queryset
    
    def _apply_price_filter(self, queryset, query_params):
        """Apply price range filter with robust error handling"""
        try:
            min_price = float(query_params.get('min_price', 0) or 0)
            max_price_param = query_params.get('max_price')
            
            if max_price_param and max_price_param.lower() != 'inf':
                max_price = float(max_price_param)
                queryset = queryset.filter(price__gte = min_price, price__lte = max_price)
            else:
                queryset = queryset.filter(price__gte = min_price)
                
            logger.debug(f"Applied price filters : min = {min_price}, max = {max_price_param}")
            
        except (ValueError, TypeError) as e :
            logger.error(f"price filtering error: {e}")
        return queryset
    
    def _apply_sorting(self, queryset, query_params):
        """Apply sorting with fallback"""
        sort_by = query_params.get('sort_by', '-created_at')
        try:
            queryset = queryset.order_by(sort_by)
        except FieldError:
            logger.warning(f"Invalid sort field: {sort_by}, using default")
            queryset = queryset.order_by('-created_at')
            
        return queryset
    def get_filter_options(self):
        """Get available filter options for products"""
        categories = Category.objects.filter(is_active = True).values('id', 'name')
        return self.success_response({
            'categories': list(categories), 
            'status_options': ['active', 'inactive'], 
            'stock_status_options': ['in_stock', 'out_of_stock', 'low_stock']
        })
    