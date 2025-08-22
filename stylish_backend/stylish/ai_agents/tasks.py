from celery import shared_task
from django.utils import timezone
import logging
from .models import Agent
from .services.sales_agent import SalesAnalysisAgent
from .services.inventory_agent import InventoryManagementAgent

logger = logging.getLogger(__name__)

AGENT_CLASSES  = {
    'inventory_manager': InventoryManagementAgent, 
    'sales_analyst': SalesAnalysisAgent
}

@shared_task(name = "ai_agents.run_agent_analysis")
def run_agent_analysis(agent_id: str):
    """Executes a single AI agent by its ID. This task is triggered from the AgentViewSet 'execute' action or 'run_all_agents' task."""
    
    try:
        agent = Agent.objects.get(id=agent_id, is_active = True)
        
        if agent.agent_type in AGENT_CLASSES:
            logger.info(f"Running agent: {agent.name}...")
            agent_instance = AGENT_CLASSES[agent.agent_type](agent)
            analysis = agent_instance.analyze({})
            recommendations = agent_instance.generate_recommendations(analysis)
            agent.last_execution = timezone.now()
            agent.save()
            
            logger.info(f"Successfully ran {agent.name}. Generated {len(recommendations)} recommendations")
            return f"Agent {agent.name} completed. {len(recommendations)} recommendations generated"
        else:
            logger.warning(f"No implementation found for agent type: {agent.agent_type}")
            return f"No implementation for agent type: {agent.agent_type}"
    except Agent.DoesNotExist:
        logger.error(f"Agent with ID {agent_id} not found or is not active.")
        return f"Agent with ID {agent_id} not found"
    except Exception as e:
        logger.error(f"Error running agent with ID {agent_id}: {str(e)}")
        raise
    
    
@shared_task(name = "ai_agents.run_all_agents")
def run_all_agents():
    """Queues all active , background-oriented AI agents for execution"""
    agents = Agent.objects.filter(
        is_active = True, 
        agent_type__in = AGENT_CLASSES.keys()
    )
    
    if not agents.exists():
        logger.info("No active agents scheduled to run.")
        return "No active agents to run."
    
    for agent in agents:
        run_agent_analysis.delay(str(agent.id))
        
    logger.info(f"Queued {agents.count()} agents for execution")
    return f"Queued {agents.count()} agents for analysis "
