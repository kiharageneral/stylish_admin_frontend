import json
from decimal import Decimal
from datetime import datetime
import uuid

class CustomJSONEncoder(json.JSONEncoder):
    """Custom JSON encoder to handle special data types from Django models, like Decimal, datetime and UUID"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return str(obj)
        if isinstance(obj, datetime):
            return obj.isoformat()
        if isinstance(obj, uuid.UUID):
            return str(obj)
        
        return super().default(obj)
        