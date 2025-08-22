import random
import uuid
from decimal import Decimal
from django.utils import timezone
import datetime
from django.core.management.base import BaseCommand
from django.db import transaction
from faker import Faker

from authentication.models import CustomUser
from ecommerce.models import Product, Category, Order, OrderItem, OrderCategory, ProductVariant

fake = Faker()

class Command(BaseCommand):
    help = 'Generate seed data for Orders'

    def add_arguments(self, parser):
        parser.add_argument('--orders', type=int, default=150, help='Number of orders to create')
        # MODIFIED: Increased default days for historical data
        parser.add_argument('--days', type=int, default=400, help='Number of days of historical orders to generate')
        parser.add_argument('--clear', action='store_true', help='Clear existing order data before seeding')

    def handle(self, *args, **options):
        if options['clear']:
            self.clear_data()

        users = CustomUser.objects.all()
        products = Product.objects.all()
        categories = Category.objects.all()

        if not users.exists() or not products.exists():
            self.stdout.write(self.style.ERROR('Users and Products must exist. Run seed_authentication and seed_products first.'))
            return

        try:
            with transaction.atomic():
                self.stdout.write('Creating orders...')
                self.create_orders(users, products, categories, options['orders'], options['days'])
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error creating orders: {e}'))

        self.stdout.write(self.style.SUCCESS('Order seed data generation completed!'))

    def clear_data(self):
        """Clear existing order data"""
        self.stdout.write('Clearing Orders...')
        OrderItem.objects.all().delete()
        OrderCategory.objects.all().delete()
        Order.objects.all().delete()
        self.stdout.write(self.style.SUCCESS('Order data cleared.'))

    def create_orders(self, users, products, categories, count, days):
        """Create orders with order items"""
        status_weights = {'completed': 0.6, 'processing': 0.2, 'in_transit': 0.1, 'on_hold': 0.05, 'rejected': 0.05}

        for _ in range(count):
            user = random.choice(list(users))
            status = random.choices(list(status_weights.keys()), weights=list(status_weights.values()), k=1)[0]

            order = Order.objects.create(
                user=user,
                total_amount=Decimal('0'),
                shipping_address=fake.address(),
                contact=fake.phone_number()[:20],
                status=status,
                tracking_number=f"TRK-{uuid.uuid4().hex[:12].upper()}" if status in ['in_transit', 'completed'] else None,
                created_at=timezone.now() - datetime.timedelta(days=random.randint(1, days))
            )

            item_count = random.randint(1, 5)
            selected_products = random.sample(list(products), min(item_count, len(products)))

            order_categories = set()
            total_amount = Decimal('0')

            for product in selected_products:
                variants = ProductVariant.objects.filter(product=product)
                price = product.display_price
                size = 'One Size'
                variation = 'Default'

                if variants.exists():
                    variant = random.choice(list(variants))
                    price = variant.effective_price
                    size = variant.attributes.get('Size', 'One Size')
                    variation = variant.attributes.get('Color', 'Default')

                quantity = random.randint(1, 3)
                item_total = price * quantity

                OrderItem.objects.create(order=order, product=product, quantity=quantity, size=size, variation=variation, price=price)
                
                if product.category:
                    order_categories.add(product.category)
                    if product.category.parent:
                        order_categories.add(product.category.parent)

                total_amount += item_total

            order.total_amount = total_amount
            order.save(update_fields=['total_amount'])

            for category in order_categories:
                OrderCategory.objects.get_or_create(order=order, category=category)