from django.shortcuts import render

# Create your views here.
from rest_framework import views, permissions, authentication, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from custom_auth.serializers import FirebaseTokenObtainSerializer


class FirebaseTokenObtainPairView(views.APIView):
    serializer_class = FirebaseTokenObtainSerializer
    permission_classes = (permissions.IsAuthenticated, )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    @classmethod
    def init_firebase(cls):
        import firebase_admin
        if not hasattr(cls, 'initialized') and 'excero' not in firebase_admin._apps.keys():
            firebase_admin.initialize_app(name='excero')
            cls.initialized = True

    def get(self, request, format=None):
        from firebase_admin import auth, get_app
        from backend.settings import DEBUG
        FirebaseTokenObtainPairView.init_firebase()
        app = get_app(name='excero')
        if DEBUG:
            if not app:
                print('App is not set')
            else:
                print('App is set')
        uid = str(request.user.id)
        additional_claims = {
            'premiumAccount': False
        }
        to = {'token': auth.create_custom_token(uid, additional_claims, app=app)}
        return Response(to)
