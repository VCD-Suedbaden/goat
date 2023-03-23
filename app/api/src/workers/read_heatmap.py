import asyncio

from src.workers.celery_app import celery_app
from src.workers.method_connector import read_heatmap_async
from src.core.config import settings


@celery_app.task(time_limit=settings.CELERY_TASK_TIME_LIST)
def read_heatmap_task(current_user, heatmap_settings):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    heatmap = loop.run_until_complete(read_heatmap_async(current_user, heatmap_settings))
    return heatmap

