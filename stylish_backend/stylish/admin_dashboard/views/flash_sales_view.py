from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from django.utils import timezone
from django.db.models import F, Sum, Count, Q
from django.core.cache import cache
from django.utils.decorators import method_decorator
from django.views.decorators.cache import cache_page
from rest_framework.exceptions import ValidationError
from ecommerce.models import Product, FlashSale, FlashSaleItem
from admin_dashboard.flash_serializers import (
    AdminFlashSaleSerializer,
    AdminFlashSaleCreateUpdateSerializer,
    FlashSaleItemAdminSeriailizer,
    FlashSaleItemSeriailizer,
)
from admin_dashboard.core.cache_util import CacheUtil
import json
from admin_dashboard.services.products.flash_sale_service import FlashSaleService


class AdminFlashSaleViewSet(viewsets.ModelViewSet):
    """Admin API for flash sales"""

    permission_classes = [IsAdminUser]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.cache_util = CacheUtil(model_name="flash_sales")
        self.flash_sale_service = FlashSaleService()

    def get_serializer_class(self):
        if self.action in ["create", "update", "partial_update"]:
            return AdminFlashSaleCreateUpdateSerializer
        return AdminFlashSaleSerializer

    def get_queryset(self):
        # Allow filtering by status
        status = self.request.query_params.get("status", None)
        now = timezone.now()

        is_public = self.request.query_params.get("is_public", None)
        group = self.request.query_params.get("customer_group", None)

        queryset = FlashSale.objects.all()

        if status == "active":
            queryset = queryset.filter(
                is_active=True, start_date__lte=now, end_date__gt=now
            )

        elif status == "upcoming":
            queryset = queryset.filter(is_active=True, start_date__gt=now)
        elif status == "expired":
            queryset = queryset.filter(end_date__lt=now)

        elif status == "inactive":
            queryset = queryset.filter(is_active=False)

        if is_public is not None:
            is_public_bool = is_public.lower() == "true"
            queryset = queryset.filter(is_public=is_public_bool)

        if group:
            queryset = queryset.filter(customer_groups__contains=[group])

        return queryset.order_by("-created_at")

    def get_serializer_context(self):
        context = super().get_serializer_context()
        return context

    def create(self, request, *args, **kwargs):
        """Create a flash sale with products"""
        serializer = self.get_serializer(data=request.data)

        try:
            serializer.is_valid(raise_exception=True)
            validated_data = serializer.validated_data

            # Use Service to create flash sale with products
            result = self.flash_sale_service.create_flash_sale(
                validated_data, request.user
            )

            if not result.get("success", False):
                return Response(
                    {
                        "success": False,
                        "error": result.get(
                            "error",
                            "Service call failed with no specific error message",
                        ),
                        "data": result.get("data", {}),
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

            self.cache_util.clear_cache()
            cache_key = "flash_sales_stats"
            cache.delete(cache_key)

            return Response(
                {
                    "success": True,
                    "data": {
                        "flash_sale": result.get("data", {}).get("flash_sale", {}),
                        "message": "Flash sale created successfully",
                        "product_added": result.get("data", {}).get(
                            "products_added", 0
                        ),
                    },
                },
                status=status.HTTP_201_CREATED,
            )

        except ValidationError as e:
            return Response(
                {"success": False, "error": "validation error", "data": e.detail},
                status=status.HTTP_400_BAD_REQUEST,
            )

        except Exception as e:
            return Response(
                {"success": False, "error": "An unexpected server error occurred."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    def update(self, request, *args, **kwargs):
        """Update a flash sale with products"""
        flash_sale = self.get_object()
        data = request.data.copy()

        # User service to update flash sale with products
        result = self.flash_sale_service.update_flash_sale(
            flash_sale.id, data, request.user
        )

        if not result.get("success", False):
            return Response(
                {"error": result.get("error")}, status=status.HTTP_400_BAD_REQUEST
            )

        self.cache_util.clear_item_cache(flash_sale.id)
        self.cache_util.clear_cache()

        # Return detailed response
        return Response(
            result.get("data", {}).get("flash_sale", {}), status=status.HTTP_200_OK
        )

    @action(detail=True, methods=["post"])
    def toggle_status(self, request, pk=None):
        """Toggle active status of a flash sale"""
        result = self.flash_sale_service.toggle_flash_sale_status(pk)

        if result.get("success", False):
            self.cache_util.clear_item_cache(pk)
            self.cache_util.clear_cache()
            return Response(result)

        return Response(result, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=["post"])
    def add_products(self, request, pk=None):
        """Add products to a flash sale"""
        flash_sale = self.get_object()
        products_data = request.data.get("products", [])

        if isinstance(products_data, str):
            try:
                products_data = json.loads(products_data)
            except json.JSONDecodeError:
                return Response(
                    {"success": False, "error": "Invalid JSON format for products"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        try:
            added_products = self.flash_sale_service._add_products_to_flash_sale(
                flash_sale, products_data
            )
            self.cache_util.clear_item_cache(flash_sale.id)
            self.cache_util.clear_cache()

            return Response(
                {
                    "success": True,
                    "data": {
                        "added_count": len(added_products),
                        "message": f"Added {len(added_products)} products to flash sale",
                    },
                }
            )

        except Exception as e:
            return Response(
                {"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST
            )

    def perform_destroy(self, instance):
        """Deletes flash sale"""
        result = self.flash_sale_service.delete_flash_sale(instance.id)

        if not result.get("success", False):
            raise ValidationError(result.get("error"))

        self.cache_util.clear_item_cache(instance.id)
        self.cache_util.clear_cache()

        instance.delete()

    @action(detail=True, methods=["post"])
    def remove_products(self, request, pk=None):
        """Remove products from a flash sale"""
        flash_sale = self.get_object()
        product_ids = request.data.get("product_ids", [])

        try:
            result = FlashSaleItem.objects.filter(
                flash_sale=flash_sale, product_id__in=product_ids
            ).delete()

            self.cache_util.clear_item_cache(flash_sale.id)

            return Response(
                {
                    "success": True,
                    "data": {
                        "removed_count": result[0],
                        "message": f"Removed {result[0]} products from flash sale",
                    },
                }
            )

        except Exception as e:
            return Response(
                {"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=["get"])
    def stats(self, request):
        """Get flash sale statistics"""
        # Check if bypass_cache parameter is present
        bypass_cache = (
            request.query_params.get("bypass_cache", "false").lower() == "true"
        )

        if bypass_cache:
            result = self.flash_sale_service.get_flash_sale_stats()
        else:
            cache_key = "flash_sales_stats"
            cached_result = cache.get(cache_key)

            if cached_result:
                result = cached_result
            else:
                result = self.flash_sale_service.get_flash_sale_stats()
                cache.set(cache_key, result, 120)

        if result.get("success", False):
            return Response(result)

        return Response(result, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=["get"])
    def detail_stats(self, request, pk=None):
        """Get detailed statistics for a specific flash sale"""
        bypass_cache = (
            request.query_params.get("bypass_cache", "false").lower() == "true"
        )

        if bypass_cache:
            result = self.flash_sale_service.get_flash_sale_stats(pk)
        else:
            cache_key = f"flash_sales{pk}_stats"
            cached_result = cache.get(cache_key)

            if cached_result:
                result = cached_result
            else:
                result = self.flash_sale_service.get_flash_sale_stats(pk)
                cache.set(cache_key, result, 60)

        if result.get("success", False):
            return Response(result)

        return Response(result, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=["get"])
    def items(self, request, pk=None):
        """Get items for a specific flash sale"""
        try:
            flash_sale = self.get_object()
            items = flash_sale.items.select_related("product").all()

            serializer = FlashSaleItemSeriailizer(items, many=True)
            return Response({"success": True, "data": serializer.data})

        except Exception as e:
            return Response(
                {"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=True, methods=["post"])
    def update_item(self, request, pk=None):
        """Update a specific item in a flash sale"""
        flash_sale = self.get_object()
        item_id = request.data.get("item_id")

        try:
            item = FlashSaleItem.objects.get(id=item_id, flash_sale=flash_sale)

            # update fields
            if "override_discount" in request.data:
                item.override_discount = request.data["override_discount"]

            if "stock_limit" in request.data:
                item.stock_limit = request.data["stock_limit"]

            if "item_purchase_limit" in request.data:
                item.item_purchase_limit = request.data["item_purchase_limit"]

            item.save()

            # clear cache
            self.cache_util.clear_item_cache(flash_sale.id)

            return Response(
                {"success": True, "data": {"message": "Item updated successfully"}}
            )

        except FlashSaleItem.DoesNotExist:
            return Response(
                {"success": False, "error": "Item not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

        except Exception as e:
            return Response(
                {"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=["get"], url_path="product_search")
    def product_search(self, request):
        """Search products for adding to flash sales"""
        query = request.query_params.get("query", "")
        if len(query) < 2:
            return Response({"success": True, "data": []})

        try:
            products = (
                Product.objects.filter(
                    Q(name__icontains=query) | Q(category__name__icontains=query)
                )
                .select_related("category")
                .filter(is_active=True)
            )

            # Exclude products already in active flash sales if specified
            exclude_active = (
                request.query_params.get("exclude_active", "false").lower() == "true"
            )

            if exclude_active:
                now = timezone.now()
                active_sale_product_ids = FlashSaleItem.objects.filter(
                    flash_sale__is_active=True,
                    flash_sale__start_date__lte=now,
                    flash_sale__end_date__gt=now,
                ).values_list("product_id", flat=True)

                products = products.exclude(id__in=active_sale_product_ids)

            products = products[:20]

            data = [
                {
                    "id": str(product.id),
                    "name": product.name,
                    "category": (
                        product.category.name if product.category else "Uncategorized"
                    ),
                    "price": product.price,
                    "stock": product.stock if hasattr(product, "stock") else None,
                }
                for product in products
            ]

            return Response({"success": True, "data": data}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {"success": False, "error": str(e)}, status=status.HTTP_400_BAD_REQUEST
            )
