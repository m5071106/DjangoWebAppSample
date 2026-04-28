from rest_framework import serializers


class GreetRequestSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100, trim_whitespace=True)


class GreetResponseSerializer(serializers.Serializer):
    message = serializers.CharField()
    name = serializers.CharField()
