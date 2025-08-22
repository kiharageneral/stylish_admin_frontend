import logging
from django.utils import timezone
from .redis_manager import redis_manager

logger = logging.getLogger(__name__)


class AnalyticsTracker:
    """Analytics tracker with proper redis connection management"""
    def __init__(self):
        self.redis_manager = redis_manager
        self._redis_available = True
        
    async def track_query(self, context, intent, execution_time:float):
        """Track query analytics with fallback handling"""
        if self._redis_available:
            try:
                await self._track_redis(context, intent, execution_time)
                return 
            except Exception as e:
                logger.warning(f"Redis analytics tracking failed : {str(e)}")
                self._redis_available = False
                
        self._track_fallback(context, intent, execution_time)
        
    async def _track_redis(self, context, intent, execution_time: float):
        """Track analytics in Redis"""
        async with self.redis_manager.get_connection() as redis_client:
            date_str = timezone.now().strftime('%Y-%m-%d')
            hour_str = timezone.now().strftime('%Y-%m-%d-%H')
            
            
            pipe = redis_client.pipeline(transaction=True)
            
            try:
                # Daily metrics
                pipe.incr(f"chat_analytics:queries:total:{date_str}")
                pipe.incr(f"chat_analytics:queries:intent:{intent.value}:{date_str}")
                pipe.incr(f"chat_analytics:users:active:{date_str}")
                
                # Hourly metrics
                pipe.incr(f"chat_analytics:queries:hourly:{hour_str}")
                
                # Execution time tracking
                pipe.lpush("chat_analytics:execution_times", execution_time)
                pipe.ltrim("chat_analytics:execution_times", 0, 999)
                
                # user-specific metrics
                pipe.incr(f"chat_analytics:user_queries:{context.user_id}:{date_str}")
                
                
                # set expiration for daily keys (30 days)
                
                pipe.expire(f"chat_analytics:queries:total:{date_str}", 30*24*3600)
                pipe.expire(f"chat_analytics:queries:intent:{intent.value}:{date_str}", 30*24*3600)
                pipe.expire(f"chat_analytics:queries:hourly:{hour_str}",7 * 24 *3600) 
                pipe.expire(f"chat_analytics:users:active:{date_str}", 30*24*3600)
                
                pipe.expire(f"chat_analytics:user_queries:{context.user_id}:{date_str}", 30*24*3600)
                
                
                # Execute all operations
                await pipe.execute()
                
                self._redis_available = True
                
            except Exception as e:
                await pipe.reset()
                raise e  
            
    def _track_fallback(self, context, intent, execution_time: float):
        """Fallback analytics tracking via logging"""
        logger.info(
            f"Analytics: user_id = {context.user_id}, intent = {intent.value}, execution_time = {execution_time:.3f}s, session_id = {context.session_id}"
        )  
        
    async def get_analytics_summary(self, days: int = 7)-> dict:
        """Get analytics summary for the last N days"""
        if not self._redis_available:
            return {
                'error': 'Analytics unavailabel - Redis connection failed', 
                'fallback_message': 'Check application logs for basic metrics'
            }  
            
        try:
            async with self.redis_manager.get_connection() as redis_client:
                summary = {}
                
                dates = []
                
                for i in range(days):
                    date = (timezone.now() - timezone.timedelta(days = i)).strftime('%Y-%m-%d')
                    dates.append(date)
                    
                pipe = redis_client.pipeline()
                
                for date in dates:
                    pipe.get(f"chat_analytics:queries:total:{date}")
                    
                pipe.lrange("chat_analytics:execution_times", 0, 99) 
                
                results = await pipe.execute()
                
                
                # Process daily query counts
                daily_queries = []
                for i, date in enumerate(dates):
                    count = int(results[i] or 0)
                    daily_queries.append({'date': date, 'queries': count})
                    
                execution_times = [float(e) for t in results[-1] if t]
                avg_execution_time = sum(execution_times)/ len(execution_times) if execution_times else 0
                
                summary = {
                    'period_days': days, 
                    'daily_queries': daily_queries,
                    'total_queries': sum(day['queries'] for day in daily_queries), 
                    'avg_execution_time': round(avg_execution_time, 3), 
                    'execution_times_sample': execution_times[:10]
                } 
                
                return summary
            
        except Exception as e:
            logger.error(f"Failed to get analytics summary: {str(e)}")
            return {
                'error': f'Analytics retrieval failed : {str(e)}', 
                'period_days': days
            }       
            
    async def cleanup_old_data(self, days_to_keep : int = 30):
        """Clean up old analytics data"""
        
        try:
            async with self.redis_manager.get_connection() as redis_client:
                cutoff_date = (timezone.now()-timezone.timedelta(days=days_to_keep)).strftime('%Y-%m-%d')
                
                pattern = 'chat_analytics:*'
                keys = await redis_client.keys(pattern)
                
                deleted_count = 0
                for key in keys:
                    key_str = key.decode() if isinstance(key, bytes) else key
                    if any(old_date in key_str for old_date in [cutoff_date]):
                        await redis_client.delete(key)
                        deleted_count += 1
                        
                logger.info(f"Cleaned up {deleted_count} old analytics keys")
                return deleted_count
        
        except Exception as e:
            logger.error(f"Analytics cleanup failed: {str(e)}")
            return 0
        