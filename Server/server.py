#coding: utf-8
import time
from datetime import datetime
from flask import Flask, request, make_response, jsonify

# Cantidad de peticiones permitidas durante una ventana de tiempo
REQUEST_LIMIT = 3
# Duración, en segundos, de una ventana de tiempo
REQUEST_LIMIT_TIME_WINDOW = 10

# Almacenamos la hora, en segundos, a la que se ha relizada cada petición
requests = list()

#
# Flask app & config
#

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False

def request_done():
    #
    # Controla las peticiones realizadas durante
    # una ventana de tiempo determinado.
    #
    t = datetime.today()
    time_in_seconds = int(t.timestamp())

    requests.append(time_in_seconds)

    valid_range = time_in_seconds - REQUEST_LIMIT_TIME_WINDOW
    requests_in_time = list(filter(lambda x: x > valid_range, requests))
    
    return (len(requests_in_time), requests_in_time[0])

#
# RESTful
#

@app.route("/", methods=[ "GET" ])
def request_main():
    #
    # Operación para probar la integración de 
    # URLSession + Combine.
    # Sobre todo las operaciones de delay y retry.
    #
    available_request_count, first_finish_request = request_done()

    if available_request_count > REQUEST_LIMIT:
        return make_exceed_response(requests_done=available_request_count, next_request_finish_time=first_finish_request)

    message = {
        "description" : "Petición... OK"
    }

    response = jsonify(message)

    response.headers['X-RateLimit-Limit'] = REQUEST_LIMIT
    response.headers['X-RateLimit-Remaining'] = str(REQUEST_LIMIT - available_request_count)

    response.status_code = 200

    return response

#
# Helper
#

def make_exceed_response(requests_done, next_request_finish_time):
    #
    # Genera un mensaje de error cuando se excede la
    # cantidad de peticiones permitidas por el API.
    #
    message = {
        "description" : "Se ha excecido el límite de peticiones",
    }

    response = jsonify(message)

    t = datetime.today()
    retry_time_seconds = int(t.timestamp()) - next_request_finish_time

    response.headers['X-RateLimit-Limit'] = REQUEST_LIMIT
    response.headers['X-RateLimit-TimeWindow'] = str(REQUEST_LIMIT_TIME_WINDOW)
    response.headers['X-RateLimit-RetryAfter'] = str(retry_time_seconds)

    response.status_code = 429

    return response

#
# Lanzamos el servicio
#

app.run()
