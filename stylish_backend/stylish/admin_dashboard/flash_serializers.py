import json
from decimal import Decimal
import uuid
from django.http import QueryDict
from rest_framework import serializers
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from ecommerce.models import FlashSale, FlashSaleItem, Product


class ProductMinimalSerializer(serializers.ModelSerializer):
    """Minimal product representation for flash sales"""

    class Meta:
        model = Product
        fields = ["id", "name", "price", "is_active"]


class FlashSaleItemSeriailizer(serializers.ModelSerializer):
    """Serializer for flash sale items"""

    product = ProductMinimalSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.filter(is_active=True), source="product"
    )
    effective_discount = serializers.IntegerField(read_only=True)
    remaining_stock = serializers.IntegerField(read_only=True)
    discounted_price = serializers.SerializerMethodField()
    effective_purchase_limit = serializers.IntegerField(read_only=True)

    class Meta:
        model = FlashSaleItem
        fields = [
            "id",
            "product",
            "product_id",
            "override_discount",
            "effective_discount",
            "stock_limit",
            "units_sold",
            "remaining_stock",
            "discounted_price",
            "item_purchase_limit",
            "effective_purchase_limit",
            "revenue",
        ]

    def get_discounted_price(self, obj):
        if not hasattr(obj, "product") or not obj.product:
            return None
        discount = obj.effective_discount
        discount_factor = Decimal(str(1 - discount / 100))
        return round(obj.product.price * discount_factor, 2)


class FlashSaleItemAdminSeriailizer(serializers.ModelSerializer):
    """Serializer for flash sale items"""

    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.filter(is_active=True), source="product"
    )
    product_details = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = FlashSaleItem
        fields = [
            "id",
            "product_id",
            "product_details",
            "override_discount",
            "stock_limit",
            "units_sold",
            "item_purchase_limit",
            "revenue",
        ]

    def get_product_details(self, obj):
        discount_factor = Decimal(str(1 - obj.effective_discount / 100))
        return {
            "id": obj.product.id,
            "name": obj.product.name,
            "price": obj.product.price,
            "effective_discount": obj.product.effective_discount,
            "discounted_price": round(obj.product.price * discount_factor, 2),
            "effective_purchase_limit": obj.effective_purchase_limit,
        }


class AdminFlashSaleSerializer(serializers.ModelSerializer):
    """Detailed flash sale serializer for admin API"""

    items = FlashSaleItemSeriailizer(many=True, read_only=True)
    status = serializers.SerializerMethodField()
    time_remaining = serializers.SerializerMethodField()
    total_products = serializers.SerializerMethodField()
    total_sold = serializers.SerializerMethodField()
    imag_url = serializers.SerializerMethodField()
    average_order_value = serializers.SerializerMethodField()

    class Meta:
        model = FlashSale
        fields = [
            "id",
            "title",
            "description",
            "image",
            "image_url",
            "discount_percentage",
            "start_data",
            "end_date",
            "is_active",
            "status",
            "time_remaining",
            "created_at",
            "updated_at",
            "items",
            "total_products",
            "total_sold",
            "total_revenue",
            "revenue_increase",
            "total_orders",
            "order_increase",
            "units_sold",
            "units_sold_increase",
            "conversion_rate",
            "conversion_rate_increase",
            "purchase_limit",
            "minimum_order_value",
            "is_public",
            "allow_stacking_discounts",
            "average_order_value",
        ]

    def get_status(self, obj):
        now = timezone.now()
        if not obj.is_active:
            return "inactive"
        if obj.start_date > now:
            return "upcoming"
        if obj.end_date <= now:
            return "expired"
        return "active"

    def get_time_remaining(self, obj):
        if not obj.is_ongoing:
            return None
        return str(obj.time_remaining)

    def get_total_products(self, obj):
        return obj.items.count()

    def get_total_sold(self, obj):
        return sum(item.units_sold for item in obj.items.all())

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None

    def get_average_order_value(self, obj):
        return obj.average_order_value


class AdminFlashSaleCreateUpdateSerializer(serializers.ModelSerializer):
    """Serializer for creating and updating flash sales"""

    products = serializers.ListField(
        child=serializers.DictField(),
        required=False,
        write_only=True,
        help_text="List of products to include in the flash sale. Each product object can specify 'product_id', 'override_discount', 'stock_limit', 'item_purchase_limit'. ",
    )
    image = serializers.ImageField(required=False, allow_null=True)
    discount_percentage = serializers.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(99)]
    )

    class Meta:
        model = FlashSale
        fields = [
            "title",
            "description",
            "image",
            "discount_percentage",
            "start_date",
            "end_date",
            "is_active",
            "products",
            "purchase_limit",
            "minimum_order_value",
            "is_public",
            "allow_stacking_discounts",
        ]

    def to_internal_value(self, data):
        if isinstance(data, QueryDict):
            current_data = data.dict()
        else:
            current_data = data.copy() if hasattr(data, "copy") else dict(data)

        # Case 1: Products_data_raw is a JSON string
        if "products" in current_data:
            products_data_raw = current_data["products"]

            parsed_products_list = None

            if isinstance(products_data_raw, str):
                try:
                    parsed_products_list = json.loads(products_data_raw)
                    if not isinstance(parsed_products_list, list):
                        raise serializers.ValidationError(
                            {
                                "products": f"Products JSON string did not decode to a list. Decoded type : {type(parsed_products_list)}"
                            }
                        )

                    if not all(isinstance(item, dict) for item in parsed_products_list):
                        raise serializers.ValidationError(
                            {
                                "products": "All items in the products list must be dictionaries."
                            }
                        )

                except json.JSONDecodeError as e:
                    raise serializers.ValidationError(
                        {"products": f"Invalid JSON format for products: {str(e)}"}
                    )

                except TypeError:
                    raise serializers.ValidationError(
                        {"products": "Products data must be a valid JSON string"}
                    )

            # Case 2: products_data_raw is already a list of dicts
            elif isinstance(products_data_raw, list) and all(
                isinstance(item, dict) for item in products_data_raw
            ):
                parsed_products_list = products_data_raw

            else:
                if "products" in current_data:
                    raise serializers.ValidationError(
                        {
                            "products": f"Products data has an unexpected format. Type {type(products_data_raw)}. Expecting a JSON string or a list of product dictionaries"
                        }
                    )

            if parsed_products_list is not None:
                current_data["products"] = parsed_products_list
            else:
                if "products" in current_data:
                    current_data.pop("products")

        internal_value = super().to_internal_value(current_data)
        return internal_value

    def validate(self, attrs):
        """Validated start and end dates, and product items."""

        start_date = attrs.get("start_date")
        end_date = attrs.get("end_date")

        if self.instance:
            start_date = start_date or self.instance.start_date
            end_date = end_date or self.instance.end_date

        if start_date and end_date and start_date >= end_date:
            raise serializers.ValidationError(
                {"end_date": "End date must be after start date"}
            )

        minimum_order_value = attrs.get("minimum_order_value")
        if minimum_order_value is not None and minimum_order_value <= 0:
            raise serializers.ValidationError(
                {"minimum_order_value": "Minimum order value must be positive"}
            )

        purchase_limit = attrs.get("purchase_limit")
        if purchase_limit is not None and purchase_limit <= 0:
            raise serializers.ValidationError(
                {"purchase_limit": "Purchase limit must be positive."}
            )

        products_list = attrs.get("products", [])
        if not isinstance(products_list, list):
            raise serializers.ValidationError(
                {
                    "products": f"Products must be a list . Got {type(products_list).__name__}"
                }
            )

        for i, product_data_item in enumerate(products_list):
            if not isinstance(product_data_item, dict):
                raise serializers.ValidationError(
                    {
                        f"products[{i}]": f"Each product item must be a dictionary.Got {type(product_data_item).__name__}."
                    }
                )

            if "product_id" not in product_data_item:
                raise serializers.ValidationError(
                    {
                        f"products[{i}].product_id": "Product ID is required for each item."
                    }
                )

            try:
                uuid.UUID(str(product_data_item["product_id"]))
            except ValueError:
                raise serializers.ValidationError(
                    {
                        f"products[{i}].product_id": f"Invalid UUID format for product_id: {product_data_item['product_id']}"
                    }
                )

            override_discount = product_data_item.get("override_discount")
            if override_discount is not None:
                if not isinstance(override_discount, int) or not (
                    1 <= override_discount <= 99
                ):
                    raise serializers.ValidationError(
                        {
                            f"products[{i}].override_discount": "Override discount must be an integer between 1 and 99"
                        }
                    )

            stock_limit = product_data_item.get("stock_limit")
            if stock_limit is not None:
                if not isinstance(stock_limit, int) or stock_limit < 0:
                    raise serializers.ValidationError(
                        {
                            f"products[{i}].stock_limit": "Stock limit must be a non-negative integer"
                        }
                    )

            item_purchase_limit = product_data_item.get("item_purchase_limit")
            if item_purchase_limit is not None:
                if not isinstance(item_purchase_limit, int) or item_purchase_limit < 0:
                    raise serializers.ValidationError(
                        {
                            f"products[{i}].item_purchase_limit": "Item purchase limit must be a non-negative integer."
                        }
                    )

        return attrs
