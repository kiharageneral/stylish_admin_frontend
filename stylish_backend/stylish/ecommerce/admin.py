from django.contrib import admin

from .models import Category, Product, Order, OrderItem, Review, WishList, WishListItem, ProductImage, ProductVariant, ProductVariation, Banner, FlashSale, FlashSaleItem, OrderCategory

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display= ('name', 'parent', 'created_at')
    search_fields= ('name',)
    
@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display= ('name', 'category', 'price')
    search_fields= ('name',)  
    list_filter = ('category', 'is_active')  

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display= ('id', 'user', 'total_amount', 'status', 'created_at')
    search_fields= ('user__email',)  
    list_filter = ('status',) 
    
    
@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display= ('id', 'order', 'product', 'quantity')
    search_fields= ('order__id','product__name')  

@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display= ('product', 'user', 'rating')
    list_filter = ('rating', ) 
    
@admin.register(WishList)
class WishListAdmin(admin.ModelAdmin):
    list_display= ('user', 'created_at', 'updated_at')
    search_fields= ('user__email',)  
@admin.register(WishListItem)
class WishListItemAdmin(admin.ModelAdmin):
    list_display= ('wishlist', 'product', 'added_at')
    search_fields= ('product__name',) 
    
@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display= ('image', 'alt_text', 'is_primary', 'product')

@admin.register(ProductVariant)
class ProductVariantAdmin(admin.ModelAdmin):
    list_display= ('product', 'attributes', 'sku', 'price', 'discount_price', 'stock')
    
@admin.register(ProductVariation)
class ProductVariationAdmin(admin.ModelAdmin):
    list_display= ('product', 'name', 'values')

@admin.register(Banner)
class BannerAdmin(admin.ModelAdmin):
    list_display= ('title', 'subtitle', 'is_active', 'start_date', 'end_date', 'created_at')

@admin.register(FlashSale)
class FlashSaleAdmin(admin.ModelAdmin):
    list_display= ('title', 'description', 'discount_percentage', 'start_date', 'end_date', 'is_active')
    
@admin.register(FlashSaleItem)
class FlashSaleItemAdmin(admin.ModelAdmin):
    list_display= ('flash_sale', 'product', 'override_discount', 'stock_limit', 'units_sold')
