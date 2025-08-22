from django.db import models
import uuid

class UserPreferences(models.Model):
    id = models.UUIDField(primary_key = True, default = uuid.uuid4, editable=False)
    user = models.ForeignKey('authentication.CustomUser', on_delete=models.CASCADE)
    category = models.ForeignKey('ecommerce.Category', on_delete= models.CASCADE)
    weight = models.FloatField(default=1.0)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateField(auto_now = True)
    
    class Meta:
        unique_together = ['user', 'category']
        indexes = [
            models.Index(fields=['user', 'category'])
        ]
        
class ProductView(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable = False)
    user = models.ForeignKey('authentication.CustomUser', on_delete=models.CASCADE)
    product = models.ForeignKey('ecommerce.Product', on_delete=models.CASCADE)
    view_count = models.IntegerField(default = 1)
    last_viewed = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'product']
        indexes =[
            models.Index(fields=['user', 'product']),
            models.Index(fields=['last_viewed']),
        ]
        
class SimilarProducts(models.Model):
    id = models.UUIDField(primary_key=True, default =uuid.uuid4, editable = False)
    product = models.ForeignKey('ecommerce.Product', on_delete=models.CASCADE, related_name='source_product')
    similar_product = models.ForeignKey('ecommerce.Product', on_delete=models.CASCADE, related_name = 'similar_to')
    similarity_score = models.FloatField()
    updated_at  = models.DateTimeField(auto_now = True)
    
    class Meta:
        unique_together = ['product', 'similar_product']
        indexes = [
            models.Index(fields=['product', 'similarity_score']),
        ]