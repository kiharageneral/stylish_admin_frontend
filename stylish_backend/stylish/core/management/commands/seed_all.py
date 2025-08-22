# management/commands/seed_all.py
from django.core.management.base import BaseCommand
from django.core.management import call_command
import time

class Command(BaseCommand):
    help = 'Seed all application data in the correct dependency order'

    def add_arguments(self, parser):
        parser.add_argument('--clear', action='store_true', help='Clear existing data before seeding')
        # User Seeding
        parser.add_argument('--users', type=int, default=50, help='Number of users to create')
        # Product Seeding
        parser.add_argument('--parent_categories', type=int, default=8, help='Number of parent categories')
        parser.add_argument('--child_categories', type=int, default=30, help='Number of child categories')
        parser.add_argument('--products', type=int, default=200, help='Number of products')
        # Order Seeding
        parser.add_argument('--orders', type=int, default=150, help='Number of orders to create')
        parser.add_argument('--days', type=int, default=60, help='Number of days of historical orders to generate')
        parser.add_argument('--out_of_stock', type=int, default=10, help='Percentage of products that should be out of stock')
        parser.add_argument('--low_stock', type=int, default=25, help='Percentage of products that should be in low stock')
        parser.add_argument('--reviews', type=int, default=400, help='Number of reviews')
        parser.add_argument('--flash_sales', type=int, default=5, help='Number of flash sales')
        parser.add_argument('--banners', type=int, default=8, help='Number of promotional banners')
        parser.add_argument('--inventory_products', type=int, default=50, help='Number of products to process for inventory')
        parser.add_argument('--analytics_days', type=int, default=30, help='Number of days of analytics data')
        parser.add_argument('--analytics_events_per_day', type=int, default=100, help='Number of analytics events per day')


    def handle(self, *args, **options):
        start_time = time.time()
        clear_flag = options['clear']

        # Step 1: Authentication (Users)
        self.stdout.write(self.style.NOTICE('Seeding authentication data...'))
        call_command('seed_authentication', users=options['users'], clear=clear_flag)

        # Step 2: E-commerce Catalog (Products, Categories)
        self.stdout.write(self.style.NOTICE('Seeding product catalog data...'))
        call_command(
            'seed_products',
            parent_categories=options['parent_categories'],
            child_categories=options['child_categories'],
            products=options['products'],
            clear=clear_flag
        )
        
        # Step 3: E-commerce Transactions (Orders)
        self.stdout.write(self.style.NOTICE('Seeding order data...'))
        call_command(
            'seed_orders',
            orders=options['orders'],
            days=options['days'],
            clear=clear_flag
        )

        # Step 4: Inventory data
        self.stdout.write(self.style.NOTICE('Seeding inventory data...'))
        call_command(
            'seed_inventory',
            products=options['inventory_products'],
            clear=clear_flag
        )

        # Step 5: Analytics data
        self.stdout.write(self.style.NOTICE('Seeding analytics data...'))
        call_command(
            'seed_analytics',
            days=options['analytics_days'],
            clear=clear_flag
        )
        
        execution_time = time.time() - start_time
        self.stdout.write(self.style.SUCCESS(f'All data successfully seeded in {execution_time:.2f} seconds'))
        
        # command to seed database with new parameters
        # python manage.py seed_all --users 100 --parent_categories 10 --child_categories 40 --products 300 --inventory_products 75 --out_of_stock 15 --low_stock 20 --reviews 600 --orders 200 --flash_sales 5 --banners 8 --analytics_days 45 --analytics_events_per_day 150