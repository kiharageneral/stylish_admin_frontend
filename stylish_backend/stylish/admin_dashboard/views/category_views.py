from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAdminUser
from django_filters.rest_framework import DjangoFilterBackend
from django.core.files.uploadedfile import InMemoryUploadedFile

from ecommerce.models import Category
from admin_dashboard.product_serializers import AdminCategorySerializer
from admin_dashboard.core.cache_util import CacheUtil


class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class= AdminCategorySerializer
    permission_classes = [IsAdminUser]
    parser_classes = (MultiPartParser, FormParser, JSONParser)
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['is_active', 'parent']
    search_fields = ['name', 'description']
    ordering_fields = ['name', 'created_at', 'updated_at']
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.category_cache = CacheUtil(model_name= 'category')
        
        
    def create(self, request, *args, **kwargs):
        """Handle category creation with optional image upload and cache invalidation"""
        
        data = request.data.copy()
        
        if 'parent' not in data or data['parent'] in ['', 'null', 'undefined']:
            data['parent'] = None
            
            
        image_file = request.FILES.get('image')
        serializer = self.get_serializer(data = data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status = status.HTTP_400_BAD_REQUEST)
        instance = serializer.save() 
        
        if image_file and isinstance(image_file , InMemoryUploadedFile):
            instance.image = image_file
            instance.save(update_fields = ['image'])
            
        self.category_cache.clear_cache()
        
        return Response(
            self.get_serializer(instance).data, 
            status= status.HTTP_201_CREATED
        )
        
    
    def update(self, request, *args, **kwargs):
        """Handle category update with cache invalidation"""
        instance = self.get_object()
        data = request.data.copy()
        
        if 'parent' not in data or data['parent'] in ['', 'null', 'undefined']:
            data['parent'] = None
            
        image_file = request.FILES.get('image')
        delete_image = data.get('delete_image') == 'true'
        
        partial = kwargs.pop('partial', False)
        serializer = self.get_serializer(instance, data = data, partial = partial)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status= status.HTTP_400_BAD_REQUEST)
        self.perform_update(serializer)
        
        if delete_image and instance.image:
            instance.image.delete(save = False) 
            instance.image = None
            instance.save(update_fields = ['image'])
            
        elif image_file and isinstance(image_file, InMemoryUploadedFile):
            if instance.image:
                instance.image.delete(save = False)
                
            instance.image = image_file
            instance.save(update_fields = ['image'])
            
        self.category_cache.clear_item_cache(instance.id)
        self.category_cache.clear_cache()
        
        return Response(serializer.data)
    
    
    def destroy(self, request, *args, **kwargs):
        """Handle category deletion with cache invalidation"""
        instance = self.get_object()
        instance_id = instance.id
        
        response = super().destroy(request, *args, **kwargs)
        
        # Ensure cache is cleared only on successful deletion
        if response.status_code == status.HTTP_204_NO_CONTENT:
            self.category_cache.clear_item_cache(instance_id)
            self.category_cache.clear_cache()
            
        return response
    
    
    @action(detail= False, methods= ['get'])
    def root_categories(self, request):
        """Get only top-level categories (no parent)"""
        root_categories = Category.objects.filter(parent = None)
        serializer = self.get_serializer(root_categories, many = True)
        return Response(serializer.data)
    
    @action(detail= True, methods= ['get'])
    def subcategories(self, request , pk = None):
        """Get all subcategories for a specific category"""
        category = self.get_object()
        subcategories = Category.objects.filter(parent = category)
        serializer = self.get_serializer(subcategories, many = True)
        return Response(serializer.data)
        