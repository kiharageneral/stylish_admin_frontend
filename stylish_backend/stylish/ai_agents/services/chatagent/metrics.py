import time
from typing import Dict, Any
from dataclasses import dataclass, field
from collections import defaultdict, deque

@dataclass
class MetricsCollector:
    request_counts: Dict[str, int] = field(default_factory=lambda:defaultdict(int))
    response_times:Dict[str, deque] = field(default_factory=lambda:defaultdict(lambda: deque(maxlen=100)))
    error_counts : Dict[str, int] = field(default_factory=lambda:defaultdict(int))
    
    def record_request(self, endpoint:str):
        self.request_counts[endpoint] +=1
        
    def record_response_time(self, endpoint:str, duration: float):
        self.response_times[endpoint].append(duration)
        
    def record_error(self, endpoint:str):
        self.error_counts[endpoint] += 1
    def get_metrics(self) -> Dict[str, Any]:
        metrics = {}
        
        for endpoint in self.request_counts:
            response_times = list(self.response_times[endpoint])
            avg_response_time = sum(response_times) / len(response_times) if response_times else 0
            
            metrics[endpoint] = {
                'total_requests': self.request_counts[endpoint], 
                'total_errors': self.error_counts[endpoint], 
                'avg_response_time': avg_response_time, 
                'error_rate': self.error_counts[endpoint]/ self.request_counts[endpoint] if self.request_counts[endpoint] > 0 else 0
            }
            
        return metrics
    
# Global metrics collector
metrics_collector = MetricsCollector()
    