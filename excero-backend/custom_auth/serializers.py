from rest_framework import serializers


class FirebaseTokenObtainSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=255)