import os
import random
import uuid
from decimal import Decimal
from django.utils import timezone
import datetime
from django.core.management.base import BaseCommand
from django.db import transaction
from django.conf import settings
from django.utils.text import slugify
from faker import Faker
import requests
from django.core.files.base import ContentFile

from ecommerce.models import (
    Category, Product, ProductVariation, ProductVariant, 
    ProductImage, Order, OrderItem, Review,
    OrderCategory, FlashSale, FlashSaleItem, Banner
)

fake = Faker()

class Command(BaseCommand):
    help = 'Generate seed data for Products and Categories'

    def add_arguments(self, parser):
        parser.add_argument('--parent_categories', type=int, default=8, help='Number of parent categories')
        parser.add_argument('--child_categories', type=int, default=30, help='Number of child categories')
        parser.add_argument('--products', type=int, default=200, help='Number of products')
        parser.add_argument('--clear', action='store_true', help='Clear existing product and category data before seeding')

    def handle(self, *args, **options):
        if options['clear']:
            self.clear_data()

        # Disable signals during seeding for performance
        from django.db.models.signals import post_save
        from ecommerce.models import Product
        # from inventory.signals import create_inventory_for_product
            
        # Disconnect the correct signal at the beginning.
        # post_save.disconnect(create_inventory_for_product, sender=Product)

        try:
            with transaction.atomic():
                self.stdout.write('Creating categories...')
                categories = self.create_categories(
                    options['parent_categories'],
                    options['child_categories']
                )

                self.stdout.write('Creating products...')
                products = self.create_products(categories, options['products'])

                self.stdout.write('Creating product variations and variants...')
                for product in products:
                    self.create_product_variations_and_variants(product)

                self.stdout.write('Creating product images...')
                for product in products:
                    self.create_product_images(product, 4)

        finally:
            pass
            # Re-connect signal
            # post_save.connect(create_inventory_for_product, sender=Product)

        self.stdout.write(self.style.SUCCESS('Product and category seed data generation completed!'))

    def clear_data(self):
        """Clear existing product and category data"""
        self.stdout.write('Clearing Products, Categories, Variations, and Images...')
        ProductImage.objects.all().delete()
        ProductVariant.objects.all().delete()
        ProductVariation.objects.all().delete()
        Product.objects.all().delete()
        Category.objects.all().delete()
        self.stdout.write(self.style.SUCCESS('Product & Category data cleared.'))

    def create_categories(self, parent_count, child_count):
        """Create parent and child categories with appropriate images"""
        parent_categories = []
        all_categories = []
        
        # Define reliable category images from Unsplash
        category_images = {
            'Men': [
                'https://images.unsplash.com/photo-1617137968427-85924c800a22',
                'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8',
                'https://images.unsplash.com/photo-1507680434567-5739c80be1ac',
                'https://images.unsplash.com/photo-1542327897-4141b355e20e'
            ],
            'Women': [
                'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5',
                'https://images.unsplash.com/photo-1581044777550-4cfa60707c03',
                'https://images.unsplash.com/photo-1554412933-514a83d2f3c8',
                'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f'
            ],
            'Kids': [
                'https://images.unsplash.com/photo-1543854704-783aaadf1971',
                'https://images.unsplash.com/photo-1518831959646-742c3a14ebf7',
                'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4',
                'https://images.unsplash.com/photo-1522771930-78848d9293e8'
            ],
            'Accessories': [
                'https://images.unsplash.com/photo-1556306535-0f09a537f0a3',
                'https://images.unsplash.com/photo-1588444650733-d0f79a129f2f',
                'https://images.unsplash.com/photo-1574025305631-a6333f405f7f',
                'https://images.unsplash.com/photo-1611085583191-a3b181a88401'
            ],
            'Footwear': [
                'https://images.unsplash.com/photo-1560343090-f0409e92791a',
                'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
                'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a',
                'https://images.unsplash.com/photo-1549298916-b41d501d3772'
            ],
            'Sports': [
                'https://images.unsplash.com/photo-1581077262877-9cc51c13f5bc',
                'https://images.unsplash.com/photo-1575537302964-96cd47c06b1b',
                'https://images.unsplash.com/photo-1554068865-24cecd4e34b8',
                'https://images.unsplash.com/photo-1516826897695-ec3ecd1d9914'
            ],
            'Formal': [
                'https://images.unsplash.com/photo-1507679799987-c73779587ccf',
                'https://images.unsplash.com/photo-1553240799-37bbf573dcd3',
                'https://images.unsplash.com/photo-1580657018950-c7f7d6a6d990',
                'https://images.unsplash.com/photo-1593030761757-71fae45fa0e7'
            ],
            'Casual': [
                'https://images.unsplash.com/photo-1589465885857-44edb59bbff2',
                'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f',
                'https://images.unsplash.com/photo-1581044777550-4cfa60707c03',
                'https://images.unsplash.com/photo-1583245877800-a4ddf4578a60'
            ]
        }
        
        # Map child categories to appropriate images
        child_category_images = {
            'Shirts': [
                'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4',
                'https://images.unsplash.com/photo-1626497764746-6dc36546b388',
                'https://images.unsplash.com/photo-1604695573706-b3efe27c4642'
            ],
            'T-shirts': [
                'https://images.unsplash.com/photo-1576566588028-4147f3842f27',
                'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab',
                'https://images.unsplash.com/photo-1586790170083-2f9ceadc732d'
            ],
            'Pants': [
                'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80',
                'https://images.unsplash.com/photo-1542574271-7f3b92e6c821',
                'https://images.unsplash.com/photo-1593795899768-947c4929449d'
            ],
            'Jeans': [
                'https://images.unsplash.com/photo-1541099649105-f69ad21f3246',
                'https://images.unsplash.com/photo-1565084888279-aca607ecce0c',
                'https://images.unsplash.com/photo-1542272604-787c3835535d'
            ],
            'Jackets': [
                'https://images.unsplash.com/photo-1551028719-00167b16eac5',
                'https://images.unsplash.com/photo-1591047139829-d91aecb6caea',
                'https://images.unsplash.com/photo-1544022613-e87ca75a784a'
            ],
            'Dresses': [
                'https://images.unsplash.com/photo-1496747611176-843222e1e57c',
                'https://images.unsplash.com/photo-1566206091558-7f218b696731',
                'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1'
            ],
            'Skirts': [
                'https://images.unsplash.com/photo-1577900232427-18221643d986',
                'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa',
                'https://images.unsplash.com/photo-1604482827372-0a4f6c21f51f'
            ],
            'Shoes': [
                'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77',
                'https://images.unsplash.com/photo-1608256246200-53e635b5b65f',
                'https://images.unsplash.com/photo-1600269452121-4f2416e55c28'
            ],
            'Boots': [
                'https://images.unsplash.com/photo-1608236415053-3691127ac4d4',
                'https://images.unsplash.com/photo-1605812860427-4024433a70fd',
                'https://images.unsplash.com/photo-1608256246200-53e635b5b65f'
            ],
            'Sneakers': [
                'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a',
                'https://images.unsplash.com/photo-1607522370275-f14206abe5d3',
                'https://images.unsplash.com/photo-1552346154-21d32810aba3'
            ],
            'Watches': [
                'https://images.unsplash.com/photo-1524592094714-0f0654e20314',
                'https://images.unsplash.com/photo-1542496658-e33a6d0d50f6',
                'https://images.unsplash.com/photo-1622434641406-a158123450f9'
            ],
            'Jewelry': [
                'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338',
                'https://images.unsplash.com/photo-1573408301185-9146fe634ad0',
                'https://images.unsplash.com/photo-1535632787350-4e68ef0ac584'
            ],
            'Hats': [
                'https://images.unsplash.com/photo-1514327605112-b887c0e61c0a',
                'https://images.unsplash.com/photo-1521369909029-2afed882baee',
                'https://images.unsplash.com/photo-1556306535-0f09a537f0a3'
            ],
            'Belts': [
                'https://images.unsplash.com/photo-1556015048-4d3aa10df74c',
                'https://images.unsplash.com/photo-1620065495551-d7724869e465',
                'https://images.unsplash.com/photo-1576566588028-4147f3842f27'
            ]
        }
        
        # Create parent categories
        for i in range(parent_count):
            category_type = random.choice(['Men', 'Women', 'Kids', 'Accessories', 'Footwear', 'Sports', 'Formal', 'Casual'])
            name = f"{category_type} {fake.word().capitalize()}"
            
            # Get image for this category type
            image_url = None
            if category_type in category_images and category_images[category_type]:
                image_url = random.choice(category_images[category_type])
            
            category = Category.objects.create(
                name=name,
                description=fake.paragraph(nb_sentences=3),
                is_active=True
            )
            
            # Download and save image if URL is available
            if image_url:
                self._download_and_save_image(category, image_url)
            
            parent_categories.append(category)
            all_categories.append(category)
        
        # Create child categories
        for _ in range(child_count):
            parent = random.choice(parent_categories)
            
            # Determine appropriate subcategory types based on parent category
            subcategory_types = {
                'Men': ['Shirts', 'T-shirts', 'Pants', 'Jeans', 'Jackets', 'Suits'],
                'Women': ['Dresses', 'Tops', 'Skirts', 'Pants', 'Blouses', 'Jackets'],
                'Kids': ['Boys', 'Girls', 'Infants', 'Teens', 'School Wear'],
                'Accessories': ['Belts', 'Hats', 'Watches', 'Jewelry', 'Sunglasses'],
                'Footwear': ['Sneakers', 'Boots', 'Sandals', 'Formal Shoes', 'Slippers'],
                'Sports': ['Running', 'Yoga', 'Gym', 'Swimming', 'Hiking'],
                'Formal': ['Business', 'Evening', 'Wedding', 'Office'],
                'Casual': ['Street Wear', 'Beach Wear', 'Lounge Wear', 'Home Wear']
            }
            
            # Extract parent type from name
            parent_type = next((t for t in subcategory_types.keys() if t in parent.name), 'Casual')
            subcategory_type = random.choice(subcategory_types.get(parent_type, ['General']))
            
            name = f"{subcategory_type} {fake.word().capitalize()}"
            
            category = Category.objects.create(
                name=name,
                description=fake.paragraph(nb_sentences=2),
                parent=parent,
                is_active=True
            )
            
            # Find the most appropriate image based on subcategory type
            image_url = None
            # First try exact match
            if subcategory_type in child_category_images:
                image_url = random.choice(child_category_images[subcategory_type])
            # If no exact match, try partial match
            else:
                for key in child_category_images:
                    if key in subcategory_type or subcategory_type in key:
                        image_url = random.choice(child_category_images[key])
                        break
            
            # If still no match, use parent category image
            if not image_url and parent_type in category_images:
                image_url = random.choice(category_images[parent_type])
                
            # Download and save image if URL is available
            if image_url:
                self._download_and_save_image(category, image_url)
                
            all_categories.append(category)
        
        return all_categories

    def _download_and_save_image(self, model_instance, image_url):
        """Download image from URL and save it to model instance"""
        try:
            response = requests.get(image_url, stream=True, timeout=5)
            if response.status_code == 200:
                # Create a unique filename from the model name and instance ID
                model_name = model_instance.__class__.__name__.lower()
                file_name = f"{model_name}_{model_instance.id}_{uuid.uuid4().hex[:8]}.jpg"
                
                # Create a ContentFile from the response content
                image_content = ContentFile(response.content)
                
                # Save the image file to the model instance
                model_instance.image.save(file_name, image_content, save=True)
                
        except Exception as e:
            self.stdout.write(self.style.WARNING(f"Error downloading image for {model_instance}: {str(e)}"))
    
    def create_products(self, categories, count):
        """Create products and associate them with categories"""
        products = []
        
        for _ in range(count):
            # Select random leaf category (categories without children)
            leaf_categories = [c for c in categories if not c.children.exists()]
            category = random.choice(leaf_categories)
            
            # Generate base product name based on category
            product_type = self._get_product_type_by_category(category)
            product_name = f"{fake.color_name()} {product_type}"
            
            # Generate price within realistic range for clothing (20-200)
            base_price = Decimal(str(round(random.uniform(20, 200), 2)))
            cost_price = base_price * Decimal('0.6')  # 60% of selling price
            
            # Randomly apply discount to some products
            has_discount = random.random() < 0.3  # 30% chance of discount
            discount_price = base_price * Decimal(str(round(random.uniform(0.7, 0.9), 2))) if has_discount else None
            
            # Create product
            product = Product.objects.create(
                name=product_name,
                description=self._generate_product_description(product_name, category.name),
                category=category,
                price=base_price,
                discount_price=discount_price,
                rating=Decimal(str(round(random.uniform(3.0, 5.0), 1))),
                reviews_count=0,  # Will be updated later
                is_active=True,
                cost=cost_price
            )
            
            products.append(product)
        
        return products
    
    def create_product_variations_and_variants(self, product):
        """Create variations (like size, color) and variants for a product"""
        # Determine appropriate variations based on product category
        variations = []
        
        # Almost all products have color variation
        color_variation = ProductVariation.objects.create(
            product=product,
            name='Color',
            values=self._get_colors_for_product(product.name)
        )
        variations.append(color_variation)
        
        # Size variation depends on product type
        if any(word in product.name.lower() for word in ['shirt', 'jacket', 'dress', 't-shirt', 'top', 'blouse']):
            size_values = ['XS', 'S', 'M', 'L', 'XL', '2XL']
        elif any(word in product.name.lower() for word in ['shoes', 'sneakers', 'boots', 'sandals']):
            size_values = ['6', '7', '8', '9', '10', '11', '12']
        elif any(word in product.name.lower() for word in ['pants', 'jeans', 'shorts', 'skirt']):
            size_values = ['28', '30', '32', '34', '36', '38', '40']
        else:
            size_values = ['S', 'M', 'L']
        
        size_variation = ProductVariation.objects.create(
            product=product,
            name='Size',
            values=size_values
        )
        variations.append(size_variation)
        
        # Add material variation for some products
        if random.random() < 0.3:  # 30% chance
            material_variation = ProductVariation.objects.create(
                product=product,
                name='Material',
                values=['Cotton', 'Polyester', 'Wool', 'Denim', 'Leather', 'Silk', 'Linen']
            )
            variations.append(material_variation)
        
        # Create variants - combinations of variations
        self._create_product_variants(product, variations)
    
    def _create_product_variants(self, product, variations):
        """Create all possible variants from variations"""
        # Get all variation values
        variation_dict = {variation.name: variation.values for variation in variations}
        
        # Generate all combinations
        import itertools
        keys = variation_dict.keys()
        values = [variation_dict[key] for key in keys]
        
        # Limit number of variants to avoid explosion
        combinations = list(itertools.product(*values))
        selected_combinations = random.sample(
            combinations, 
            min(len(combinations), random.randint(3, 8))
        )
        
        for combo in selected_combinations:
            attributes = {key: value for key, value in zip(keys, combo)}
            
            # Variant-specific pricing (slight variations from base product price)
            price_modifier = Decimal(str(round(random.uniform(-10, 10), 2)))
            variant_price = product.price + price_modifier
            
            # Apply discount if product has discount
            variant_discount = None
            if product.discount_price:
                discount_modifier = price_modifier * Decimal('0.8')  # Slightly less discount on modified price
                variant_discount = product.discount_price + discount_modifier
            
            # Create variant
            ProductVariant.objects.create(
                product=product,
                attributes=attributes,
                # SKU will be auto-generated in save() method
                price=variant_price,
                discount_price=variant_discount,
                stock=random.randint(5, 50)
            )
    
    def create_product_images(self, product, count):
        """Create multiple images for a product"""
        for i in range(count):
            is_primary = (i == 0)  # First image is primary
            
            # Get the URL
            image_url = self._get_random_image_url(product_name=product.name)
            
            # Download the image and create a Django file object
            try:
                response = requests.get(image_url, stream=True, timeout=5)
                if response.status_code == 200:
                    # Create a unique filename
                    file_name = f"{product.name.replace(' ', '_').lower()}_{i}.jpg"
                    
                    # Create a ContentFile from the response content
                    image_content = ContentFile(response.content)
                    
                    # Create the ProductImage object and save the file
                    product_image = ProductImage(
                        product=product,
                        alt_text=f"{product.name} - View {i+1}",
                        order=i,
                        is_primary=is_primary
                    )
                    
                    # Save the image file to the image field
                    product_image.image.save(file_name, image_content, save=False)
                    product_image.save()
                    
            except Exception as e:
                self.stdout.write(self.style.WARNING(f"Error downloading image for {product.name}: {str(e)}"))
                
    def _get_product_type_by_category(self, category):
        """Return appropriate product type based on category name"""
        category_name = category.name.lower()
        parent_name = category.parent.name.lower() if category.parent else ""
        
        if any(word in category_name for word in ['shirt', 'top', 'blouse']):
            return random.choice(['Shirt', 'Top', 'Blouse', 'T-Shirt'])
        elif 'dress' in category_name:
            return random.choice(['Dress', 'Gown', 'Sundress'])
        elif any(word in category_name for word in ['pants', 'jeans', 'trousers']):
            return random.choice(['Pants', 'Jeans', 'Trousers', 'Slacks'])
        elif 'shoe' in category_name or 'footwear' in parent_name:
            return random.choice(['Sneakers', 'Shoes', 'Boots', 'Loafers', 'Sandals'])
        elif 'jacket' in category_name:
            return random.choice(['Jacket', 'Coat', 'Blazer'])
        elif 'accessory' in category_name or 'accessories' in parent_name:
            return random.choice(['Watch', 'Belt', 'Scarf', 'Hat', 'Sunglasses', 'Jewelry'])
        else:
            # Generic clothing types
            return random.choice([
                'Shirt', 'Pants', 'Jacket', 'Dress', 'Skirt', 'Sweater', 
                'Hoodie', 'Socks', 'Underwear', 'Sleepwear', 'Activewear'
            ])
    
    def _get_colors_for_product(self, product_name):
        """Generate appropriate colors for a product"""
        basic_colors = ['Black', 'White', 'Navy', 'Gray', 'Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Pink']
        fashion_colors = ['Burgundy', 'Teal', 'Olive', 'Mustard', 'Coral', 'Lavender', 'Mint', 'Khaki', 'Beige']
        
        # Extract existing color from product name if present
        product_color = next((c for c in basic_colors + fashion_colors 
                             if c.lower() in product_name.lower()), None)
        
        # Select colors based on product type
        if 'formal' in product_name.lower() or 'business' in product_name.lower():
            colors = ['Black', 'Navy', 'Gray', 'White', 'Burgundy', 'Beige']
        elif 'casual' in product_name.lower():
            colors = basic_colors + fashion_colors
        else:
            colors = random.sample(basic_colors + fashion_colors, random.randint(3, 8))
        
        # Always include the color in the product name if it exists
        if product_color and product_color not in colors:
            colors = [product_color] + colors
            
        return colors[:random.randint(3, 6)]  # Limit to 3-6 color options
                    
    
                    
    def _generate_product_description(self, product_name, category_name):
        """Generate realistic product descriptions"""
        material = random.choice(['cotton', 'polyester', 'wool', 'silk', 'linen', 'leather', 'denim'])
        feature = random.choice(['comfortable', 'durable', 'stylish', 'versatile', 'lightweight', 'premium'])
        occasion = random.choice(['casual', 'formal', 'everyday', 'special occasions', 'work', 'outdoor'])
        
        desc_parts = [
            f"High-quality {product_name.lower()} made with {material} material.",
            f"This {feature} {category_name.lower()} is perfect for {occasion} wear.",
            f"Features a modern design with attention to detail.",
            fake.paragraph(nb_sentences=3),
            f"Easy to care for and maintain.\n\n",
            f"Material: {material.capitalize()}\n",
            f"Style: {random.choice(['Classic', 'Modern', 'Casual', 'Formal', 'Vintage'])}\n",
            f"Pattern: {random.choice(['Solid', 'Striped', 'Printed', 'Checked', 'Plain'])}"
        ]
        
        return "\n".join(desc_parts)
    
    def _get_random_image_url(self, category_name=None, product_name=None):
        """
        Returns a random image URL based on category or product name from Unsplash.
        """
        import random
        import requests
        
        # Normalize inputs for better matching
        search_term = ''
        if category_name:
            search_term = category_name.lower()
        elif product_name:
            search_term = product_name.lower()
        else:
            search_term = "fashion"
        
        # Define comprehensive image collections by type
        image_collections = {
            'men': [
                'https://images.unsplash.com/photo-1617137968427-85924c800a22',
                'https://images.unsplash.com/photo-1576566588028-4147f3842f27',
                'https://images.unsplash.com/photo-1553143820-6bb68bc34679',
                'https://images.unsplash.com/photo-1480455624313-e29b44bbfde1',
                'https://images.unsplash.com/photo-1542327897-4141b355e20e',
                'https://images.unsplash.com/photo-1610652492500-ded49ceeb378',
                'https://images.unsplash.com/photo-1516257984-b1b4d707412e',
                'https://images.unsplash.com/photo-1550246140-29f40b909e5a',
                'https://images.unsplash.com/photo-1507680434567-5739c80be1ac',
                'https://images.unsplash.com/photo-1622519407650-3df9883f76a5',
            ],
            'women': [
                'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5',
                'https://images.unsplash.com/photo-1581044777550-4cfa60707c03',
                'https://images.unsplash.com/photo-1554412933-514a83d2f3c8',
                'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b',
                'https://images.unsplash.com/photo-1485968579580-b6d095142e6e',
                'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f',
                'https://images.unsplash.com/photo-1589465885857-44edb59bbff2',
                'https://images.unsplash.com/photo-1563178406-4cdc2923acbc',
                'https://images.unsplash.com/photo-1496747611176-843222e1e57c',
                'https://images.unsplash.com/photo-1566206091558-7f218b696731',
            ],
            'pants': [
                'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80',
                'https://images.unsplash.com/photo-1542574271-7f3b92e6c821',
                'https://images.unsplash.com/photo-1593795899768-947c4929449d',
                'https://images.unsplash.com/photo-1506629082955-511b1aa562c8',
                'https://images.unsplash.com/photo-1541099649105-f69ad21f3246',
                'https://images.unsplash.com/photo-1565084888279-aca607ecce0c'
            ],
            'kids': [
                'https://images.unsplash.com/photo-1543854704-783aaadf1971',
                'https://images.unsplash.com/photo-1518831959646-742c3a14ebf7',
                'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4',
                'https://images.unsplash.com/photo-1522771930-78848d9293e8',
                'https://images.unsplash.com/photo-1503919545889-aef636e10ad4',
                'https://images.unsplash.com/photo-1524055037154-18a6a7306e0e',
                'https://images.unsplash.com/photo-1519457431-44ccd64a579b',
                'https://images.unsplash.com/photo-1519238359922-989348752efb',
                'https://images.unsplash.com/photo-1607453998774-d533f65dac99',
                'https://images.unsplash.com/photo-1519238360324-0a398e5affa6',
            ],
            'accessories': [
                'https://images.unsplash.com/photo-1556306535-0f09a537f0a3',
                'https://images.unsplash.com/photo-1588444650733-d0f79a129f2f',
                'https://images.unsplash.com/photo-1574025305631-a6333f405f7f',
                'https://images.unsplash.com/photo-1611085583191-a3b181a88401',
                'https://images.unsplash.com/photo-1582552938357-32b906df40cb',
                'https://images.unsplash.com/photo-1590548784585-643d2b9f2925',
                'https://images.unsplash.com/photo-1635767798638-3e25273a8236',
                'https://images.unsplash.com/photo-1583292650898-7d22cd27ca6f',
                'https://images.unsplash.com/photo-1576053139778-7e32f2ae3cfd',
                'https://images.unsplash.com/photo-1635805737707-575885ab0820',
            ],
            'footwear': [
                'https://images.unsplash.com/photo-1560343090-f0409e92791a',
                'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
                'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a',
                'https://images.unsplash.com/photo-1549298916-b41d501d3772',
                'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77',
                'https://images.unsplash.com/photo-1608256246200-53e635b5b65f',
                'https://images.unsplash.com/photo-1600269452121-4f2416e55c28',
                'https://images.unsplash.com/photo-1562183241-b937e95585b6',
                'https://images.unsplash.com/photo-1604001307862-2d953b875079',
                'https://images.unsplash.com/photo-1543163521-1bf539c55dd2',
            ],
            'sports': [
                'https://images.unsplash.com/photo-1581077262877-9cc51c13f5bc',
                'https://images.unsplash.com/photo-1575537302964-96cd47c06b1b',
                'https://images.unsplash.com/photo-1554068865-24cecd4e34b8',
                'https://images.unsplash.com/photo-1516826897695-ec3ecd1d9914',
                'https://images.unsplash.com/photo-1606196480615-c5204c6d775a',
                'https://images.unsplash.com/photo-1621689689603-46a857bc0ee4',
                'https://images.unsplash.com/photo-1587280501635-68a0e82cd5ff',
                'https://images.unsplash.com/photo-1594381898411-846e7d193883',
                'https://images.unsplash.com/photo-1517164850305-99a3e65bb47e',
                'https://images.unsplash.com/photo-1587502536900-baf0c55a3f74',
            ],
            'casual': [
                'https://images.unsplash.com/photo-1589465885857-44edb59bbff2',
                'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f',
                'https://images.unsplash.com/photo-1581044777550-4cfa60707c03',
                'https://images.unsplash.com/photo-1583245877800-a4ddf4578a60',
                'https://images.unsplash.com/photo-1609505848912-b7c3b8b4beda',
                'https://images.unsplash.com/photo-1560243563-062bfc001d68',
                'https://images.unsplash.com/photo-1617075801831-014d0e596ce0',
                'https://images.unsplash.com/photo-1551028719-00167b16eac5',
                'https://images.unsplash.com/photo-1602810319428-019690571b5b',
                'https://images.unsplash.com/photo-1608234808654-2a8875faa7fd',
            ],
            'formal': [
                'https://images.unsplash.com/photo-1507679799987-c73779587ccf',
                'https://images.unsplash.com/photo-1553240799-37bbf573dcd3',
                'https://images.unsplash.com/photo-1580657018950-c7f7d6a6d990',
                'https://images.unsplash.com/photo-1593030761757-71fae45fa0e7',
                'https://images.unsplash.com/photo-1514222709107-a180c68d72b4',
                'https://images.unsplash.com/photo-1553484604-9f524520c793',
                'https://images.unsplash.com/photo-1597843787343-3d9577cf8a72',
                'https://images.unsplash.com/photo-1621072156002-e2fccdc0b176',
                'https://images.unsplash.com/photo-1517502474097-f9b30659dadb',
                'https://images.unsplash.com/photo-1596902852634-9c0a6ea33969',
            ],
            'shirts': [
                'https://images.unsplash.com/photo-1620012253295-c15cc3e65df4',
                'https://images.unsplash.com/photo-1626497764746-6dc36546b388',
                'https://images.unsplash.com/photo-1604695573706-b3efe27c4642',
                'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf',
                'https://images.unsplash.com/photo-1596755094514-f87e34085b2c',
                'https://images.unsplash.com/photo-1594938298603-c8148c4dae35',
                'https://images.unsplash.com/photo-1598032895397-b9472444bf93',
                'https://images.unsplash.com/photo-1588359348347-9bc6cbbb689e',
                'https://images.unsplash.com/photo-1607345366928-199ea26cfe3e',
                'https://images.unsplash.com/photo-1603252109303-2751441dd157',
            ]
        }
        
        # Add more categories for child categories to ensure coverage
        child_categories = {
            'dresses': image_collections['women'],
            'tops': image_collections['women'],
            'skirts': image_collections['women'],
            'pants': image_collections['men'],
            'jeans': image_collections['men'],
            'jackets': image_collections['men'],
            'suits': image_collections['formal'],
            'belts': image_collections['accessories'],
            'hats': image_collections['accessories'],
            'scarves': image_collections['accessories'],
            'gloves': image_collections['accessories'],
            'watches': image_collections['accessories'],
            'sneakers': image_collections['footwear'],
            'boots': image_collections['footwear'],
            'sandals': image_collections['footwear'],
            'running': image_collections['sports'],
            'yoga': image_collections['sports'],
            'gym': image_collections['sports'],
            'swimming': image_collections['sports'],
        }
        
        fallback_images = [
        'https://images.unsplash.com/photo-1523381210434-271e8be1f52b',  # Generic clothing rack
        'https://images.unsplash.com/photo-1542060748-10c28b62716f',  # Shopping bags
        'https://images.unsplash.com/photo-1445205170230-053b83016050',  # Fashion display
        'https://images.unsplash.com/photo-1441986300917-64674bd600d8',  # Store interior
        'https://images.unsplash.com/photo-1607082349566-187342175e2f',  # Simple background
    ]
        
        # Get a candidate image URL using the existing logic
        candidate_url = None
        
        # Find the most appropriate category based on the search term
        for category, urls in image_collections.items():
            if category in search_term.lower():
                candidate_url = random.choice(urls)
                break
        
        # If no specific match found, use a general category based on parent types
        if not candidate_url:
            for parent_type in ['men', 'women', 'kids', 'accessories', 'footwear', 'sports', 'casual', 'formal']:
                if parent_type in search_term.lower():
                    candidate_url = random.choice(image_collections[parent_type])
                    break
        
        # Default to a random fashion image if no match found
        if not candidate_url:
            all_images = []
            for image_list in image_collections.values():
                all_images.extend(image_list)
            
            candidate_url = random.choice(all_images)
        
        # Verify the image is reachable with a short timeout
        try:
            # Using a HEAD request to minimize bandwidth
            response = requests.head(candidate_url, timeout=3)
            if response.status_code == 200:
                return candidate_url
        except (requests.RequestException, Exception):
            # If any exception occurs, fall back to guaranteed images
            pass
        
        # If the image is not reachable, use one of the fallback images
        return random.choice(fallback_images)
    
    def _get_random_avatar_url(self):
        """Return a random avatar URL for user profiles"""
        gender = random.choice(['men', 'women'])
        return f"https://randomuser.me/api/portraits/{gender}/{random.randint(1, 99)}.jpg"
    
    def create_flash_sales(self, count=5):
        """Create flash sales with items"""
        self.stdout.write('Creating flash sales...')
        flash_sales = []
        products = list(Product.objects.all())
        
        # Get current time for reference
        now = timezone.now()
        
        for i in range(count):
            # Create different types of flash sales
            sale_types = [
                {
                    'title': 'Weekend Flash Sale',
                    'description': 'Grab amazing deals this weekend! Limited time only.',
                    'discount': random.randint(20, 40),
                    'start_offset': random.randint(-10, 20),  # Days from now
                    'duration': random.randint(2, 3)  # Days
                },
                {
                    'title': 'Midnight Madness',
                    'description': 'Shop till you drop with these exclusive midnight offers!',
                    'discount': random.randint(30, 50),
                    'start_offset': random.randint(-5, 15),
                    'duration': 1
                },
                {
                    'title': 'Seasonal Clearance',
                    'description': 'End of season sale with massive discounts on all items.',
                    'discount': random.randint(40, 70),
                    'start_offset': random.randint(-15, 10),
                    'duration': random.randint(5, 10)
                },
                {
                    'title': 'Members Only Sale',
                    'description': 'Exclusive deals for our loyal members.',
                    'discount': random.randint(25, 45),
                    'start_offset': random.randint(-8, 12),
                    'duration': random.randint(3, 7),
                    'is_public': False
                },
                {
                    'title': '24-Hour Deals',
                    'description': 'Blink and you\'ll miss these incredible 24-hour deals!',
                    'discount': random.randint(15, 35),
                    'start_offset': random.randint(-2, 25),
                    'duration': 1
                }
            ]
            
            sale_config = sale_types[i % len(sale_types)]
            
            # Calculate start and end dates
            start_date = now + datetime.timedelta(days=sale_config['start_offset'])
            end_date = start_date + datetime.timedelta(days=sale_config['duration'])
            
            # Create some sales in the past, present, and future for testing
            flash_sale = FlashSale.objects.create(
                title=f"{sale_config['title']} #{i+1}",
                description=sale_config['description'],
                discount_percentage=sale_config['discount'],
                start_date=start_date,
                end_date=end_date,
                is_active=True,
                purchase_limit=random.choice([None, 3, 5, 10]),
                minimum_order_value=random.choice([None, Decimal('50.00'), Decimal('100.00')]),
                is_public=sale_config.get('is_public', True),
                allow_stacking_discounts=random.random() < 0.3  # 30% chance
            )
            
            # Add image to flash sale
            flash_sale_images = [
                'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da',
                'https://images.unsplash.com/photo-1550745165-9bc0b252726f',
                'https://images.unsplash.com/photo-1586892478025-2b5472316bf4',
                'https://images.unsplash.com/photo-1626285861696-9f0bf5a49c6d',
                'https://images.unsplash.com/photo-1612599316791-451087f7944f'
            ]
            self._download_and_save_image(flash_sale, random.choice(flash_sale_images))
            
            # Add metrics for past sales
            if end_date < now:
                flash_sale.total_revenue = Decimal(str(random.randint(5000, 50000)))
                flash_sale.revenue_increase = Decimal(str(random.randint(10, 150)))
                flash_sale.total_orders = random.randint(50, 500)
                flash_sale.order_increase = Decimal(str(random.randint(10, 200)))
                flash_sale.units_sold = random.randint(100, 1000)
                flash_sale.units_sold_increase = Decimal(str(random.randint(10, 100)))
                flash_sale.conversion_rate = Decimal(str(random.randint(10, 50)))
                flash_sale.conversion_rate_increase = Decimal(str(random.randint(-20, 100)))
                flash_sale.save()
            
            # Add 5-15 products to each flash sale
            num_products = random.randint(5, 15)
            selected_products = random.sample(products, min(num_products, len(products)))
            
            for product in selected_products:
                # Some products get special discount overrides
                override = None
                if random.random() < 0.3:  # 30% chance
                    override = random.randint(10, 80)
                    
                FlashSaleItem.objects.create(
                    flash_sale=flash_sale,
                    product=product,
                    override_discount=override,
                    stock_limit=random.choice([None, random.randint(10, 100)]),
                    item_purchase_limit=random.choice([None, 1, 2, 3, 5]),
                    units_sold=random.randint(0, 50) if start_date < now else 0,
                    revenue=Decimal(str(random.randint(0, 5000))) if start_date < now else 0
                )
            
            flash_sales.append(flash_sale)
        
        return flash_sales

    def create_banners(self, count=8):
        """Create promotional banners for the homepage"""
        self.stdout.write('Creating banners...')
        banners = []
        
        # Get flash sales to link some banners to them
        flash_sales = list(FlashSale.objects.all())
        
        # Banner configurations
        banner_configs = [
            {
                'title': 'New Arrivals',
                'subtitle': 'Check out our latest collection',
                'link_text': 'Shop Now'
            },
            {
                'title': 'Summer Collection',
                'subtitle': 'Beat the heat with our cool summer wear',
                'link_text': 'Explore'
            },
            {
                'title': 'Winter Essentials',
                'subtitle': 'Stay warm with our winter collection',
                'link_text': 'Stay Warm'
            },
            {
                'title': 'Accessories Sale',
                'subtitle': 'Up to 50% off on all accessories',
                'link_text': 'Shop Sale'
            },
            {
                'title': 'Exclusive Footwear',
                'subtitle': 'Step out in style with our premium footwear',
                'link_text': 'Step In'
            },
            {
                'title': 'Kids Collection',
                'subtitle': 'Adorable outfits for your little ones',
                'link_text': 'Shop Kids'
            },
            {
                'title': 'Formal Wear',
                'subtitle': 'Dress to impress with our formal collection',
                'link_text': 'Look Sharp'
            },
            {
                'title': 'Sports & Fitness',
                'subtitle': 'Performance gear for your active lifestyle',
                'link_text': 'Get Active'
            }
        ]
        
        # Banner images from Unsplash
        banner_images = [
            'https://images.unsplash.com/photo-1483985988355-763728e1935b',
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d',
            'https://images.unsplash.com/photo-1445205170230-053b83016050',
            'https://images.unsplash.com/photo-1612423284934-2850a4ea6b0f',
            'https://images.unsplash.com/photo-1551488831-00ddcb6c6bd3',
            'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da',
            'https://images.unsplash.com/photo-1487222477894-8943e31ef7b2',
            'https://images.unsplash.com/photo-1526628953301-3e589a6a8b74'
        ]
        
        # Create banners
        for i in range(count):
            banner_config = banner_configs[i % len(banner_configs)]
            
            # Determine if banner should be linked to a flash sale
            flash_sale = None
            if flash_sales and random.random() < 0.4:  # 40% chance
                flash_sale = random.choice(flash_sales)
            
            # Create banner
            banner = Banner.objects.create(
                title=banner_config['title'],
                subtitle=banner_config['subtitle'],
                link_text=banner_config['link_text'],
                link_url=f'/collections/{slugify(banner_config["title"])}/',
                is_active=random.random() < 0.8,  # 80% active
                display_order=i,
                flash_sale=flash_sale
            )
            
            # Add date range to some banners
            if random.random() < 0.6:  # 60% chance
                now = timezone.now()
                days_offset = random.randint(-10, 20)
                banner.start_date = now + datetime.timedelta(days=days_offset)
                banner.end_date = banner.start_date + datetime.timedelta(days=random.randint(10, 30))
                banner.save()
            
            # Add image to banner
            self._download_and_save_image(banner, banner_images[i % len(banner_images)])
            
            banners.append(banner)
        
        return banners
    
    def _generate_review_text(self, rating, product_name):
        """Generate realistic review text based on rating"""
        if rating >= 4:
            sentiments = [
                f"Love my new {product_name}! Excellent quality and exactly as described.",
                f"Very satisfied with this purchase. The {product_name} exceeded my expectations.",
                f"Great product! Comfortable and stylish. Would definitely recommend.",
                f"Perfect fit and great material. Will buy again from this store."
            ]
        elif rating == 3:
            sentiments = [
                f"Decent {product_name}, but not exceptional. Good for the price though.",
                f"Average quality. Not bad, but not great either.",
                f"Got what I expected. Nothing more, nothing less.",
                f"It's okay. Serves its purpose but wouldn't buy again."
            ]
        else:
            sentiments = [
                f"Disappointed with this {product_name}. Quality is lower than expected.",
                f"Not as advertised. The product looks different from the photos.",
                f"Poor quality for the price. Would not recommend.",
                f"Had to return because it didn't fit well. Sizing is off."
            ]
        
        return random.choice(sentiments) + " " + fake.paragraph(nb_sentences=random.randint(1, 3))
    
    
                    
    def create_reviews(self, users, products, count):
        """Create reviews for products"""
        for _ in range(count):
            user = random.choice(users)
            product = random.choice(products)
            
            # Check if this user has already reviewed this product
            if Review.objects.filter(user=user, product=product).exists():
                continue
            
            # Create review with weighted ratings (more positive than negative)
            weights = [1, 2, 3, 4, 4, 5, 5, 5, 5, 5]  # Skewed toward higher ratings
            rating = random.choice(weights)
            
            Review.objects.create(
                user=user,
                product=product,
                rating=rating,
                comment=self._generate_review_text(rating, product.name),
                created_at=timezone.now() - datetime.timedelta(days=random.randint(1, 90))
            )
        
        # Update product ratings and review counts
        for product in products:
            reviews = Review.objects.filter(product=product)
            if reviews.exists():
                avg_rating = sum(review.rating for review in reviews) / reviews.count()
                product.rating = Decimal(str(round(avg_rating, 1)))
                product.reviews_count = reviews.count()
                product.save(update_fields=['rating', 'reviews_count'])