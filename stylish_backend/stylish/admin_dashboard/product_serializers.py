from rest_framework import serializers
import uuid
import base64
from django.core.files.base import ContentFile
from django.utils.text import slugify

from ecommerce.models import (Product, Category, ProductImage, ProductVariant, ProductVariation, Order, OrderItem)
from inventory.models import InventoryRecord

class ProductImageSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductImage
        fields = [
            'id', 'product', 'image', 'image_url', 'alt_text', 'order', 'is_primary', 'created_at'
        ]
        extra_kwargs = {
            'product': {'required': False}, 
            'image': {'required': False}, 
            'created_at': {'read_only': True}
        }
        
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url 
        return None
    
    def validate(self, data):
        return data
   
   
class ProductVariantSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductVariant
        fields = [
            'id', 'product', 'attributes', 'sku', 'price', 'discount_price', 'stock', 'image', 'image_url', 'created_at', 'updated_at'
        ]
        extra_kwargs = {
            'product': {'required': False}, 
            'created_at': {'read_only': True}, 
            'updated_at': {'read_only': True}, 
            
            'image': {'required': False, 'write_only': True}
        }
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.urls)
            return obj.image.url 
        return None
    
    def save(self, **kwargs):
        instance = super().save(**kwargs)
        # Clear related product cache upon variant save
        return instance
    def validate(self, data):
        if 'price' in data and data['price'] is not None:
            product = data.get('product') or self.instance.product if self.instance else None
            if product and data['price'] > product.price and not getattr(product, 'allow_price_increase', False):
                raise serializers.ValidationError({"price": "Variant price cannot exceed base product price unless explicitly allowed"})
            
        if 'discount_price' in data and data['discount_price'] is not None:
            price = data.get('price')
            if price and data['discount_price'] >= price:
                raise serializers.ValidationError({"discount_price": "Discount price must be lower than regular price"})
            
        request = self.context.get('request')
        if request and request.data.get('is_stock_distribution'):
            return data
        return data
    
class ProductVariationSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductVariation
        fields = [
            'id', 'name', 'values', 'created_at', 'updated_at'
        ]
        extra_kwargs = {
            'created_at': {'read_only': True}, 
            'updated_at': {'read_only': True}, 
            
        }
        
         
class ProductListSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source = 'category.name', read_only = True)
    primary_image_url = serializers.SerializerMethodField()
    stock_status = serializers.SerializerMethodField()
    stock = serializers.IntegerField(read_only = True)
    def get_stock_status(self, obj):
        inventory  = getattr(obj, 'inventory', None)
        return inventory.stock_status if inventory else 'unknown'
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'category', 'category_name', 'price', 'stock', 'discount_price', 'display_price', 'rating', 'primary_image_url', 'stock_status', 'is_active'
        ]
        
    def get_primary_image_url(self, obj):
        request = self.context.get('request')
        primary = obj.primary_image
        
        if primary and primary.image:
            if request:
                return request.build_absolute_uri(primary.image.url)
            return primary.image.url
        return None
    
    def to_representation(self, instance):
        ret = super().to_representation(instance)
        if self.context.get('include_all_images', False):
            ret['all_image_urls'] = self.get_all_image_urls(instance)
        return ret
    
class ProductDetailSerializer(ProductListSerializer):
    profit_margin = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = ProductListSerializer.Meta.fields + ['description', 'cost', 'profit_margin', 'reviews_count', 'created_at', 'updated_at']
        
    def get_profit_margin(self, obj):
        if obj.price and obj.cost and obj.cost > 0:
            actual_price = obj.discount_price if obj.discount_price else obj.price
            margin = ((actual_price - obj.cost)/obj.price) *100
            return round(margin, 2)
        return None 
    
class ProductFullSerializer(ProductDetailSerializer):
    images = ProductImageSerializer(many = True, read_only = True)
    variants = ProductVariantSerializer(many = True)
    variations = serializers.SerializerMethodField()
    inventory = serializers.SerializerMethodField()
    initial_stock = serializers.IntegerField(source = 'inventory.initial_stock', read_only = True)
    current_stock = serializers.IntegerField(source = 'inventory.current_stock', read_only = True)
    
    class Meta: 
        model = Product
        fields = ProductDetailSerializer.Meta.fields + ['images', 'variants', 'variations', 'inventory', 'initial_stock', 'current_stock']
        
    def get_variations(self, obj):
        variations = {}
        for variation in obj.variation_types.all():
            variations[variation.name] = variation.values
        if not variations:
            for variant in obj.variants.all():
                for key, value in variant.attributes.items():
                    if key not in variations:
                        variations[key] = []
                    if value not in variations[key]:
                        variations[key].append(value)
        return variations
    
    def get_inventory(self, obj):
        inventory = getattr(obj, 'inventory', None)
        if inventory:
            return InventorySerializer(inventory).data
        return None
    
 
class InventorySerializer(serializers.ModelSerializer):
    sold_count = serializers.IntegerField(read_only = True)
    sold_percentage = serializers.FloatField(read_only  = True)
    stock_status = serializers.CharField(read_only = True)
    
    class Meta:
        model  = InventoryRecord
        fields = [
            'id', 'initial_stock', 'current_stock', 'low_stock_threshold', 'reorder_point', 'reorder_quantity', 'last_updated', 'sold_count', 'sold_percentage', 'stock_status'
        ]
        read_only_fields = ['id', 'last_updated', 'current_stock']
        
class ProductCreateSerializer(serializers.ModelSerializer):
    images = ProductImageSerializer(many = True, required = False)
    variations = ProductVariationSerializer(many = True, required = False, source = 'variation_types')
    variants = ProductVariantSerializer(many = True, required = False)
    initial_stock = serializers.IntegerField(write_only = True, required = False, default = 0)
    low_stock_threshold = serializers.IntegerField(required = False, allow_null = True)
    reorder_point = serializers.IntegerField(required = False, allow_null = True)
    reorder_quantity = serializers.IntegerField(required = False, allow_null = True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'category', 'price', 'discount_price', 'cost', 'is_active', 'images', 'variations', 'variants', 'initial_stock', 'low_stock_threshold', 'reorder_point', 'reorder_quantity'
        ]
    def validate(self, data):
        discount_price = data.get('discount_price')
        price = data.get('price')
        cost = data.get('cost')
            
        if discount_price and price and discount_price >= price:
            raise serializers.ValidationError({"discount_price": "Must be less than regular price"})
            
        if price and cost and price < cost:
            raise serializers.ValidationError({"price": "Selling price cannot be less than cost price"})
            
        return data
    def validate_cost(self, value):
        if value is not None and value <0:
            raise serializers.ValidationError("cost cannot be negative")
        return value
         
    def create(self, validated_data):
        # Extract nested data
        images_data = validated_data.pop('images', [])
        variations_data = validated_data.pop('variation_types', [])
        variants_data = validated_data.pop('variants', [])
        # Store initial_stock in a variable
        initial_stock = validated_data.pop('initial_stock', 0)
            
        # Extract other inventory data
        inventory_data = {
            'low_stock_threshold': validated_data.pop('low_stock_threshold', None),
            'reorder_point': validated_data.pop('reorder_point', None), 
            'reorder_quantity': validated_data.pop('reorder_quantity', None)
        }
            
        # Create the product in a transaction
        from django.db import transaction
        with transaction.atomic():
            # Create the product
            product = Product.objects.create(**validated_data)
                
            # create inventory record with the explicit initial_stock value
            from inventory.services import InventoryService
            inventory_service = InventoryService()
                
            inventory, _ = inventory_service.initialize_inventory(product = product, initial_stock = initial_stock, update_if_exists= True)
                
            if inventory:
                update_fields = []
                for field in ['low_stock_threshold', 'reorder_point', 'reorder_quantity']:
                    if inventory_data[field] is not None:
                        setattr(inventory, field, inventory_data[field])
                        update_fields.append(field)
                            
                if update_fields: 
                    inventory.save(updated_fields = update_fields)
                        
            # Create images
            for image_data in images_data:
                image_serializer = ProductImageSerializer(data = {**image_data, 'product': product.id})
                    
                if image_serializer.is_valid():
                    image_serializer.save()
            # create variations 
            for variation_data in variations_data:
                ProductVariation.objects.create(product = product, **variation_data)
                    
            # Create variants
            for variant_data in variants_data: 
                ProductVariant.objects.create(product = product, **variant_data)
                    
        return product
                
class ProductUpdateSerializer(ProductCreateSerializer):
    class Meta(ProductCreateSerializer.Meta):
        pass
    
    def validate(self, data):
        # Call parent validate method
        data = super().validate(data)
        
        if self.instance:
            if 'initial_stock' in data:
                data.pop('initial_stock')
        return data
    
    def update(self, instance, validated_data):
        # Extract nested data
        images_data = validated_data.pop('images', None)
        variations_data = validated_data.pop('variation_types', None)
        variants_data = None
        if 'variants' in self.initial_data:
            variants_data = validated_data.pop('variants', None)
            
        removed_image_ids = self.initial_data.get('removed_image_ids', [])
        
        # Extract inventory data
        inventory_data  = {}
        for field in ['low_stock_threshold', 'reorder_point', 'reorder_quantity']:
            if field in validated_data:
                inventory_data[field] = validated_data.pop(field)
                
        initial_stock = validated_data.pop('initial_stock', None) if 'initial_stock' in validated_data else None
        
        from django.db import transaction
        with transaction.atomic():
            # Update product fields
            for attr, value in validated_data.items():
                setattr(instance, attr, value)
                
            instance.save()
            
            if removed_image_ids:
                ProductImage.objects.filter(id__in = removed_image_ids, product = instance).delete()
                
            inventory = getattr(instance, 'inventory', None)
            if inventory and inventory_data:
                update_fields = []
                for field, value in inventory_data.items():
                    setattr(inventory, field, value)
                    update_fields.append(field)
                    
                if update_fields:
                    inventory.save(update_fields= update_fields)
                    
                    
            elif not inventory and initial_stock is not None:
                from inventory.services import InventoryService
                inventory_service = InventoryService()
                inventory, _ = inventory_service.initialize_inventory(product = instance, initial_stock= initial_stock)
                
            # Handle variations if provided
            if variations_data is not None:
                self._handle_variations(instance, variations_data)
                
            # Handle variants if provided
            if variants_data is not None:
                # Validate variants before processing
                validated_variants = self.validate_variants(variants_data)
                self._handle_variants(instance, validated_variants)
                # Only update inventory from variants if explicit stock values were provided in variants
                if any('stock' in variant for variant in validated_variants):
                    
                    self._update_inventory_with_variants(instance, validated_variants)
                    
        return instance
     
    def validate_variants(self, variants_data):
        """Validate variants data"""
        if not variants_data:
            return variants_data
        
        # check for duplicate attributes
        attribute_sets = []
        for variant in variants_data:
            if 'attributes' not in variant:
                continue
            attributes = variant['attributes'] 
            attr_set = frozenset(attributes.items())
            
            if attr_set in attribute_sets:
                raise serializers.ValidationError("Duplicate variant attributes found")
            
            attribute_sets.append(attr_set)
            
        return variants_data 
                         
                  
    def _update_inventory_with_variants(self, instance, variants_data):
        """Update inventory record based on variant stocks , only if stock values are present"""
        if not variants_data or not any('stock' in variant for variant in variants_data):
            return
        
        # Calculate total stock from variants
        total_stock = sum(variant.get('stock', 0) for variant in variants_data if 'stock' in variant)
        
        # Use the service method to update inventory
        from inventory.services import InventoryService
        inventory_service = InventoryService()
        inventory_service.update_inventory_from_variants(instance, total_stock)
        
        # Clear product cache immediately after variant stock update
        from admin_dashboard.services.products.product_service import ProductService 
        product_service = ProductService()
        product_service.clear_product_cache(instance.id)
        
         
                
                
    def _handle_variants(self, instance, variants_data):
        """Handle variant updates"""
        existing_variants = {str(var.id): var for var in instance.variants.all()}
        
        for variant_data in variants_data:
            variant_id = str(variant_data.get('id')) if variant_data.get('id') else None
            if variant_id and variant_id in existing_variants:
                # Update existing variant
                variant = existing_variants[variant_id]
                for key, value in variant_data.items():
                    if key not in ['id', 'product']:
                        setattr(variant, key, value)
                        
                variant.save()
                
                del existing_variants[variant_id]
                
            else :
                # Create new variant
                variant_data_copy = {k: v for k , v in variant_data.items() if k not in ['id', 'product']}
                ProductVariant.objects.create(product=instance, **variant_data_copy)
                
                
    def _handle_variations(self, instance, variations_data):
        """Handle variation type updates"""
        existing_variations = {str(var.id):var for var in instance.variation_types.all()}
        
        for variation_data in variations_data:
            variation_id= str(variation_data.get('id')) if variation_data.get('id') else None
            
            if variation_id and variation_id in existing_variations:
                # Update existing variation
                variation = existing_variations[variation_id]
                for key, value in variation_data.items():
                    if key not in ['id', 'product']:
                        setattr(variation, key, value)
                variation.save()
                del existing_variations[variation_id]
            else:
                # Create new variation
                ProductVariation.objects.create(product = instance, **{k:v for k, v in variation_data.items() if k!='id'})
                
    def to_representation(self, instance):
        """Override to_representation to include full nested data in the response after create/update operations"""
        
        # Clear cache for this product before returning representation
        from admin_dashboard.services.products.product_service import ProductService 
        product_service = ProductService()
        product_service.clear_product_cache(instance.id)
        
        import time
        self.context['cache_timestamp'] = time.time()
        # use the full serializer for the response
        serializer = ProductFullSerializer(instance, context = self.context)
        return serializer.data         
    
class AdminCategoryListSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'image_url']
        
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None
    
    
class AdminCategorySerializer(serializers.ModelSerializer):
    children = serializers.SerializerMethodField()
    parent_name = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    delete_image = serializers.BooleanField(required = False, write_only= True)
    
    class Meta:
        model = Category
        fields = [
            'id', 'name', 'slug', 'description', 'image', 'image_url', 'parent', 'parent_name', 'children', 'is_active', 'created_at', 'updated_at', 'delete_image'
        ]
        read_only_fields = ['id', 'slug', 'created_at', 'updated_at', 'image_url']
        extra_kwargs = {
            'image': {'write_only': True, 'required': False}, 
            'parent': {'required': False, 'allow_null': True}
        }
        
    def get_children(self, obj):
        children = Category.objects.filter(parent = obj)
        serializer = AdminCategoryListSerializer(children, many = True, context = self.context)
        return serializer.data
    
    def get_parent_name(self, obj):
        if obj.parent:
            return obj.parent.name
        return None
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None
    
    def create(self, validated_data):
        validated_data.pop('delete_image', None)
        
        # Remove slug from name if not provided
        if 'slug' not in validated_data:
            validated_data['slug'] = slugify(validated_data['name'])
            
        return super().create(validated_data)
    
    def update(self, validated_data, instance):
        validated_data.pop('delete_image', None)
        return super().update(instance, validated_data)
    
    def validate_name(self, value):
        """Ensure unique category names, allowing for name reuse with different parents"""
        # Get the parent from the data
        parent_data = self.initial_data.get('parent', None)
        
        parent = None
        if parent_data in ['', 'null', None, 'undefined']:
            parent = None
            
        else: 
            parent = parent_data
            
        query = Category.objects.filter(name__iexact = value)
        if parent:
            query = query.filter(parent = parent)
        else:
            query = query.filter(parent__isnull = True)
            
        instance = getattr(self, 'instance', None)
        if instance and instance.pk:
            query = query.exclude(pk = instance.pk)
            
        if query.exists():
            raise serializers.ValidationError("A category with this name already exists in this location")
        return value
    
    
    def to_representation(self, instance):
        """Ensure context is properly passed to serializer and add request to context"""
        result = super().to_representation(instance)
        return result