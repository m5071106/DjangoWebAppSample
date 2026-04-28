from django.urls import path

from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path("api/hello/", views.hello_api, name="hello-api"),
    path("api/greet/", views.greet_api, name="greet-api"),
]
