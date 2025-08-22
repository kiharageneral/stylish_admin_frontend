from django.utils import timezone
from django.db import transaction
from django.db.models import F, Sum, Count, Q
from ecommerce.models import Product, FlashSale, FlashSaleItem
from rest_framework.exceptions import ValidationError
import json
import uuid
import logging

logger = logging.getLogger(__name__)


class FlashSaleService:
    """Service for managing flash sales"""
    def log_exception(self, exception, message):
        """Log exception with message"""
        logger.exception(f"{message}: {str(exception)}")
        
    def log_error(self, message):
        """Log error message"""
        logger.error(f"ERROR : {message}")
        
    def success_response(self, data):
        """Return success response with data"""
        return {"success": True, "data": data}
    
    def error_response(self, error):
        """Return error response with message"""
        return {"success": False, "error": error}
    
    def get_active_flash_sales(self, customer_groups = None):
        """Get currently active flash sales. """
        now = timezone.now()
        query = FlashSale.objects.filter(is_active = True, start_data__lte = now, end_date__gt = now)
        
        return query.order_by('end_date')
    
    def create_flash_sale(self, data, user = None):
        try:
            with transaction.atomic():
                data_copy = data.copy()
                products_data = data_copy.pop('products', None)
                
                if products_data is not None:
                    logger.log(f"SERVICE: Extracted products data (from validated_data): {products_data}")
                else:
                    logger.error("SERVICE: No 'products' field found in validated_data or it was none")
                
                flash_sale = FlashSale.objects.create(**data_copy)
                added_products_details = []
                
                if products_data:
                    added_products_details = self._add_products_to_flash_sale(flash_sale, products_data)
                    
                return self.success_response({
                    'message': 'Flash sale created successfully', 
                    'flash_sale_id': flash_sale.id, 
                    'flash_sale': {
                        'id': flash_sale.id, 
                        'title': flash_sale.title, 
                        'description': flash_sale.description, 
                        'discount_percentage': flash_sale.discount_percentage, 
                        'start_date': flash_sale.start_date.isoformat(),
                        'end_date': flash_sale.end_date.isoformat(),
                        'is_active': flash_sale.is_active, 
                        'purchase_limit': flash_sale.purchase_limit, 
                        'minimum_order_value': flash_sale.minimun_order_value, 
                        'is_public': flash_sale.is_public, 
                        'allow_stacking_discounts': flash_sale.allow_stacking_discounts
                    }, 
                    'products_added': len(added_products_details)
                })
                
        except ValidationError as e:
            self.log_error(f"SERVICE: Validation error during flash sale creation: {e.detail}")
            return self.error_response(error=e.detail)
        except Exception as e:
            self.log_exception(e, "SERVICE: Failed to create flash sale (unexpected exception)", full_traceback = True)
            return self.error_response(error= f"An unexpected error occurred {str(e)}")
        
    def update_flash_sale(self, flash_sale_id, data, user= None):
        """Update an existing flash sale"""
        try:
            flash_sale = FlashSale.objects.get(id = flash_sale_id)
            
            with transaction.atomic():
                # create a copy of data to avoid modifying the original
                data_copy = data.copy() if hasattr(data, 'copy') else dict(data)
                
                # Extract products data before updating flash sale
                products_data = None
                if 'products' in data_copy:
                    products_data = data_copy.pop('products')
                    
                for field, value in data_copy.items():
                    if hasattr(flash_sale, field):
                        setattr(flash_sale, field, value)
                        
                flash_sale.save()
                
                products_result = {}
                
                if products_data is not None:
                    flash_sale.items.all().delete()
                    added_products = self._add_products_to_flash_sale(flash_sale, products_data)
                    products_result = {'products_added': len(added_products)}
                    
                result = {
                    'message': 'Flash sale updated successfully', 
                    'flash_sale_id': flash_sale.id, 
                    'flash_sale': {
                        'id': flash_sale.id, 
                        'title': flash_sale.title,
                        'description': flash_sale.description, 
                        'discount_percentage': flash_sale.discount_percentage, 
                        'start_date': flash_sale.start_date, 
                        'end_date': flash_sale.end_date, 
                        'is_active': flash_sale.is_active, 
                        'purchase_limit': flash_sale.purchase_limit, 
                        'minimum_order_value': flash_sale.minimun_order_value, 
                        'is_public': flash_sale.is_public,
                        'allow_stacking_discounts': flash_sale.allow_stacking_discounts
                    }
                }
                result.update(products_result)
                
                return self.success_response(result)
        except FlashSale.DoesNotExist:
            return self.error_response(error='Flash sale not found')
        except ValidationError as e:
            return self.error_response(error=str(e))
        except Exception as e:
            self.log_exception(e, 'Failed to updated flash sale') 
            return self.error_response(error= str(e))  
            
                    
                    
                    
    def _add_products_to_flash_sale(self, flash_sale_instance, products_data_list):
        """Helper method to add products (list of dicts) to a flash sale"""
        
        added_items_details = []
        errors_encountered = []
        
        for index, product_data in enumerate(products_data_list):
            try:
                
                try:
                    product_id = product_data.get('product_id')
                    product_instance = Product.objects.get(id = product_id, is_active = True)
                except Product.DoesNotExist:
                    errors_encountered.append(f"Product with id  (ID: {product_id}) not found or is not active (index{index})")
                    continue
                
                if FlashSaleItem.objects.filter(flash_sale =flash_sale_instance, product = product_instance).exists():
                    errors_encountered.append(f"Product {product_instance.name} (ID: {product_id}) is already in this flash sales (index  {index}).")
                    continue
                override_discount = product_data.get('override_discount'), 
                stock_limit = product_data.get('stock_limit'), 
                item_purchase_limit = product_data.get('item_purchase_limit')
                # Create flash sale item
                flash_sale_item = FlashSaleItem.objects.create(
                    flash_sale = flash_sale_instance, 
                    product = product_instance, 
                    override_discount = override_discount, 
                    stock_limit = stock_limit, 
                    item_purchase_limit = item_purchase_limit
                     
                )
                
                added_items_details.append({'item_id': flash_sale_item.id, 'product_id': product_instance.id, 'product_name': product_instance.name})
                
            except Exception as e:
                error_msg = f"Error processing product item at index {index} (ID: {product_data.get('product_id', 'N/A')}): {str(e)}"
                self.log_error(f"SERVICE (_add_products_to_flash_sale): {error_msg}")
                errors_encountered.append(error_msg)
        if errors_encountered:
            self.log_error(f"SERVICE (_add_products_to_flash_sale for FS ID {flash_sale_instance.id}): Finished with {len(errors_encountered)} errors {errors_encountered}")
            
        
        return added_items_details
        

    def toggle_flash_sale_status(self, flash_sale_id):
        """Toggle active status of a flash sale"""
        try:
            flash_sale = FlashSale.objects.get(id=flash_sale_id)
            flash_sale.is_active = not flash_sale.is_active
            flash_sale.save(update_fields=['is_active', 'updated_at'])
            
            status = 'activated' if flash_sale.is_active else 'deactivated'
            
            return self.success_response({
                'message': f'Flash sale {status} successfully', 
                'is_active': flash_sale.is_active
            })
            
        except FlashSale.DoesNotExist:
            return self.error_response(error='Flash sale not found')
        except Exception as e:
            self.log_exception(e, f"Failed to toggle flash sale status")
            return self.error_response(error = str(e))
        
    def delete_flash_sale(self, flash_sale_id):
        """Delete a flash sale"""
        try:
            flash_sale = FlashSale.objects.get(id=flash_sale_id)
            flash_sale.delete()
            return self.success_response({
                'message': 'Flash sale deleted successfully'
            })
        except FlashSale.DoesNotExist:
            return self.error_response(error='Flash sale not found')
        except Exception as e:
            self.log_exception(e, "Failed to delete flash sale")
            return self.error_response(error=str(e))
        
    
    def get_flash_sale_stats(self, flash_sale_id = None):
        """Get statistics about flash sales"""
        try:
            now = timezone.now()
            # Base stats
            stats = {
                'total_flash_sales': FlashSale.objects.count(), 
                'active_flash_sales': FlashSale.objects.filter(is_active = True, start_date__lte = now, end_date_gt = now).count(), 
                'upcoming_flash_sales': FlashSale.objects.filter(is_active = True, start_date__gt = now).count(), 
                'expired_flash_sales': FlashSale.objects.filter(end_date__lt = now).count()
            }  
            
            if flash_sale_id:
                try:
                    flash_sale = FlashSale.objects.get(id = flash_sale_id)
                    items = flash_sale.items.all()
                    
                    total_units = items.aggregate(Sum('units_sold'))
                    total_units_sold = total_units['units_sold__sum'] if total_units['units_sold__sum'] is not None else 0
                    
                    stats.update({
                        'title': flash_sale.title, 
                        
                        'totala_products': items.count(), 
                        'total_units_sold': total_units_sold, 
                        'average_discount': flash_sale.discount_percentage, 
                        'is_active': flash_sale.is_active, 
                        'is_ongoing': flash_sale.is_ongoing, 
                        'time_remaining': str(flash_sale.time_remaining) if flash_sale.time_remaining else None, 
                        'total_revenue': flash_sale.total_revenue,
                        'revenue_increase': flash_sale.revenue_increase, 
                        'total_orders': flash_sale.total_orders, 
                        'order_increase': flash_sale.order_increase, 
                        'units_sold': flash_sale.units_sold, 
                        'units_sold_increase': flash_sale.units_sold_increase, 
                        'conversion_rate': flash_sale.conversion_rate, 
                        'conversion_rate_increas': flash_sale.conversion_rate_increase, 
                        'average_order_value': flash_sale.average_order_value, 
                        'is_public': flash_sale.is_public, 
                        'purchase_limit': flash_sale.purchase_limit
                        
                    })
                    
                    # Top selling products in this flash sale
                    top_selling = items.order_by('-units_sold')[:5]
                    stats['top_selling_products'] = [{
                        'product_id': str(item.product.id), 
                        'product_name': item.product.name, 
                        'units_sold': item.units_sold, 
                        'effective_discount': item.effective_discount, 
                        'revenue': item.revenue
                    } for item in top_selling]
                    
                    
                    if hasattr(flash_sale, 'customer_groups') and flash_sale.customer_groups:
                        stats['customer_groups'] = flash_sale.customer_groups
                        
                except FlashSale.DoesNotExist:
                    pass
                
            return self.success_response(stats)
        except Exception as e:
            self.log_exception(e, "Failed to get flash sale stats")
            return self.error_response(error=str(e))
        