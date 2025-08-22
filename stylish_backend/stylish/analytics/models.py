from django.db import models
from datetime import timedelta
import uuid

class AnalyticsEvent(models.Model):
    EVENT_TYPES = [
        ('view', 'Product View'), 
        ('cart_add', 'Add to Cart'), 
        ('cart_remove', 'Remove from Cart'), 
        ('purchase', 'Purchase'), 
        ('search', 'Search'), 
        ('wishilist_add', 'Add to Wishlist'), 
    ]
    id = models.UUIDField(primary_key = True, default= uuid.uuid4, editable=False)
    user = models.ForeignKey('authentication.CustomUser', on_delete = models.CASCADE)
    event_type = models.CharField(max_length=20, choices = EVENT_TYPES)
    product = models.ForeignKey('ecommerce.Product', on_delete=models.CASCADE,null = True)
    search_query= models.CharField(max_length=255, null = True)
    metadata = models.JSONField(default = dict)
    created_at = models.DateTimeField(auto_now_add = True)
    
    class Meta:
        indexes = [
            models.Index(fields = ['event_type', 'created_at']),
            models.Index(fields = ['user', 'created_at']),
        ]
        
class RevenueMetrics(models.Model):
    id = models.UUIDField(primary_key=True, default = uuid.uuid4, editable = False)
    date = models.DateField(db_index = True, unique=True)
    total_revenue = models.DecimalField(max_digits=10, decimal_places=2)
    order_count = models.IntegerField()
    average_order_value = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add  = True)
    
    class Meta:
        ordering = ['-date']
        indexes = [
            models.Index(fields=['date']), 
        ]
        
    @property
    def profit(self):
        return float(self.total_revenue)*0.3
    
    def __str__(self):
        return f"Revenue for {self.date}: ${self.total_revenue}"
    

class AnalyticsSummary(models.Model):
    id = models.UUIDField(primary_key = True, default = uuid.uuid4, editable=False)
    date = models.DateField(unique= True)
    total_views = models.IntegerField(default = 0)
    unique_visitors= models.IntegerField(default = 0)
    conversion_rate = models.FloatField(default =0.0)
    bounce_rate = models.FloatField(default =0.0)
    avg_session_duration = models.DurationField(null = True)
    created_at = models.DateTimeField(auto_now_add=True)
    
class UserSession(models.Model):
    id = models.UUIDField(primary_key = True, default = uuid.uuid4, editable = False)
    user = models.ForeignKey('authentication.CustomUser', on_delete = models.CASCADE, null = True)
    session_id = models.CharField(max_length=100)
    start_time = models.DateTimeField(auto_now_add = True)
    end_time = models.DateTimeField(null = True)
    pages_viewed = models.IntegerField(default = 0)
    created_at = models.DateTimeField(auto_now_add = True)
    
class AnalyticsDashboard(models.Model):
    id = models.UUIDField(primary_key = True, default = uuid.uuid4, editable = False)
    date = models.DateField(unique = True)
    
    # Revenue metrics
    total_revenue = models.DecimalField(max_digits = 12, decimal_places=2, default = 2)
    total_orders = models.IntegerField(default =0)
    average_order_value = models.DecimalField(max_digits = 10, decimal_places=2, default = 0)
    
    # User metrics
    total_users = models.IntegerField(default = 0)
    new_users = models.IntegerField(default = 0)
    return_users = models.IntegerField(default = 0)
    
    # Product metrics
    top_selling_products = models.JSONField(default = dict)
    category_distribution = models.JSONField(default = dict)
    
    # Cart metrics
    cart_abandonment_rate = models.FloatField(default=0)
    items_per_cart = models.FloatField(default=0)
    
    # Performance metrics
    conversion_rate = models.FloatField(default=0)
    bounce_rate = models.FloatField(default=0)
    
    created_at = models.DateTimeField(auto_now_add = True)
    class Meta:
        indexes = [
            models.Index(fields=['date']),
        ]
        
class UserBehavior(models.Model):
    id = models.UUIDField(primary_key=True, default = uuid.uuid4, editable = False)
    
    user = models.ForeignKey('authentication.CustomUser', on_delete = models.CASCADE, null = True, blank = True)
    session_id = models.CharField(max_length=100, unique = True)
    # Page navigation
    page_views = models.IntegerField(default = 0)
    time_spent = models.DurationField(default = timedelta)
    entry_page = models.CharField(max_length=255)
    exit_page = models.CharField(max_length = 255, blank = True)
    
    # Search behavior
    search_queries = models.JSONField(default = list)
    filter_usage = models.JSONField(default = dict)
    
    # Cart behavior
    cart_additions = models.IntegerField(default = 0)
    cart_removals = models.IntegerField(default = 0)
    cart_abandonment = models.BooleanField(default = False)
    
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)
    
    class Meta:
        indexes = [
            models.Index(fields = ['session_id']), 
            models.Index(fields = ['created_at']), 
        ]