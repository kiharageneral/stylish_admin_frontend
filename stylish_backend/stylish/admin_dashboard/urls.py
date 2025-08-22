from django.urls import path, include 
from rest_framework.routers import DefaultRouter
from .views import (
    AdminProductViewSet, 
    CategoryViewSet, 
    AdminFlashSaleViewSet
)

router = DefaultRouter()
router.register(r'products', AdminProductViewSet, basename= 'admin-products')
router.register(r'categories', CategoryViewSet, basename= 'categories')
router.register(r'flash_sales', AdminFlashSaleViewSet, basename='flash-sales')

urlpatterns = [
    path('', include(router.urls))
]
