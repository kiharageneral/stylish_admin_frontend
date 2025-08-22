import logging
from django.db import transaction
from django.db.models import Sum
from rest_framework import serializers, status
from rest_framework.response import Response
from ecommerce.models import ProductVariant, ProductVariation
from inventory.models import VariantStockLog
from inventory.services import InventoryService
from .base_service import BaseService
from .product_cache_service import ProductCacheService

logger = logging.getLogger(__name__)

class ProductVariantService(BaseService):
    """Service for handling product operations"""
    
    def __init__(self, user = None):
        super().__init__()
        self.user = user
        self.cache_service = ProductCacheService()
        self.inventory_service = InventoryService()
        
        
    def manage_variants(self, product, data, serializer_context = None):
        """Manage variants and variations for a product"""
        
        try:
            self.cache_service.clear_product_cache(product.id)
            
            # Check operation types
            is_stock_distribution = data.get('is_stock_distribution', False)
            is_discount_update = data.get('is_discount_update', False)
            
            
            with transaction.atomic():
                # Process variations if needed
                if 'variations' in data and not is_discount_update and not is_stock_distribution:
                    self._process_variations(product, data['variations'])
                    
                # Process variants if provided
                if 'variants' in data:
                    # Get serializer class for validation
                    from admin_dashboard.product_serializers import ProductUpdateSerializer, ProductVariantSerializer, ProductFullSerializer
                    
                    # Validate variants data
                    serializer = ProductUpdateSerializer(context = serializer_context)
                    validated_variants = serializer.validate_variants(data['variants'])
                    
                    # Process variants based on operation type
                    self._process_variants(product, validated_variants, is_discount_update, is_stock_distribution, serializer_context)
                    
                    self.cache_service.clear_product_cache(product.id)
                    
                    from admin_dashboard.product_serializers import ProductFullSerializer
                    serializer = ProductFullSerializer(product, context= serializer_context)
                    
                    return self.success_response(serializer.data)
                
        except serializers.ValidationError as e:
            self.log_exception(e, "Validation error managing variants")
            return self.error_response(error= 'Validation error', details= e.detail if hasattr(e, 'detail') else str(e))
        
        except Exception as e:
            self.error_response(
                error= 'Server error',
                details= str(e), 
                status_code= status.HTTP_500_INTERNAL_SERVER_ERROR
            )
                    
                    
                    
                    
    # {"color: ["Red", "Blue"], "Size": ["M", "L"]}
    def _process_variations(self, product, variations_data):
        """Process variation types for a product"""
        # convert to standardized format
        if isinstance(variations_data, list):
            variations_dict = {}
            for variation in variations_data:
                if isinstance(variation, dict) and 'name' in variation and 'values' in variation:
                    variations_dict[variation['name']] = variation['values']
        variations_data = variations_dict
        
        
        # Delete variations not in new data
        existing_variations_names = set(product.variation_types.values_list('name', flat = True))
        # [('Color',), ('Size',)] - without flat = True
        #  ['Color', 'Size']
        
        new_variations_names = set(variations_data.keys())
        to_delete = existing_variations_names-new_variations_names
        
        if to_delete:
            product.variation_types.filter(name__in=to_delete).delete()
            
            
        # Update or create variations
        for name, values in variations_data.items():
            ProductVariation.objects.update_or_create(
                product = product, 
                name = name, 
                defaults= {'values': values}
            )
    
    def _process_variants(self, product, validated_variants, is_discount_update, is_stock_distribution, serializer_context):
        """Process variants based on operation type"""
        
        from admin_dashboard.product_serializers import ProductVariantSerializer
        
        # Get existing variants for reference
        existing_variants = {str(v.id): v for v in product.variants.all()}
        
        # Track processed variants and calculate total stock
        processed_ids= set()
        total_stock = 0
        
        # Get current total stock if this is a distribution
        current_inventory = getattr(product, 'inventory', None)
        current_total_stock = current_inventory.current_stock if current_inventory else 0
        
        
        for variant_data in validated_variants:
            variant_id= str(variant_data.get('id')) if variant_data.get('id') else None
            
            # Process existing variant
            if variant_id and variant_id in existing_variants:
                variant = existing_variants[variant_data]
                old_stock = variant.stock
                
                if is_discount_update:
                    self._update_variant_discount(variant, variant_data)
                    
                elif is_stock_distribution:
                    self._update_variant_stock_distribution(variant, variant_data)
                    
                else:
                    self._update_variant_normal(variant, variant_data, serializer_context)
                    
                processed_ids.add(variant_id)
                total_stock += variant.stock
                
                # Log stock changes if needed
                if old_stock != variant.stock:
                    adjustment_type = 'redistribution' if is_stock_distribution else None
                    self._log_variant_stock_change(product, variant, old_stock, adjustment_type = adjustment_type)
            # Create new variant (only in normal mode)
            elif not is_discount_update and not is_stock_distribution:
                new_variant = self._create_new_variant(product, variant_data, serializer_context)
                if new_variant:
                    processed_ids.add(str(new_variant.id))
                    total_stock+= new_variant.stock
                    
                    # Log new variant stock
                    if new_variant.stock > 0:
                        self._log_variant_stock_change(product, new_variant, 0, adjustment_type='addition')
                        
        # Delete variants not included
        if not is_discount_update and not is_stock_distribution:
            variants_to_delete = set(existing_variants.keys()) - processed_ids
            if variants_to_delete:
                for variant_id in variants_to_delete:
                    variant = existing_variants[variant_id]
                    
                    if variant.stock >0:
                        self._log_variant_stock_change(product, variant, variant.stock, deleted = True)
                        
                product.variants.filter(id__in = variants_to_delete).delete()
                
        # Update inventory based on operation type
        if is_stock_distribution:
            self._handle_stock_distribution(product, total_stock, current_total_stock)
        elif not is_discount_update:
            self._update_inventory_from_variants(product, total_stock)
                    
             
    def _create_new_variant(self, product, variant_data, serializer_context):
        """Create a new variant for a product"""
        from admin_dashboard.product_serializers import ProductVariantSerializer
        
        variant_data['product']= product.id 
        serializer = ProductVariantSerializer(
            data = variant_data, 
            context = serializer_context
        )
        
        if serializer.is_valid():
            return serializer.save()
        else:
            raise serializers.ValidationError({
                'new_variant': variant_data, 
                'errors': serializer.errors
            })
    
    def _log_variant_stock_change(self, product, variant, previous_stock, deleted  = False, adjustment_type =  None):
        """Log stock changes for variants"""
        if adjustment_type is None:
            if deleted:
                adjustment_type = 'deletion'
            elif previous_stock < variant.stock:
                adjustment_type = 'addition'
            elif previous_stock > variant.stock:
                adjustment_type = 'reduction'
            else:
                adjustment_type = 'no_change' 
                
                
        # Create log entry
        VariantStockLog.objects.create(
            product = product, 
            variant = variant, 
            previous_stock= previous_stock, 
            current_stock  = variant.stock if not deleted else 0,
            adjustment_type = adjustment_type, 
            notes = f'Variant {"delete" if deleted else "updated"}'
        )       
            
    
    
    
    def _update_variant_discount(self, variant, variant_data):
        """Update only discount price for a variant"""
        if 'discount_price' in variant_data:
            variant.discount_price = variant_data['discount_price']
            variant.save(update_fields = ['discount_price'])
    
    def _update_variant_stock_distribution(self, variant, variant_data):
        """Update stock for a variant during distribution"""
        if 'stock' in variant_data:
            variant.stock = variant_data['stock']
            variant.save(update_fields = ['stock'])
            
            
    def _update_variant_normal(self, variant, variant_data, serializer_context):
        """Normal update for a variant wiht all fields"""
        from admin_dashboard.product_serializers import ProductVariantSerializer
        
        # Make a copy with product ID
        variant_data_copy = {**variant_data, 'product': variant.product.id}
        
        serializer = ProductVariantSerializer(
            variant, 
            data  = variant_data_copy, 
            partial = True, 
            context = serializer_context
        )
        
        if serializer.is_valid():
            serializer.save()
            
        else:
            raise serializers.ValidationError({
                'variant_id': variant.id, 
                'errors': serializer.errors
            })
            
    
    def _handle_stock_distribution(self, product, total_stock, previous_stock):
        """Handle stock distribution across variants"""
        
        inventory = getattr(product, 'inventory', None)
        
        if inventory:
            # Determine if this is a redistribution or a new stock assignment
            is_redistribution = abs(total_stock - previous_stock) <= 0.01
            
            # Log this special operation type
            self.inventory_service.update_inventory_from_variants(product, total_stock, is_sync= True, adjustment_type= 'redistribution' if  is_redistribution else 'stock_update', notes= f'{"Stock redistributed" if is_redistribution else "Stock updated"} across variants (was: {previous_stock}, now: {total_stock})')
        else:
            product.ensure_inventory(total_stock)
            
            from inventory.models import InventoryLog
            InventoryLog.objects.create(
                product = product, 
                previous_stock = 0, 
                current_stock = total_stock, 
                adjustment_type = 'initial_stock', 
                notes = 'Initial stock distribution across variants'
            )
            
    def _update_inventory_from_variants(self, product, total_stock):
        """Update product inventory based on total variant stocks"""
        inventory = getattr(product, 'inventory', None)
        
        if inventory:
            if inventory.current_stock != total_stock:
                self.inventory_service.update_inventory_from_variants(product, total_stock, is_sync= True, adjustment_type='sync')
                
        else:
            product.ensure_inventory(total_stock)