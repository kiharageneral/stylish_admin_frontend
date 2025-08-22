from django.contrib import admin
from .models import UserPreferences, ProductView, SimilarProducts

@admin.register(UserPreferences)
class UserPreferencesAdmin(admin.ModelAdmin):
    list_display = ('user', 'category', 'weight')
    search_fields = ('user__email',)
    
@admin.register(ProductView)
class ProductViewAdmin(admin.ModelAdmin):
    list_display = ('user', 'product', 'view_count')
    search_fields = ('user__email', 'product__name')
    
    
@admin.register(SimilarProducts)
class SimilarProductsAdmin(admin.ModelAdmin):
    list_display = ('product', 'similar_product', 'similarity_score')
    search_fields = ('product__name',)