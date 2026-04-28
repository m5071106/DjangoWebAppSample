from django.http import HttpResponse
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from .serializers import GreetRequestSerializer, GreetResponseSerializer


def index(request):
    return HttpResponse("Hello World!")


@api_view(["GET"])
def hello_api(request):
    return Response({"message": "Hello World!"})


@api_view(["POST"])
def greet_api(request):
    req = GreetRequestSerializer(data=request.data)
    req.is_valid(raise_exception=True)

    name = req.validated_data["name"]
    res = GreetResponseSerializer({"message": f"Hello, {name}!", "name": name})
    return Response(res.data, status=status.HTTP_200_OK)
