from rest_framework.response import Response
from rest_framework import status
import logging

logger = logging.getLogger(__name__) 

class BaseService:
    """Base service class with common functionality"""
    def success_response(self, data = None, message = None, status_code = status.HTTP_200_OK):
        """Standard success response format"""
        response = {}
        if message:
            response['message'] = message
        if data is not None:
            if isinstance(data, dict):
                response.update(data)
            else:
                response['data'] =data
        return Response(response, status = status_code)
    
    def error_response(self, error = None, details = None, status_code = status.HTTP_400_BAD_REQUEST):
        """standard error response format"""
        response = {'success': False}
        if error:
            response['error'] = error
        if details:
            response['details'] = details
            
        return Response(response, status  = status_code)
    
    def log_exception(self, e, message = "An error occurred"):
        """Standard exception logging"""
        logger.error(f"{message}: {str(e)}", exc_info=True)