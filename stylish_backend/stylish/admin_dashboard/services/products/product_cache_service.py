import time
import logging
from django.core.cache import cache
from admin_dashboard.core.cache_util import CacheUtil
from .base_service import BaseService

logger = logging.getLogger(__name__)

class ProductCacheService(BaseService):
    """Service for handling product caching operations"""
    def __init__(self):
        super().__init__()
        self.cache_util  = CacheUtil(model_name='product')
        
    def get_cached_queryset(self, query_params, queryset_generator):
        """Get cached queryset or generate and cache it"""
        bypass_cache = query_params.get('bypass_cache') == 'true'
        
        # Generate cache key and register it
        cache_key = self.cache_util.get_cache_key(query_params)
        self.cache_util.register_key(cache_key)
        
        # Return from cache if available and not bypassed
        queryset = None if bypass_cache else self.cache_util.get_from_cache(cache_key)
        if queryset is None:
            # Generate queryset using the provided function
            queryset= queryset_generator()
            
            if not bypass_cache:
                self.cache_util.set_in_cache(cache_key, queryset)
                
        return queryset
    
    def clear_single_product_cache(self, product_id):
        """Clear cache for a single product"""
        logger.debug(f"Clearing single product cache for product_id = {product_id}")
        self.cache_util.clear_item_cache(product_id)
        self._clear_product_variant_caches(product_id)
        
        product_detail_key = f"product_{product_id}_detail"
        cache.delete(product_detail_key)
        
    def clear_product_cache(self, product_id = None):
        """Cache clearing with Redis"""
        logger.debug(f"Clearing product cache for product_id = {product_id}")
        if product_id:
            self.clear_single_product_cache(product_id)
        
        # clear general product caches
        self.clear_general_product_cache()
        
        # clear related model caches that might be affected
        self._clear_related_model_caches()
        
        # Update cache invalidation timestamp
        cache.set('Product_cache_last_cleared', time.time(), timeout= 86400)
        
    def _clear_related_model_caches(self):
        """Clear caches of related models that might be affected"""
        # clear category cahce as products affect category listings
        category_cache = CacheUtil(model_name='category')
        category_cache.clear_cache()
        
        # clear inventory-related caches
        inventory_cache = CacheUtil(model_name= 'inventory')
        inventory_cache.clear_cache()
      
    def clear_general_product_cache(self):
        """Clear general product listing caches"""
        self.cache_util.clear_cache()
        common_patterns = [
            {'loadBasiInfo': 'true'}, 
            {'status': 'active'}, 
            {'status': 'inactive'}, 
            {}, 
        ]
        for pattern in common_patterns:
            cache_key = self.cache_util.get_cache_key(pattern)
            cache.delete(cache_key)
            
        category_cache = CacheUtil(model_name='category')
        category_cache.clear_cache()
        
    
    def _clear_product_variant_caches(self, product_id):
        """Clear all variant-related caches for a product"""
        if hasattr(cache, '_cache') and hasattr(cache._cache, 'get_client'):
            try:
                redis_client = cache._cache.get_client()
                patterns = [
                    f"*product_{product_id}_variant*", 
                    f"*variant_product_{product_id}*", 
                    f"product_variants_{product_id}*"
                ]
                for pattern in patterns:
                    cursor = 0
                    while True:
                        cursor , keys = redis_client.scan(cursor= cursor, match = pattern, count = 50)
                        if keys:
                            redis_client.delete(*keys)
                        if cursor == 0:
                            break
                return 
            except Exception:
                pass
            
        # Fallback to specific key deletion
        variant_keys = [
            f"product_{product_id}_variants",
            f"product_{product_id}_with_variants", 
            f"product_variant_{product_id}", 
            f"variant_stock_{product_id}", 
            f"product_{product_id}_variant_list"
        ]
        cache.delete_many(variant_keys)
    