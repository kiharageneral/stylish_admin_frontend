from typing import Dict, Any, List
from datetime import datetime, timedelta
from django.utils import timezone
from django.db.models import Sum, Count, Avg, F, Q
from asgiref.sync import sync_to_async
from .core import MCPTool
from ecommerce.models import Order, OrderItem, Product
from authentication.models import CustomUser
from inventory.models import StockAdjustment, InventoryRecord
import logging

logger = logging.getLogger(__name__)


class EcommerceMCPTools:
    """MCP Tools for e-commerce operations"""

    @staticmethod
    def get_sales_analytics_tool() -> MCPTool:
        return MCPTool(
            name="get_sales_analytics",
            description="Retrieve comprehensive sales analytics data including revenue, orders, and trends",
            inputSchema={
                "type": "object",
                "properties": {
                    "period": {
                        "type": "string",
                        "enum": ["today", "7days", "30days", "90days", "1year"],
                        "description": "Time period for analysis",
                    },
                    "metrics": {
                        "type": "array",
                        "items": {
                            "type": "string",
                            "enum": [
                                "revenue",
                                "orders",
                                "avg_order_value",
                                "top_products",
                                "customer_segments",
                            ],
                        },
                        "description": "Specific metrics to include",
                    },
                    "group_by": {
                        "type": "string",
                        "enum": ["day", "week", "month", "category", "customer"],
                        "description": "How to group the data",
                    },
                },
                "required": ["period"],
            },
        )

    @staticmethod
    async def handle_sales_analytics(args: Dict[str, Any]) -> Dict[str, Any]:
        """Handle sales analytics tool call"""
        period = args.get("period", "30days")
        metrics = args.get("metrics", ["revenue", "orders", "avg_order_value"])
        group_by = args.get("group_by", "day")

        # Calculate data range
        end_date = timezone.now()

        if period == "today":
            start_date = end_date.replace(hour=0, minute=0, second=0, microsecond=0)

        elif period == "7days":
            start_date = end_date - timedelta(days=7)
        elif period == "90days":
            start_date = end_date - timedelta(days=90)
        elif period == "30days":
            start_date = end_date - timedelta(days=30)
        elif period == "1year":
            start_date = end_date - timedelta(days=365)
        else:
            start_date = end_date - timedelta(days=30)

        return await sync_to_async(EcommerceMCPTools._get_sales_data)(
            start_date, end_date, metrics, group_by
        )

    @staticmethod
    def _get_sales_data(start_date, end_date, metrics, group_by) -> Dict[str, Any]:
        """Get sales data with proper field access"""
        try:
            orders_qs = (
                Order.objects.filter(
                    created_at__gte=start_date, created_at__lte=end_date
                )
                .select_related("user")
                .prefetch_related("items__proudct")
            )
            result = {
                "period": f"{start_date.isoformat()} to {end_date.isoformat()}",
                "total_records": orders_qs.count(),
            }

            if "revenue" in metrics:
                revenue_data = orders_qs.aggregate(
                    total_revenue=Sum("total_amount"),
                    avg_order_value=Avg("total_amount"),
                )
                result["revenue"] = {
                    "total": float(revenue_data.get("total_revenue", 0) or 0),
                    "average_order_value": float(
                        revenue_data.get("avg_order_value", 0) or 0
                    ),
                }

            if "orders" in metrics:
                result["orders"] = {
                    "total": orders_qs.count(),
                    "completed": orders_qs.filter(status="completed").count(),
                    "processing": orders_qs.filter(status="processing").count(),
                    "in_transit": orders_qs.filter(status="in_transit").count(),
                    "on_hold": orders_qs.filter(status="on_hold").count(),
                    "rejected": orders_qs.filter(status="rejected").count(),
                }

            if "top_products" in metrics:
                top_products = (
                    OrderItem.objects.filter(
                        order__created_at__gte=start_date,
                        order__created_at__lte=end_date,
                    )
                    .values("product__name", "product__id")
                    .annotate(
                        total_sold=Sum("quantity"),
                        total_revenue=Sum(F("quantity") * F("price")),
                    )
                    .order_by("-total_revenue")[:10]
                )
                result["top_products"] = [
                    {
                        "id": item["product__id"],
                        "name": item["product__name"],
                        "quantity_sold": item["total_sold"],
                        "revenue": float(item["total_revenue"]),
                    }
                    for item in top_products
                ]

            if "customer_segments" in metrics:
                customer_stats = (
                    orders_qs.values("user__id", "user__username")
                    .annotate(order_count=Count("id"), total_spent=Sum("total_amount"))
                    .order_by("-total_spent")[:20]
                )

                result["top_customers"] = [
                    {
                        "user_id": item["user__id"],
                        "username": item["user__username"],
                        "order_count": item["order_count"],
                        "total_spent": float(item["total_spent"]),
                    }
                    for item in customer_stats
                ]

            return result
        except Exception as e:
            logger.error(f"Error in _get_sales_data: {str(e)}")
            return {
                "error": str(e),
                "period": f"{start_date.isoformat()} to {end_date.isoformat()}",
                "total_records": 0,
            }

    @staticmethod
    def get_inventory_status_tool() -> MCPTool:
        return MCPTool(
            name="get_inventory_status",
            description="Get real-time inventory status including stock levels, alerts and recommendatations",
            inputSchema={
                "type": "object",
                "properties": {
                    "product_ids": {
                        "type": "array",
                        "items": {"type": "integer"},
                        "description": "Specific product IDs to check",
                    },
                    "category": {
                        "type": "string",
                        "description": "Filter by product category",
                    },
                    "alert_level": {
                        "type": "string",
                        "enum": [
                            "low_stock",
                            "out_of_stock",
                            "in_stock",
                            "overstocked",
                            "all",
                        ],
                        "description": "Type of inventory alerts to include",
                    },
                    "include_recommendations": {
                        "type": "boolean",
                        "description": "Whether to include restock recommendations",
                    },
                },
            },
        )

    @staticmethod
    async def handle_inventory_status(args: Dict[str, Any]) -> Dict[str, Any]:
        """Handle inventory status tool call"""
        product_ids = args.get("product_ids")
        category = args.get("category")
        alert_level = args.get("alert_level", "all")
        include_recommendations = args.get("include_recommendations", False)

        return await sync_to_async(EcommerceMCPTools._get_inventory_data)(
            product_ids, category, alert_level, include_recommendations
        )

    @staticmethod
    def _get_inventory_data(
        product_ids, category, alert_level, include_recommendations
    ) -> Dict[str, Any]:
        """Get inventory data with proper model relationships"""
        try:
            products_qs = Product.objects.select_related("category")

            if product_ids:
                products_qs = products_qs.filter(id__in=product_ids)

            if category:
                products_qs = products_qs.filter(category__name__icontains=category)

            inventory_records = InventoryRecord.objects.filter(
                product__in=products_qs
            ).select_related("product", "product__category")

            alerts = []

            if alert_level in ["low_stock", "all"]:
                low_stock_items = inventory_records.filter(
                    current_stock__lte=F("low_stock_threshold"), current_stock__gt=0
                )

                alerts.extend(
                    [
                        {
                            "type": "low_stock",
                            "product_id": str(inv.product.id),
                            "product_name": inv.product.name,
                            "current_stock": inv.current_stock,
                            "threshold": inv.low_stock_threshold,
                            "category": (
                                inv.product.category.name
                                if inv.product.category
                                else None
                            ),
                        }
                        for inv in low_stock_items
                    ]
                )

            if alert_level in ["out_of_stock", "all"]:
                out_of_stock_items = inventory_records.filter(current_stock=0)

                alerts.extend(
                    [
                        {
                            "type": "out_of_stock",
                            "product_id": str(inv.product.id),
                            "product_name": inv.product.name,
                            "current_stock": 0,
                            "category": (
                                inv.product.category.name
                                if inv.product.category
                                else None
                            ),
                        }
                        for inv in out_of_stock_items
                    ]
                )

            inventory_stats = inventory_records.aggregate(
                total_products=Count("id"),
                total_stock_value=Sum(F("current_stock") * F("product__cost")),
            )

            result = {
                "summary": {
                    "total_products": inventory_stats.get("total_products", 0),
                    "total_stock_value": float(
                        inventory_stats.get("total_stock_value", 0) or 0
                    ),
                    "alert_count": len(alerts),
                },
                "alerts": alerts,
            }

            if include_recommendations:
                recommendations = []

                for alert in alerts:
                    if alert["type"] in ["low_stock", "out_of_stock"]:
                        try:
                            inventory = InventoryRecord.objects.get(
                                product__id=alert["product_id"]
                            )
                            recommendations.append(
                                {
                                    "product_id": alert["product_id"],
                                    "product_name": alert["product_name"],
                                    "recommended_quantity": inventory.reorder_quantity,
                                    "estimated_cost": float(
                                        inventory.product.cost
                                        * inventory.reorder_quantity
                                    ),
                                    "priority": (
                                        "high"
                                        if alert["type"] == "out_of_stock"
                                        else "medium"
                                    ),
                                }
                            )

                        except InventoryRecord.DoesNotExist:
                            continue

                result["recommendations"] = recommendations

            return result
        except Exception as e:
            logger.error(f"Error in _get_inventory_data: {str(e)}")
            return {
                "error": str(e),
                "summary": {
                    "total_products": 0,
                    "total_stock_value": 0,
                    "alert_count": 0,
                },
                "alerts": [],
            }

    @staticmethod
    def get_customer_insights_tool() -> MCPTool:
        return MCPTool(
            name="get_customer_insights",
            description="Analyze customer behavior, segmentation and lifetime value",
            inputSchema={
                "type": "object",
                "properties": {
                    "segment": {
                        "type": "string",
                        "enum": [
                            "high_value",
                            "frequent_buyers",
                            "new_customers",
                            "at_risk",
                            "all",
                        ],
                        "description": "Customer segment to analyze",
                    },
                    "analysis_type": {
                        "type": "string",
                        "enum": [
                            "ltv",
                            "behavior",
                            "demographics",
                            "purchase_patterns",
                        ],
                        "description": "Type of customer analysis",
                    },
                    "time_period": {
                        "type": "string",
                        "enum": ["30days", "90days", "1year", "all_time"],
                        "description": "Time period for analysis",
                    },
                },
            },
        )

    @staticmethod
    async def handle_customer_insights(args: Dict[str, Any]) -> Dict[str, Any]:
        """Handle customer insights tool call"""
        segment = args.get("segment", "all")
        analysis_type = args.get("analysis_type", "behavior")
        time_period = args.get("time_period", "90days")

        return await sync_to_async(EcommerceMCPTools._get_customer_data)(
            segment, analysis_type, time_period
        )

    @staticmethod
    def _get_customer_data(segment, analysis_type, time_period) -> Dict[str, Any]:
        """Get customer data (sync method)"""
        end_date = timezone.now()
        if time_period == "30days":
            start_date = end_date - timedelta(days=30)
        elif time_period == "90days":
            start_date = end_date - timedelta(days=90)
        elif time_period == "1year":
            start_date = end_date - timedelta(days=365)
        else:
            start_date = None

        customers_qs = CustomUser.objects.filter(is_active=True)

        customer_stats = customers_qs.annotate(
            total_orders=Count("orders"),
            total_spent=Sum("orders__total_amount"),
            avg_order_value=Avg("orders__total_amount"),
        ).filter(total_orders__gt=0)

        if start_date:
            customer_stats = customer_stats.filter(orders__created_at__gte=start_date)

        if segment == "high_value":
            customer_stats = customer_stats.filter(total_spent__gte=1000)

        elif segment == "frequent_buyers":
            customer_stats = customer_stats.filter(total_orders__gte=5)
        elif segment == "new_customers":
            customer_stats = customer_stats.filter(
                date_joined__gte=timezone.now - timedelta(days=30)
            )

        result = {
            "segment": segment,
            "analysis_type": analysis_type,
            "time_period": time_period,
            "total_customers": customer_stats.count(),
        }

        if analysis_type == "ltv":
            ltv_stats = customer_stats.aggregate(
                avg__ltv=Avg("total_spent"),
                total_ltv=Sum("total_spent"),
                avg_orders=Avg("total_orders"),
            )

            result["lifetime_value"] = {
                "average": float(ltv_stats.get("avg_ltv", 0) or 0),
                "total": float(ltv_stats.get("total_ltv", 0) or 0),
                "average_orders": float(ltv_stats.get("avg_orders", 0) or 0),
            }

        if analysis_type == "behavior":
            top_customers = customer_stats.order_by("-total_spent")[:10]
            result["top_customers"] = [
                {
                    "id": c.id,
                    "username": c.username,
                    "total_orders": c.total_orders,
                    "total_spent": float(c.total_spent or 0),
                    "avg_order_value": float(c.avg_order_value or 0),
                }
                for c in top_customers
            ]

        return result

    @staticmethod
    def get_order_management_tool() -> MCPTool:
        return MCPTool(
            name="get_order_management",
            description="Manage and analyze order data including status, fulfillment and performance",
            inputSchema={
                "type": "object",
                "properties": {
                    "status": {
                        "type": "string",
                        "enum": [
                            "pending",
                            "processing",
                            "shipped",
                            "delivered",
                            "cancelled",
                            "all",
                        ],
                        "description": "Filter orders by status",
                    },
                    "date_range": {
                        "type": "object",
                        "properties": {
                            "start": {"type": "string", "format": "date"},
                            "end": {"type": "string", "format": "date"},
                        },
                        "description": "Date range for orders",
                    },
                    "customer_id": {
                        "type": "integer",
                        "description": "Filter by specific customer",
                    },
                    "analytics": {
                        "type": "boolean",
                        "description": "Include order analytics",
                    },
                },
            },
        )

    @staticmethod
    async def handle_order_management(args: Dict[str, Any]) -> Dict[str, Any]:
        """Handle order management tool call"""
        status = args.get("status", "all")
        date_range = args.get("date_range")
        customer_id = args.get("customer_id")
        analytics = args.get("analytics", False)

        return await sync_to_async(EcommerceMCPTools._get_order_data)(
            status, date_range, customer_id, analytics
        )

    @staticmethod
    def _get_order_data(status, date_range, customer_id, analytics) -> Dict[str, Any]:
        """Get order data with proper status handling"""
        try:
            orders_qs = Order.objects.select_related("user").prefetch_related(
                "items__product"
            )

            status_mapping = {
                "pending": "processing",
                "shipped": "in_transit",
                "delivered": "completed",
                "cancelled": "rejected",
            }

            if status != "all":
                actual_status = status_mapping.get(status, status)
                orders_qs = orders_qs.filter(status=actual_status)

            if date_range:
                if date_range.get("start"):
                    start_date = datetime.fromisoformat(date_range["start"])
                    orders_qs = orders_qs.filter(created_at__gte=start_date)

                if date_range.get("end"):
                    end_date = datetime.fromisoformat(date_range["end"])
                    orders_qs = orders_qs.filter(created_at__lte=end_date)

            if customer_id:
                orders_qs = orders_qs.filter(user_id=customer_id)

            result = {
                "total_orders": orders_qs.count(),
                "filters": {
                    "status": status,
                    "date_range": date_range,
                    "customer_id": customer_id,
                },
            }

            if analytics:
                status_dist = (
                    orders_qs.values("status")
                    .annotate(count=Count("id"))
                    .order_by("-count")
                )
                result["status_distribution"] = list(status_dist)

                revenue_stats = orders_qs.aggregate(
                    total_revenue=Sum("total_amount"),
                    avg_order_value=Avg("total_amount"),
                )

                result["revenue_analytics"] = {
                    "total": float(revenue_stats.get("total_revenue", 0) or 0),
                    "average_order_value": float(
                        revenue_stats.get("avg_order_value", 0) or 0
                    ),
                }

            recent_orders = orders_qs.order_by("-created_at")[:10]
            result["recent_orders"] = [
                {
                    "id": str(order.id),
                    "customer": order.user.username if order.user else "Guest",
                    "status": order.status,
                    "total_amount": float(order.total_amount),
                    "created_at": order.created_at.isoformat(),
                    "items_count": order.items.count(),
                }
                for order in recent_orders
            ]

            return result
        except Exception as e:
            logger.error(f"Error in _get_order_data: {str(e)}")
            return {
                "error": str(e),
                "total_orders": 0,
                "filters": {
                    "status": status,
                    "date_range": date_range,
                    "customer_id": customer_id,
                },
            }

    @staticmethod
    def get_product_recommendations() -> MCPTool:
        """Tool for AI-powered product recommendations"""
        return MCPTool(
            name="get_product_recommendations",
            description="Generate AI-powered product recommendations based on purchase history and behavior",
            inputSchema={
                "type": "object",
                "properties": {
                    "customer_id": {
                        "type": "integer",
                        "description": "Customer ID to generate recommendations for",
                    },
                    "product_id": {
                        "type": "integer",
                        "description": "Product ID to finel similar products for",
                    },
                    "category": {
                        "type": "string",
                        "description": "Product category to focus recommendations on",
                    },
                    "limit": {
                        "type": "integer",
                        "default": 10,
                        "description": "Maximum number of recommendations to return",
                    },
                    "recommendation_type": {
                        "type": "string",
                        "enum": [
                            "personal",
                            "similar",
                            "trending",
                            "cross_sell",
                            "up_sell",
                        ],
                        "description": "Type of recommendation algorithm to use",
                    },
                },
            },
        )

    @staticmethod
    async def handle_product_recommendations(args: Dict[str, Any]) -> Dict[str, Any]:
        """Handle product recommendations tool call"""
        customer_id = args.get("customer_id")
        product_id = args.get("product_id")
        category = args.get("category")
        limit = args.get("limit", 10)
        recommendation_type = args.get("recommendation_type", "personal")

        return await sync_to_async(EcommerceMCPTools._get_product_recommendations)(
            customer_id, product_id, category, limit, recommendation_type
        )

    @staticmethod
    def _get_product_recommendations(
        customer_id, product_id, category, limit, recommendation_type
    ) -> Dict[str, any]:
        """Get product recommendations (sync method)"""
        recommendations = []

        if recommendation_type == "personal" and customer_id:
            # Get customer's purchase history
            customer_orders = Order.objects.filter(
                user_id=customer_id, status="completed"
            ).prefetch_related("items__product")

            # Find products frequently bought together
            purchased_products = set()
            for order in customer_orders:
                for item in order.items.all():
                    purchased_products.add(item.product.id)

            # Get similar products based on category and price range
            if purchased_products:
                similar_products = Product.objects.filter(
                    category__in=Product.objects.filter(
                        id__in=purchased_products
                    ).values_list("category_id", flat=True)
                ).exclude(id__in=purchased_products)[:limit]

                recommendations = [
                    {
                        "product_id": p.id,
                        "name": p.name,
                        "price": float(p.price),
                        "category": p.category.name if p.category else None,
                        "reason": "Based on your purchase history",
                    }
                    for p in similar_products
                ]

            elif recommendation_type == "trending":
                # Get trending products based on recent sales
                trending = (
                    OrderItem.objects.filter(
                        order__created_at__gte=timezone.now() - timedelta(days=30)
                    )
                    .values("product__id", "product__name", "product__price")
                    .annotate(total_sold=Sum("quantity"))
                    .order_by("-total_sold")[:limit]
                )

                recommendations = [
                    {
                        "product_id": item["product__id"],
                        "name": item["product__name"],
                        "price": float(item["product__price"]),
                        "total_sold": item["total_sold"],
                        "reason": "Trending product",
                    }
                    for item in trending
                ]

            elif recommendation_type == "similar" and product_id:
                try:
                    base_product = Product.objects.get(id=product_id)
                    similar_products = Product.objects.filter(
                        category=base_product.category
                    ).exclude(id=product_id)[:limit]

                    recommendations = [
                        {
                            "product_id": p.id,
                            "name": p.name,
                            "price": float(p.price),
                            "category": p.category.name if p.category else None,
                            "reason": f"Similar to {base_product.name}",
                        }
                        for p in similar_products
                    ]

                except Product.DoesNotExist:
                    pass

            return {
                "recommendation_type": recommendation_type,
                "total_recommendations": len(recommendations),
                "recommendations": recommendations,
            }

    @staticmethod
    def get_inventory_forecast_tool() -> MCPTool:
        """Tool for inventory forecasting and demand prediction"""
        return MCPTool(
            name="get_inventory_forecast",
            description="Generate inventory forecasts and demand predictions based on historical data",
            inputSchema={
                "type": "object",
                "properties": {
                    "product_id": {
                        "type": "integer",
                        "description": "Specific product ID to forecast",
                    },
                    "category": {
                        "type": "string",
                        "description": "Product category to forecast",
                    },
                    "forecast_days": {
                        "type": "integer",
                        "default": 30,
                        "description": "Number of days to forecast ahead",
                    },
                    "historical_days": {
                        "type": "integer",
                        "default": 90,
                        "description": "Number of historical days to analyze ",
                    },
                    "include_seasonality": {
                        "type": "boolean",
                        "default": True,
                        "description": "Whether to include seasonal patterns",
                    },
                },
            },
        )

    @staticmethod
    async def handle_inventory_forecast(args: Dict[str, Any]) -> Dict[str, Any]:
        """Handle inventory forecast tool call"""
        product_id = args.get("product_id")
        category = args.get("category")
        forecast_days = args.get("forecast_days", 30)
        historical_days = args.get("historical_days", 90)
        include_seasonality = args.get("include_seasonality", True)

        return await sync_to_async(EcommerceMCPTools._get_inventory_forecast)(
            product_id, category, forecast_days, historical_days, include_seasonality
        )

    @staticmethod
    def _get_inventory_forecast(
        product_id, category, forecast_days, historical_days, include_seasonality
    ) -> Dict[str, Any]:
        """Get inventory forecast (sync method)"""
        end_date = timezone.now()
        start_date = end_date - timedelta(days=historical_days)

        if product_id:
            products_qs = Product.objects.filter(id=product_id)
        elif category:
            products_qs = Product.objects.filter(category__name__icontains=category)
        else:
            products_qs = Product.objects.all()[:10]

        forecasts = []

        for product in products_qs:
            historical_sales = (
                OrderItem.objects.filter(
                    product=product,
                    order__created_at__gte=start_date,
                    order__created_at__lte=end_date,
                )
                .values("order__created_at__date")
                .annotate(daily_quantity=Sum("quantity"))
                .order_by("order__created_at__date")
            )

            total_sold = sum(item["daily_quantity"] for item in historical_sales)
            avg_daily_demand = (
                total_sold / historical_days if historical_days > 0 else 0
            )

            forecast_demand = avg_daily_demand * forecast_days

            current_stock = getattr(product.inventory, "current_stock", 0)
            days_until_stockout = (
                current_stock / avg_daily_demand
                if avg_daily_demand > 0
                else float("inf")
            )

            forecasts.append(
                {
                    "product_id": product.id,
                    "product_name": product.name,
                    "current_stock": current_stock,
                    "avg_daily_demand": round(avg_daily_demand, 2),
                    "forecast_demand": round(forecast_demand, 2),
                    "days_until_stockout": min(days_until_stockout, 365),
                    "recommended_reorder": max(0, forecast_demand - current_stock),
                    "risk_level": (
                        "high"
                        if days_until_stockout < 7
                        else "medium" if days_until_stockout < 30 else "low"
                    ),
                }
            )

        return {
            "forecast_period": f"{forecast_days} days",
            "historical_period": f"{historical_days} days",
            "forecasts": forecasts,
        }
