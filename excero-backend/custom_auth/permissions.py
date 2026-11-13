from django.contrib.auth import get_user_model
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import BasePermission, DjangoModelPermissions

from custom_auth.models import Conversation

User = get_user_model()

class IsOwner(BasePermission):
    def has_object_permission(self, request, view, obj):
        return (hasattr(obj, 'user_id') and obj.user_id == request.user.id) or obj.id == request.user.id

class IsAdminUser(BasePermission):
    def has_permission(self, request, view):
        User = get_user_model()
        user = User.objects.filter(id=request.user.id).first()
        return bool(user and user.is_staff)


class IsPeerUser(BasePermission):
    def get_peer_id(self, base_user_id):
        conversation = Conversation.objects.filter(user1__id=base_user_id).last()
        peer_id = None
        if conversation is not None:
            if conversation.user2 is not None:
                peer_id = conversation.user2.id
            else:
                peer_id = conversation.simulated_peer.id
        else:
            conversation = Conversation.objects.filter(user2__id=base_user_id).last()
            if conversation is not None:
                if conversation.user1 is not None:
                    peer_id = conversation.user1.id
                else:
                    peer_id = conversation.simulated_peer.id

        return peer_id

    def has_object_permission(self, request, view, obj):
        peer_id = self.get_peer_id(request.user.id)
        if peer_id is not None:
            return obj.user_id == peer_id
        else:
            raise PermissionDenied()


class IsPeerOrOwner(IsPeerUser):
    def has_object_permission(self, request, view, obj):
        if request.method == 'POST':
            return True
        peer_id = self.get_peer_id(request.user.id)
        if hasattr(obj, 'user_id') and ((peer_id is not None and obj.user_id == peer_id)
                                        or obj.user_id == int(request.user.id)):
            return True
        elif isinstance(obj, User) and peer_id == obj.id or request.user.id == obj.id:
            return True
        elif (not isinstance(obj, User) and hasattr(obj, 'user')) \
              and (peer_id == obj.user.id or request.user.id == obj.user.id):
            return True
        else:
            raise PermissionDenied()

class ModelPermission(DjangoModelPermissions):
    pass
