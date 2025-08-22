import os
import base64
from io import BytesIO
from django.core.files.uploadedfile import InMemoryUploadedFile, UploadedFile
from django.core.files.base import ContentFile
from rest_framework.response import Response
from rest_framework import status
from ecommerce.models import ProductImage, Product
from admin_dashboard.product_serializers import ProductImageSerializer

class ImageService:
    def extract_files_from_request(self, request):
        """Extract image files from both multipart and base64 data"""
        image_files = []
        primary_image_index = None
        
        # Get primary image index if provided
        if hasattr(request.data, 'get'):
            primary_image_index = request.data.get('primary_image_index')
            if primary_image_index and str(primary_image_index).isdigit():
                primary_image_index = int(primary_image_index)
                
        if not image_files and hasattr(request, 'FILES'):
            images_field = request.FILES.getlist('images')
            for i, file_obj in enumerate(images_field):
                try:
                    is_primary = primary_image_index is not None and i == primary_image_index
                    
                    file_name = file_obj.name
                    
                    base_name = os.path.splitext(file_name)[0]
                    
                    alt_text = base_name.replace('_', '')
                    
                    image_files.append({
                        'file': file_obj, 
                        'alt_text': alt_text, 
                        'order': i, 
                        'is_primary': is_primary, 
                        'name': file_name
                    })
                    
                except Exception as e:
                    pass
                
        # Sort by order/index
        image_files.sort(key = lambda x:x['order'])
        
        if image_files and primary_image_index is None:
            image_files[0]['is_primary'] = True
            
        return image_files
    
    def process_images(self, product, image_data_list):
        """Process and save uploaded image files"""
        created_images = []
        
        for i, image_data in enumerate(image_data_list):
            try:
                if 'file' in image_data and image_data['file']:
                    file_obj = image_data['file']
                    
                    image = ProductImage.objects.create(
                        product=product, 
                        image = file_obj, 
                        alt_text = image_data.get('alt_text', image_data.get('name', product.name)), 
                        order = image_data.get('order', i), 
                        is_primary = image_data.get('is_primary', False)
                    )
                    
                    created_images.append(image)
                else:
                    continue
                
            except Exception as e:
                import traceback
                print(traceback.format_exc())
        # Ensure at least one image is primary if we have images
        if created_images and not any(img.is_primary for img in created_images):
            created_images[0].is_primary = True
            created_images[0].save(update_fields = ['is_primary'])
            
        return created_images
    
    def manage_product_images(self, product_id, request):
        """Add or update product images with file upload support"""
        try:
            product = Product.objects.get(id = product_id) 
        except Product.DoesNotExist:
            return Response(
                {'error': 'Product not found'}, 
                status = status.HTTP_404_NOT_FOUND
            )   
            
        # Get images from various sources
        image_data_list = self.extract_files_from_request(request)
        
        if not image_data_list:
            return Response(
                {'error': 'No valid image files provided. Ensure images uploaded correctly.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            created_images = self.process_images(product, image_data_list)
            
            # Get request for proper URL generation in serializer
            context = {'request': request} if request else {}
            
            return Response({
                'message': f'Successfully added {len(created_images)} images', 
                'images': ProductImageSerializer(created_images, many = True, context = context).data
            })
            
        except Exception as e:
            import traceback
            print(f"Error in manage_product_images: str(e)")
            print(traceback.format_exc())
            return Response({
                'error': 'Failed to process images', 
                'detail': str(e)
            }, status= status.HTTP_400_BAD_REQUEST)
            
    def set_primary_image(self, product_id, image_id):
        """Set a specific image as the primary image"""
        try:
            product = Product.objects.get(id = product_id)
            image = ProductImage.objects.get(id=image_id, product=product)
            
            # Clear existing primary flags
            ProductImage.objects.filter(product = product, is_primary = True).update(is_primary = False)
            
            # Set this images as primary
            image.is_primary = True
            image.save(update_fields= ['is_primary'])
            
            return Response({
                'message': 'Primary image updated successfully',
                'image': ProductImageSerializer(image).data
            })
            
            
        except Product.DoesNotExist:
            return Response(
                {'error': 'Product not found'}, 
                status= status.HTTP_404_NOT_FOUND
            )
            
        except ProductImage.DoesNotExist:
            return Response(
                {'error': 'Image not found'}, 
                status= status.HTTP_404_NOT_FOUND
            )
    
    def delete_product_image(self, product_id, image_id):
        """Delete a product image with improved primary image handling"""
        try:
            product = Product.objects.get(id = product_id)
            image = ProductImage.objects.get(id = image_id, product = product)
            
            was_primary = image.is_primary
            image.delete()
            
            # if deleted image was primary , update product's primary image 
            if was_primary:
                next_image = ProductImage.objects.filter(product = product).first()
                if next_image:
                    next_image.is_primary=True
                    next_image.save(update_fields=['is_primary'])
                    
            return Response({'message': 'Image deleted successfully'})
        except Product.DoesNotExist:
            return Response(
                {'error': 'Product not found'}, 
                status= status.HTTP_404_NOT_FOUND
            )
            
        except ProductImage.DoesNotExist:
            return Response(
                {'error': 'Image not found'}, 
                status= status.HTTP_404_NOT_FOUND
            )
    
    def reorder_images(self, product_id, order_data):
        """Reorder product images"""
        try:
            product = Product.objects.get(id = product_id)
            
            if not isinstance(order_data, list):
                return Response(
                    {'error': 'Expected array of image order data'}, 
                    status= status.HTTP_400_BAD_REQUEST
                )
                
            for item in order_data:
                if 'id' not in item or 'order' not in item:
                    continue
                
                try:
                    image = ProductImage.objects.get(id = item['id'], product = product)
                    image.order = item['order']
                    image.save(update_fields=['order'])
                except ProductImage.DoesNotExist:
                    pass
                
            # Return updated image list
            images = ProductImage.objects.filter(product = product).order_by('order')
            return Response({
                'message': 'Images reordered successfully', 
                'images': ProductImageSerializer(images, many = True).data
            })
        
        except Product.DoesNotExist:
            return Response(
                {'error': 'Product not found'}, 
                status= status.HTTP_404_NOT_FOUND
            )
                    