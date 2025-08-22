import os
import random
import uuid
import datetime
from decimal import Decimal
from django.utils import timezone
from django.core.management.base import BaseCommand
from django.db import transaction

from authentication.models import CustomUser
from ecommerce.models import Product
from inventory.models import InventoryRecord, StockAdjustment
from inventory.services import InventoryService


class Command(BaseCommand):
    help = "Generate seed data for the inventory system"

    def add_arguments(self, parser):
        parser.add_argument(
            "--products", type=int, default=50, help="Number of products to process"
        )
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Clear existing inventory data before seeding",
        )
        parser.add_argument(
            "--out_of_stock",
            type=int,
            default=10,
            help="Percentage of products that should be out of stock",
        )
        parser.add_argument(
            "--low_stock",
            type=int,
            default=25,
            help="Percentage of products that should be in low stock",
        )

    def handle(self, *args, **options):
        if options["clear"]:
            self.clear_data()
            self.stdout.write(self.style.SUCCESS("Existing inventory data cleared"))

        # Get distribution parameters
        out_of_stock_percent = max(0, min(100, options["out_of_stock"]))
        low_stock_percent = max(0, min(100, options["low_stock"]))
        normal_stock_percent = 100 - out_of_stock_percent - low_stock_percent

        self.stdout.write(
            f"Target distribution: {out_of_stock_percent}% out of stock, "
            f"{low_stock_percent}% low stock, {normal_stock_percent}% normal stock"
        )

        # Disable signals during seeding if needed
        try:
            with transaction.atomic():
                self.stdout.write("Creating inventory records and adjustments...")

                # Get existing products or limit to the specified number
                self.stdout.write("Finding new products without inventory records...")
                products = list(
                    Product.objects.filter(inventoryrecord__isnull=True).order_by(
                        "-id"
                    )[: options["products"]]
                )
                product_count = len(products)

                if not products:
                    self.stdout.write(
                        self.style.WARNING(
                            "No products found without inventory. All products may be seeded, or you may need to run seed_products first."
                        )
                    )
                    return

                # Determine how many products should be in each category
                out_of_stock_count = int(product_count * out_of_stock_percent / 100)
                low_stock_count = int(product_count * low_stock_percent / 100)

                # Shuffle products to randomize which ones are out/low stock
                random.shuffle(products)

                # Process products by category
                current_index = 0

                # Create out-of-stock products
                for i in range(current_index, current_index + out_of_stock_count):
                    if i < product_count:
                        self.create_inventory_data(
                            products[i], stock_status="out_of_stock"
                        )
                current_index += out_of_stock_count

                # Create low-stock products
                for i in range(current_index, current_index + low_stock_count):
                    if i < product_count:
                        self.create_inventory_data(
                            products[i], stock_status="low_stock"
                        )
                current_index += low_stock_count

                # Create normal-stock products
                for i in range(current_index, product_count):
                    self.create_inventory_data(products[i], stock_status="normal")

            self.stdout.write(
                self.style.SUCCESS("Inventory seed data generation completed!")
            )

        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error during seeding: {str(e)}"))

    def clear_data(self):
        """Clear existing inventory data"""
        StockAdjustment.objects.all().delete()
        InventoryRecord.objects.all().delete()
        self.stdout.write("Inventory data cleared")

    def create_inventory_data(self, product, stock_status="normal"):
        """Create inventory with specific stock status"""
        # Use the inventory service to handle the inventory creation/update
        service = InventoryService()

        # Set thresholds based on product characteristics or randomness
        low_stock_threshold = random.choice([5, 10, 15, 20])
        reorder_point = random.choice([3, 5, 8, 10])
        reorder_quantity = random.choice([10, 20, 30, 50])

        # Initial stock amount depends on desired status
        if stock_status == "out_of_stock":
            initial_stock = random.randint(30, 100)
            target_stock = 0
        elif stock_status == "low_stock":
            initial_stock = random.randint(30, 100)
            # Ensure stock is between 1 and the threshold
            target_stock = random.randint(1, low_stock_threshold)
        else:  # normal stock
            initial_stock = random.randint(50, 200)
            target_stock = random.randint(low_stock_threshold + 5, initial_stock)

        # Create or update inventory record
        inventory, created = service.initialize_inventory(
            product=product, initial_stock=initial_stock, update_if_exists=True
        )

        # Set additional fields
        inventory.low_stock_threshold = low_stock_threshold
        inventory.reorder_point = reorder_point
        inventory.reorder_quantity = reorder_quantity
        inventory.save()

        # Create stock adjustments to simulate history and reach target stock
        self._create_stock_adjustments(inventory, initial_stock, target_stock)

        self.stdout.write(
            f"Created {stock_status} inventory for {product.name}: "
            f"Initial: {initial_stock}, Current: {target_stock}, "
            f"Threshold: {low_stock_threshold}"
        )

        return inventory

    def _create_stock_adjustments(self, inventory, initial_stock, target_stock):
        """Create a history of stock adjustments to reach a target stock level"""
        # Get random admin user
        admin_users = CustomUser.objects.filter(is_staff=True)
        admin = admin_users.first() if admin_users.exists() else None

        # Create adjustment for initial stock
        StockAdjustment.objects.create(
            inventory=inventory,
            quantity=initial_stock,
            previous_stock=0,
            new_stock=initial_stock,
            adjustment_type="restock",
            reason="Initial inventory",
            reference=f"INIT-{uuid.uuid4().hex[:6].upper()}",
            admin=admin,
            created_at=timezone.now() - datetime.timedelta(days=random.randint(30, 60)),
        )

        # Start with initial stock
        current_stock = initial_stock

        # Create a more efficient adjustment to reach target stock
        # Rather than many small adjustments, make a few larger ones
        remaining_reduction = current_stock - target_stock

        if remaining_reduction > 0:
            # Create 1-3 large sales to reduce stock
            num_sales = min(3, max(1, remaining_reduction // 5))
            for i in range(num_sales):
                # For the last sale, ensure we hit the target exactly
                if i == num_sales - 1:
                    sale_qty = -(current_stock - target_stock)
                else:
                    # Divide remaining reduction roughly equally
                    avg_reduction = remaining_reduction // (num_sales - i)
                    # Add some randomness but ensure progress
                    sale_qty = -random.randint(
                        max(1, avg_reduction // 2), avg_reduction
                    )

                new_stock = current_stock + sale_qty

                StockAdjustment.objects.create(
                    inventory=inventory,
                    quantity=sale_qty,
                    previous_stock=current_stock,
                    new_stock=new_stock,
                    adjustment_type="sale",
                    reason=self._get_adjustment_reason("sale"),
                    reference=f"SALE-{uuid.uuid4().hex[:6].upper()}",
                    admin=admin,
                    created_at=timezone.now()
                    - datetime.timedelta(days=random.randint(1, 30)),
                )

                current_stock = new_stock
                remaining_reduction = current_stock - target_stock

        # Update current stock in inventory to ensure consistency
        inventory.current_stock = current_stock
        inventory.save(update_fields=["current_stock"])

        # Add a maximum of 2 random adjustments if we have stock left
        if target_stock > 0:
            for _ in range(random.randint(0, 2)):
                adj_type = random.choice(["return", "damaged", "inventory"])

                if adj_type == "damaged":
                    # Ensure we don't damage more than we have, and leave at least 1 item
                    max_damage = min(2, current_stock - 1)
                    if max_damage < 1:
                        continue
                    qty = -random.randint(1, max_damage)
                elif adj_type == "return":
                    qty = random.randint(1, 3)
                else:  # inventory
                    qty = random.randint(-1, 1)

                # Skip if adjustment would cause negative stock
                if current_stock + qty < 0:
                    continue

                new_stock = current_stock + qty

                StockAdjustment.objects.create(
                    inventory=inventory,
                    quantity=qty,
                    previous_stock=current_stock,
                    new_stock=new_stock,
                    adjustment_type=adj_type,
                    reason=self._get_adjustment_reason(adj_type),
                    reference=f"{adj_type.upper()}-{uuid.uuid4().hex[:6].upper()}",
                    admin=admin,
                    created_at=timezone.now()
                    - datetime.timedelta(days=random.randint(1, 20)),
                )

                current_stock = new_stock

        # Ensure final stock matches our target by adding a final adjustment if needed
        if current_stock != target_stock:
            final_adj = target_stock - current_stock

            StockAdjustment.objects.create(
                inventory=inventory,
                quantity=final_adj,
                previous_stock=current_stock,
                new_stock=target_stock,
                adjustment_type="inventory",
                reason="Inventory reconciliation",
                reference=f"RECON-{uuid.uuid4().hex[:6].upper()}",
                admin=admin,
                created_at=timezone.now()
                - datetime.timedelta(days=random.randint(1, 5)),
            )

        # Update current stock in inventory to ensure consistency
        inventory.current_stock = target_stock
        inventory.save(update_fields=["current_stock"])

    def _get_adjustment_reason(self, adjustment_type):
        """Generate realistic reasons for inventory adjustments"""
        reasons = {
            "sale": [
                "Customer purchase",
                "Online order",
                "Store sale",
                "Bulk order",
                "Promotional sale",
            ],
            "return": [
                "Customer return",
                "Defective product",
                "Wrong size",
                "Unwanted gift",
                "Warranty claim",
            ],
            "damaged": [
                "Shipping damage",
                "Storage damage",
                "Display item wear",
                "Quality control inspection",
                "Expiration",
            ],
            "restock": [
                "Regular inventory restock",
                "Seasonal restock",
                "Low inventory replenishment",
                "New shipment",
                "Back-ordered items received",
            ],
            "inventory": [
                "Inventory count adjustment",
                "Stock reconciliation",
                "Inventory audit",
                "System correction",
                "Cycle count adjustment",
            ],
        }

        return random.choice(reasons.get(adjustment_type, ["General adjustment"]))
