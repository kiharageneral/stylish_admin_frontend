from django.conf import settings
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.db import transaction
from django.db.models import Sum, Count, Avg
from decimal import Decimal
import random
import datetime
import uuid
from faker import Faker

from authentication.models import CustomUser
from ecommerce.models import Product, Order, OrderItem, Category
from analytics.models import (
    AnalyticsEvent, RevenueMetrics, AnalyticsSummary, 
    UserSession, AnalyticsDashboard, UserBehavior
)

class Command(BaseCommand):
    help = 'Seed analytics data for e-commerce application'

    def add_arguments(self, parser):
        # MODIFIED: Increased default days for historical data
        parser.add_argument('--days', type=int, default=400, help='Number of days of analytics data to generate')
        parser.add_argument('--events-per-day', type=int, default=100, help='Number of events to generate per day')
        parser.add_argument('--clear', action='store_true', help='Clear existing analytics data')
        
    def clear_data(self):
        """Clear all existing analytics data"""
        AnalyticsEvent.objects.all().delete()
        RevenueMetrics.objects.all().delete()
        AnalyticsSummary.objects.all().delete()
        UserSession.objects.all().delete()
        AnalyticsDashboard.objects.all().delete()
        UserBehavior.objects.all().delete()
        
    def handle(self, *args, **options):
        days = options['days']
        events_per_day = options['events_per_day']
        
        if options['clear']:
            self.clear_data()
            self.stdout.write(self.style.SUCCESS('Existing analytics data cleared'))
        
        # Setup
        fake = Faker()
        end_date = timezone.now().date()
        start_date = end_date - datetime.timedelta(days=days)
        
        # Get existing data
        users = list(CustomUser.objects.all())
        products = list(Product.objects.filter(is_active=True))
        categories = list(Category.objects.all())
        
        if not users or not products:
            self.stdout.write(self.style.ERROR('No users or products found. Run product seeder first.'))
            return
            
        try:
            with transaction.atomic():
                # Create data for each day
                current_date = start_date
                
                while current_date <= end_date:
                    self.stdout.write(f'Generating analytics for {current_date}...')
                    
                    # Create analytics events for this day
                    events = self.create_analytics_events(
                        current_date, 
                        users, 
                        products, 
                        events_per_day
                    )
                    
                    # Create user sessions for this day
                    sessions = self.create_user_sessions(
                        current_date, 
                        users, 
                        int(events_per_day * 0.3)  # Roughly 30% of events create sessions
                    )
                    
                    # Create user behavior records
                    self.create_user_behaviors(
                        current_date,
                        users,
                        products,
                        sessions
                    )
                    
                    # Generate daily summary metrics based on events
                    self.create_daily_summaries(current_date, events, sessions)
                    
                    # Create revenue metrics based on actual orders for this date
                    self.create_revenue_metrics(current_date)
                    
                    # Create analytics dashboard data (aggregate of all metrics)
                    self.create_dashboard_data(current_date, products, categories)
                    
                    current_date += datetime.timedelta(days=1)
                    
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error generating analytics data: {str(e)}'))
            raise
            
        self.stdout.write(self.style.SUCCESS(f'Successfully generated analytics data for {days} days'))
    
    def create_analytics_events(self, date, users, products, count):
        """Create analytics events for a specific date"""
        fake = Faker()
        events = []
        
        # Create a datetime range for the entire day
        start_datetime = datetime.datetime.combine(date, datetime.time.min)
        end_datetime = datetime.datetime.combine(date, datetime.time.max)
        
        for _ in range(count):
            # Create a random datetime within the day
            event_datetime = fake.date_time_between(
                start_date=start_datetime,
                end_date=end_datetime
            )
            
            # Convert to timezone-aware datetime if using timezone
            if settings.USE_TZ:
                event_datetime = timezone.make_aware(event_datetime)
            
            user = random.choice(users)
            event_type = random.choice([
                'view', 'cart_add', 'cart_remove', 'purchase', 
                'search', 'wishlist_add'
            ])
            
            # Create event with appropriate data based on type
            event_data = {
                'user': user,
                'event_type': event_type,
                'created_at': event_datetime,
                'metadata': {}
            }
            
            if event_type in ['view', 'cart_add', 'cart_remove', 'purchase', 'wishlist_add']:
                event_data['product'] = random.choice(products)
                
                # Add relevant metadata
                if event_type == 'cart_add':
                    event_data['metadata'] = {
                        'quantity': random.randint(1, 3),
                        'variant_id': str(uuid.uuid4()),
                        'from_section': random.choice(['featured', 'recommended', 'search', 'category']),
                        'was_discounted': random.choice([True, False, False, False])
                    }
                elif event_type == 'view':
                    event_data['metadata'] = {
                        'view_duration': random.randint(5, 180),  # seconds
                        'source': random.choice(['search', 'category', 'recommendation', 'direct']),
                        'device': random.choice(['mobile', 'desktop', 'tablet']),
                        'detailed_view': random.choice([True, False])
                    }
                    
            elif event_type == 'search':
                event_data['product'] = None
                event_data['search_query'] = fake.word() + ' ' + random.choice(['shirt', 'dress', 'pants', 'shoes', 'jacket'])
                event_data['metadata'] = {
                    'filter_applied': random.choice([True, False]),
                    'results_count': random.randint(0, 50),
                    'sorted_by': random.choice(['relevance', 'price_low', 'price_high', 'newest', 'popular'])
                }
            
            # Create the event
            event = AnalyticsEvent.objects.create(**event_data)
            events.append(event)
            
        return events
    
    def create_user_sessions(self, date, users, count):
        """Create user sessions for a specific date"""
        fake = Faker()
        sessions = []
        
        for _ in range(count):
            # About 20% of sessions are from anonymous users
            user = None if random.random() < 0.2 else random.choice(users)
            
            # Create start and end times within the day
            start_datetime = datetime.datetime.combine(
                date, 
                datetime.time(
                    hour=random.randint(0, 23),
                    minute=random.randint(0, 59)
                )
            )
            
            # Session duration between 1 and 60 minutes
            session_duration = datetime.timedelta(minutes=random.randint(1, 60))
            end_datetime = start_datetime + session_duration
            
            # Make timezone-aware if needed
            if settings.USE_TZ:
                start_datetime = timezone.make_aware(start_datetime)
                end_datetime = timezone.make_aware(end_datetime)
            
            # Create the session
            session = UserSession.objects.create(
                user=user,
                session_id=str(uuid.uuid4()),
                start_time=start_datetime,
                end_time=end_datetime,
                pages_viewed=random.randint(1, 20),
                created_at=start_datetime
            )
            sessions.append(session)
            
        return sessions
    
    def create_user_behaviors(self, date, users, products, sessions):
        """Create one user behavior record for each user session."""
        fake = Faker()
        behaviors = []
        
        # Common entry/exit pages
        entry_pages = [
            '/', '/products', '/category/men', '/category/women',
            '/sale', '/new-arrivals', '/featured'
        ]
        
        exit_pages = entry_pages + [
            '/cart', '/checkout', '/account', '/wishlist',
            '/product/detail', '/search'
        ]

        # Iterate over each unique session to create a corresponding behavior record.
        # This guarantees a one-to-one relationship.
        for session in sessions:
            user = session.user if session.user else random.choice(users)
            
            # Create time spent (between 1 minute and 2 hours)
            time_spent = datetime.timedelta(
                minutes=random.randint(1, 120)
            )
            
            # Generate search queries
            num_searches = random.randint(0, 5)
            search_queries = [fake.word() for _ in range(num_searches)]
            
            # Generate filter usage
            filter_usage = {}
            if random.random() < 0.7:  # 70% chance of using filters
                possible_filters = {
                    'price': random.choice(['under_50', '50_to_100', 'over_100']),
                    'size': random.choice(['S', 'M', 'L', 'XL']),
                    'color': random.choice(['black', 'white', 'blue', 'red']),
                }
                for filter_key, filter_value in possible_filters.items():
                    if random.random() < 0.5:
                        filter_usage[filter_key] = filter_value
            
            # Cart behavior
            cart_additions = random.randint(0, 5)
            cart_removals = random.randint(0, cart_additions)
            cart_abandonment = random.random() < 0.7 if cart_additions > 0 else False
            
            # Use get_or_create to prevent integrity errors on subsequent runs.
            # This is robust and idempotent.
            behavior, created = UserBehavior.objects.get_or_create(
                session_id=session.session_id,
                defaults={
                    'user': user,
                    'page_views': session.pages_viewed, # Use actual pages viewed from session
                    'time_spent': time_spent,
                    'entry_page': random.choice(entry_pages),
                    'exit_page': random.choice(exit_pages),
                    'search_queries': search_queries,
                    'filter_usage': filter_usage,
                    'cart_additions': cart_additions,
                    'cart_removals': cart_removals,
                    'cart_abandonment': cart_abandonment,
                    'created_at': session.start_time # Align created_at with the session
                }
            )
            
            if created:
                behaviors.append(behavior)
                
        return behaviors
    
    def create_daily_summaries(self, date, events, sessions):
        """Create analytics summary for a specific date"""
        
        # Calculate metrics from events
        total_views = len([e for e in events if e.event_type == 'view'])
        
        # Calculate unique visitors from sessions
        unique_visitors = len(set(s.user.id for s in sessions if s.user)) + len([s for s in sessions if not s.user])
        
        # Calculate other metrics
        conversion_rate = 0.0
        purchases = len([e for e in events if e.event_type == 'purchase'])
        if unique_visitors > 0:
            conversion_rate = (purchases / unique_visitors) * 100
            
        # Calculate bounce rate (sessions with only 1 page view)
        bounced_sessions = len([s for s in sessions if s.pages_viewed == 1])
        bounce_rate = 0.0
        if sessions:
            bounce_rate = (bounced_sessions / len(sessions)) * 100
            
        # Calculate average session duration
        if sessions:
            total_seconds = sum(
                [(s.end_time - s.start_time).total_seconds() for s in sessions if s.end_time]
            )
            avg_duration = datetime.timedelta(seconds=total_seconds / len(sessions))
        else:
            avg_duration = datetime.timedelta(minutes=5)  # Default
            
        # Create or update the summary
        summary, created = AnalyticsSummary.objects.update_or_create(
            date=date,
            defaults={
                'total_views': total_views,
                'unique_visitors': unique_visitors,
                'conversion_rate': conversion_rate,
                'bounce_rate': bounce_rate,
                'avg_session_duration': avg_duration
            }
        )
        
        return summary
    
    def create_revenue_metrics(self, date):
        """Create revenue metrics based on actual orders for the date"""
        
        # Get all orders for this date
        day_start = datetime.datetime.combine(date, datetime.time.min)
        day_end = datetime.datetime.combine(date, datetime.time.max)
        
        if settings.USE_TZ:
            day_start = timezone.make_aware(day_start)
            day_end = timezone.make_aware(day_end)
            
        # Query orders created on this date
        orders = Order.objects.filter(
            created_at__gte=day_start,
            created_at__lte=day_end
        )
        
        # If we don't have any real orders, create synthetic data
        if not orders.exists():
            # Generate synthetic revenue between $500 and $5000
            total_revenue = Decimal(str(round(random.uniform(500, 5000), 2)))
            order_count = random.randint(5, 50)
            avg_order_value = total_revenue / order_count if order_count > 0 else Decimal('0.00')
            
         
        else:
            # Calculate metrics from actual orders
            total_revenue = orders.aggregate(sum=Sum('total_amount'))['sum'] or Decimal('0.00')
            order_count = orders.count()
            avg_order_value = total_revenue / order_count if order_count > 0 else Decimal('0.00')
            
            # Calculate refunds (assume some orders have refunds)
            refunded_orders = orders.filter(status='refunded')
           
            
        # Create or update revenue metrics
        metrics, created = RevenueMetrics.objects.update_or_create(
            date=date,
            defaults={
                'total_revenue': total_revenue,
                'order_count': order_count,
                'average_order_value': avg_order_value,

            }
        )
        
        return metrics
    
    def create_dashboard_data(self, date, products, categories):
        """Create analytics dashboard data for a specific date"""
        
        # Get or create revenue metrics
        try:
            revenue_metrics = RevenueMetrics.objects.get(date=date)
            total_revenue = revenue_metrics.total_revenue
            total_orders = revenue_metrics.order_count
            avg_order_value = revenue_metrics.average_order_value
        except RevenueMetrics.DoesNotExist:
            # Generate synthetic data if no revenue metrics exist
            total_revenue = Decimal(str(round(random.uniform(500, 5000), 2)))
            total_orders = random.randint(5, 50)
            avg_order_value = total_revenue / total_orders if total_orders > 0 else Decimal('0.00')
        
        # Get or create analytics summary
        try:
            analytics_summary = AnalyticsSummary.objects.get(date=date)
            conversion_rate = analytics_summary.conversion_rate
            bounce_rate = analytics_summary.bounce_rate
        except AnalyticsSummary.DoesNotExist:
            # Generate synthetic data if no summary exists
            conversion_rate = random.uniform(1.0, 5.0)
            bounce_rate = random.uniform(20.0, 60.0)
            
        # User metrics
        total_users = CustomUser.objects.count()
        # Assume 1-5% of total users are new each day
        new_users = int(total_users * random.uniform(0.01, 0.05))
        returning_users = int(total_users * random.uniform(0.05, 0.15))
        
        # Product metrics - top selling products
        # In a real implementation, this would come from OrderItem aggregation
        # For now, we'll create synthetic data
        top_selling = []
        sample_products = random.sample(list(products), min(10, len(products)))
        for product in sample_products:
            top_selling.append({
                'id': str(product.id),
                'name': product.name,
                'category': product.category.name if product.category else 'Uncategorized',
                'units_sold': random.randint(1, 20),
                'revenue': float(product.price) * random.randint(1, 20)
            })
        
        # Sort by units sold
        top_selling.sort(key=lambda x: x['units_sold'], reverse=True)
        
        # Category distribution
        category_dist = {}
        for category in categories:
            if category.parent is None:  # Only count parent categories
                category_dist[category.name] = {
                    'sales_percentage': random.uniform(5.0, 30.0),
                    'product_count': Product.objects.filter(
                        category__parent=category
                    ).count()
                }
        
        # Normalize percentages to add up to 100%
        total_percentage = sum(c['sales_percentage'] for c in category_dist.values())
        if total_percentage > 0:
            for category in category_dist:
                category_dist[category]['sales_percentage'] = (
                    category_dist[category]['sales_percentage'] / total_percentage * 100
                )
        
        # Cart metrics
        cart_abandonment_rate = random.uniform(60.0, 85.0)  # Common industry range
        items_per_cart = random.uniform(1.0, 4.0)
        
        # Create dashboard entry
        dashboard, created = AnalyticsDashboard.objects.update_or_create(
            date=date,
            defaults={
                'total_revenue': total_revenue,
                'total_orders': total_orders,
                'average_order_value': avg_order_value,
                'total_users': total_users,
                'new_users': new_users,
                'returning_users': returning_users,
                'top_selling_products': top_selling,
                'category_distribution': category_dist,
                'cart_abandonment_rate': cart_abandonment_rate,
                'items_per_cart': items_per_cart,
                'conversion_rate': conversion_rate,
                'bounce_rate': bounce_rate
            }
        )
        
        return dashboard