from django.contrib import admin
from .models import InventoryRecord, StockAdjustment

@admin.register(InventoryRecord)
class InventoryRecordAdmin(admin.ModelAdmin):
    list_display = ('current_stock', 'initial_stock', 'product')
    search_fields = ('product',)
    
@admin.register(StockAdjustment)
class StockAdjustmentAdmin(admin.ModelAdmin):
    list_display = ('inventory', 'quantity', 'previous_stock', 'reason')
    search_fields = ('inventory',)