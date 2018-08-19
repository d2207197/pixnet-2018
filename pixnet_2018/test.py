

import time

import cv2
import dramatiq
from dramatiq.brokers.rabbitmq import RabbitmqBroker
from dramatiq.brokers.redis import RedisBroker
from dramatiq.middleware import default_middleware
from dramatiq.results import Results
from dramatiq.results.backends import RedisBackend

result_backend = RedisBackend(encoder=dramatiq.PickleEncoder)
middleware = [m()
              for m in default_middleware
              if m is not dramatiq.middleware.prometheus.Prometheus]
# broker = RabbitmqBroker(
#     middleware=middleware
# )
broker = RedisBroker(
    middleware=middleware
)
dramatiq.set_encoder(dramatiq.PickleEncoder)

broker.add_middleware(Results(backend=result_backend))
dramatiq.set_broker(broker)


@dramatiq.actor(queue_name='test', store_results=True)
def test(delay, arr):

    time.sleep(delay)
    return arr + 10
