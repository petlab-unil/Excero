from functools import partial

from django.contrib.auth import get_user_model
from django.contrib.auth.models import Permission
from django.db.models import Q
from django.utils import timezone
from lmql import query
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import api_view, action
from rest_framework.exceptions import PermissionDenied, NotFound

# Create your views here.
from rest_framework.generics import get_object_or_404
from rest_framework.permissions import AllowAny, DjangoModelPermissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt import authentication

from api.models import ExperimentalCondition, Avatar, SimulatedPeer, AvatarPiece, AvatarType, InterventionWeek, \
    SimulatedPeerModel
from api.serializers import UserSerializer, StepRecordSerializer, GoalSerializer, ExperimentalConditionSerializer, \
    AvatarSerializer, SimulatedPeerSerializer, UserStepRecordSerializer, UserAvatarSerializer, \
    UserSimulatedPeerSerializer, UserGoalSerializer, ConversationSerializer, MessageSerializer, \
    ConversationMessagesSerializer, AvatarTypeAvatarPieceSerializer, AvatarTypeSerializer, AvatarPieceSerializer, \
    UserSelfSerializer, InterventionWeekSerializer, SimulatedPeerModelSerializer, NotificationPayloadSerializer, \
    UserAdminSerializer, UserAdminReportSerializer, BugAdminReportSerializer, AnalyticInteractionSerializer, \
    UserAnalyticInteractionSerializer, SimulatedPeerStepRecordSerializer, UserEditSerializer, AppReportSerializer, \
    UserSimplifiedAdminSerializer
from custom_auth.models import StepRecord, Goal, Message, Conversation, AnalyticInteraction
from custom_auth.permissions import IsOwner, IsAdminUser, ModelPermission, IsPeerUser, IsPeerOrOwner

User = get_user_model()

def firebase_cloud_messaging_send_notification(app, data):
    from firebase_admin import messaging

    payload_data = {
        'has_badge': str(data.get('has_badge', False)).lower(),
    }
    if data.get('notification_type') is not None:
        payload_data['notification_type'] = data.get('notification_type')
    if data.get('additional_payload') is not None:
        from json import loads
        json_data = loads(data.get('additional_payload'))
        payload_data.update(json_data)

    message = messaging.Message(
        notification=messaging.Notification(
            title=data.get('title'),
            body=data.get('message')
        ),
        token=data.get('destination_token'),
        data=payload_data,
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default", content_available=True,
                                  mutable_content=True, custom_data=payload_data)
            ),
        ),
    )

    return messaging.send(message, app=app)

class UserViewSet(viewsets.ModelViewSet):
    #queryset = User.objects.all()
    permission_classes = (DjangoModelPermissions, IsPeerOrOwner, )

    def list(self, request, *args, **kwargs):
        if not request.user.is_staff:
            raise PermissionDenied()
        queryset = User.objects.all()
        return Response(UserSimplifiedAdminSerializer(queryset, many=True, context={'request': request}).data)

    @action(methods=['get'], detail=False)
    def self(self, request):
        user = User.objects.filter(pk=request.user.id)
        return Response(UserSelfSerializer(user, many=True, context={'request': request}).data)

    @action(methods=['post'], detail=False, authentication_classes=[], permission_classes=[AllowAny])
    def activate(self, request):
        if 't' not in request.data.keys():
            return Response(status=status.HTTP_400_BAD_REQUEST)

        user = get_object_or_404(User, password_set_token=request.data['t'],
                                 password_set_date__gte=timezone.now())

        if 'pwd1' in request.data.keys() and 'pwd2' in request.data.keys() \
                and request.data['pwd1'] == request.data['pwd2']:
            user.set_password(request.data['pwd1'])
            user.password_set_token = None
            user.password_set_date = None
            user.password_reset_token = None
            user.password_reset_date = None
            user.save()
        else:
            return Response(status=status.HTTP_400_BAD_REQUEST)
        return Response(status=status.HTTP_200_OK, data={'u': user.username})

    def update(self, request, *args, **kwargs):
        if 'pk' not in kwargs.keys():
            return Response(status=status.HTTP_400_BAD_REQUEST)
        else:
            if int(kwargs['pk']) != request.user.id and not request.user.is_staff:
                return Response(status=status.HTTP_403_FORBIDDEN)
        user = get_object_or_404(User.objects, **kwargs)
        serializer = UserEditSerializer(user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(UserSerializer(user, context={'request': request}).data)

    @action(methods=['get'], detail=False)
    def deactivate(self, request):
        user = get_object_or_404(User, pk=request.user.id)
        user.is_active = False
        user.save()
        return Response(UserSelfSerializer(user, context={'request': request}).data)

    def get_serializer_class(self):
        user = User.objects.filter(id=self.request.user.id).first()
        if user.is_staff:
            return UserAdminSerializer
        return UserSerializer

    def get_queryset(self):
        user = User.objects.filter(id=self.request.user.id).first()
        return User.objects.all()
        #if user.is_staff:
        #    return User.objects.all()
        #else:
        #    return User.objects.filter(id=self.request.user.id)


class StepRecordViewSet(viewsets.ModelViewSet):
    serializer_class = StepRecordSerializer
    queryset = StepRecord.objects.all()
    permission_classes = (DjangoModelPermissions,)


class GoalViewSet(viewsets.ModelViewSet):
    serializer_class = GoalSerializer
    permission_classes = (DjangoModelPermissions,)

    def get_queryset(self):
        user = User.objects.filter(id=self.request.user.id).first()
        if user.is_staff:
            return Goal.objects.all()
        else:
            return Goal.objects.filter(user__id=self.request.user.id)


class ExperimentalConditionViewSet(viewsets.ModelViewSet):
    serializer_class = ExperimentalConditionSerializer
    queryset = ExperimentalCondition.objects.all()


class AvatarViewSet(viewsets.ModelViewSet):
    serializer_class = AvatarSerializer
    queryset = Avatar.objects.all()
    permission_classes = (DjangoModelPermissions,)

    def get_user_peer_id(self, user_id):
        query = Q(user1_id=user_id) | Q(user2_id=user_id)
        conv = get_object_or_404(Conversation, query)
        if user_id == conv.user1.id:
            if conv.user2 is not None:
                return conv.user2.id
        elif user_id == conv.user2.id:
            return conv.user1.id
        return None

    def get_sep_peer_id(self, user_id):
        user = get_object_or_404(User, pk=user_id)
        if user.simulated_peer is not None:
            return user.simulated_peer.simulated_peer_model.id
        return None

    def retrieve(self, request, pk=None, *args, **kwargs):
        if request.user.is_staff:
            return super().retrieve(request, pk, *args, **kwargs)
        peer_user_id = self.get_user_peer_id(request.user.id)

        query = None
        if peer_user_id is None:
            peer_sep_id = self.get_sep_peer_id(request.user.id)
            query = (Q(user__id=request.user.id) | Q(simulated_peer__id=peer_sep_id)) & Q(pk=pk)
            #if peer_sep_id is None:
            #    raise NotFound()
        else:
            query = (Q(user__id=request.user.id) | Q(user__id=peer_user_id)) & Q(pk=pk)
        avatar = get_object_or_404(Avatar, query)
        serializer = self.serializer_class(avatar, context={'request': request})
        return Response(serializer.data)



class UserOwnViewSet(viewsets.ViewSet):
    serializer_class = UserSerializer
    queryset = User.objects.all()

    def get_queryset(self):
        user = self.request.user
        return self.queryset.filter(id=user.id)


class UserNestedModelViewSet(viewsets.ModelViewSet):
    model_class = None
    queryset = Avatar.objects.all()
    relation_field_name = None
    many = False
    permission_classes = (DjangoModelPermissions, IsPeerOrOwner,)

    def is_user_or_peer(self, user_id, request_user_id):
        conversation = Conversation.objects.filter(user1__id=request_user_id).last()
        peer_id = -1
        if conversation is not None:
            if conversation.user2 is not None:
                peer_id = conversation.user2.id
            else:
                peer_id = conversation.simulated_peer.id
        else:
            conversation = Conversation.objects.filter(user2__id=request_user_id).last()
            if conversation is not None:
                if conversation.user1 is not None:
                    peer_id = conversation.user1.id
                else:
                    peer_id = conversation.simulated_peer.id

        return int(user_id) == int(request_user_id) or int(user_id) == int(peer_id)

    def get_object_or_403(self, request, user_pk, queryset, **filter_args):
        if self.is_user_or_peer(user_pk, self.request.user.id):
            return queryset.objects.filter(**filter_args)
        else:
            raise PermissionDenied()

    def list(self, request, user_pk=None, **kwargs):
        data = self.get_object_or_403(request, user_pk, self.model_class, user__id=user_pk)
        serializer = self.serializer_class(data, many=True, context={'request': request})
        return Response(serializer.data)

    def retrieve(self, request, pk=None, user_pk=None, *args, **kwargs):
        queryset = self.model_class.objects.filter(id=pk, user__id=user_pk)
        obj = get_object_or_404(queryset, pk=pk)
        self.check_object_permissions(self.request, obj)
        serializer = self.serializer_class(obj, context={'request': request})
        return Response(serializer.data)

    def create(self, request, user_pk=None, *args, **kwargs):
        from rest_framework import status
        import logging
        from backend.settings import DEBUG
        is_many = isinstance(request.data, list)
        serializer = self.serializer_class(data=request.data, many=is_many)
        if DEBUG:
            logger = logging.getLogger()
            logger.addHandler(logging.FileHandler('serializer_logs.txt'))
        if not request.user.is_staff and int(request.user.id) != int(user_pk):
            raise PermissionDenied()
        if not serializer.is_valid():
            if DEBUG:
                logger.warning('Serializer invalid exception: {}'.format(serializer.errors))
            return Response(status=status.HTTP_400_BAD_REQUEST)
        obj = serializer.save()
        user = User.objects.filter(id=user_pk).first()
        is_many_res = []
        if not self.many:
            if is_many:
                for o in obj:
                    setattr(user, self.relation_field_name, o)
                    user.save()
            else:
                setattr(user, self.relation_field_name, obj)
                user.save()
        else:
            if is_many:
                for o in obj:
                    setattr(o, self.relation_field_name, user)
                    o.save()
            else:
                setattr(obj, self.relation_field_name, user)
                obj.save()
        if is_many:
            return Response(status=status.HTTP_200_OK)
        else:
            return self.retrieve(request, obj.id, user_pk, *args, **kwargs)


class UserAvatarViewSet(UserNestedModelViewSet):
    serializer_class = UserAvatarSerializer
    model_class = Avatar
    relation_field_name = 'avatar'


class UserSimulatedPeerViewSet(UserNestedModelViewSet):
    serializer_class = UserSimulatedPeerSerializer
    model_class = SimulatedPeer
    relation_field_name = 'simulated_peer'

    def list(self, request, user_pk=None, **kwargs):
        if not request.user.is_staff:
            if int(user_pk) == request.user.id:
                return super().list(request, user_pk, **kwargs)
            else:
                raise PermissionDenied()
        else:
            return super().list(request, user_pk, **kwargs)

    def retrieve(self, request, pk=None, user_pk=None, *args, **kwargs):
        if not request.user.is_staff:
            if int(user_pk) == request.user.id:
                return super().retrieve(request, pk, user_pk, **kwargs)
            else:
                raise PermissionDenied()
        else:
            return super().retrieve(request, pk, user_pk, **kwargs)

class UserStepRecordViewSet(UserNestedModelViewSet):
    serializer_class = UserStepRecordSerializer
    model_class = StepRecord
    relation_field_name = 'user'
    many = True


class SimulatedPeerStepRecordViewSet(viewsets.ModelViewSet):
    queryset = StepRecord.objects.all()
    serializer_class = SimulatedPeerStepRecordSerializer
    model_class = StepRecord
    many = True

    def list(self, request, simulatedpeer_pk=None, **kwargs):
        if not request.user.is_staff:
            query_filter = Q(sep__user__id=request.user.id) & Q(sep__id=simulatedpeer_pk)
            _ = get_object_or_404(SimulatedPeer, Q(id=simulatedpeer_pk) & Q(user__id=request.user.id))
        else:
            query_filter = Q(sep__id=simulatedpeer_pk)
        queryset = self.model_class.objects.filter(query_filter)
        serializer = self.serializer_class(queryset, many=True, context={'request': request})
        return Response(serializer.data)

    def retrieve(self, request, pk=None, simulatedpeer_pk=None, *args, **kwargs):
        if not request.user.is_staff:
            query_filter = Q(pk=pk) & Q(sep__user__id=request.user.id) & Q(sep__id=simulatedpeer_pk)
            _ = get_object_or_404(SimulatedPeer, Q(id=simulatedpeer_pk) & Q(user__id=request.user.id))
        else:
            query_filter = Q(pk=pk) & Q(sep__id=simulatedpeer_pk)
        queryset = self.model_class.objects.filter(query_filter)
        obj = get_object_or_404(queryset, pk=pk)
        serializer = self.serializer_class(obj, context={'request': request})
        return Response(serializer.data)


class UserGoalViewSet(UserNestedModelViewSet):
    serializer_class = UserGoalSerializer
    model_class = Goal
    relation_field_name = 'user'
    many = True


class SimulatedPeerModelViewSet(viewsets.ModelViewSet):
    serializer_class = SimulatedPeerModelSerializer
    queryset = SimulatedPeerModel.objects.all()


class SimulatedPeerViewSet(viewsets.ModelViewSet):
    serializer_class = SimulatedPeerSerializer

    def get_queryset(self):
        user = User.objects.filter(id=self.request.user.id).first()
        if user.is_staff:
            return SimulatedPeer.objects.all()
        else:
            return SimulatedPeer.objects.filter(user__id=user.pk)

class ConversationViewSet(viewsets.ModelViewSet):
    serializer_class = ConversationSerializer
    permission_classes = (DjangoModelPermissions, )

    def get_queryset(self):
        user = User.objects.filter(id=self.request.user.id).first()
        if user.is_staff:
            return Conversation.objects.all()
        else:
            query_filter = Q(user1__id=self.request.user.id) | Q(user2__id=self.request.user.id)
            return Conversation.objects.filter(query_filter)


class MessageViewSet(viewsets.ModelViewSet):
    serializer_class = MessageSerializer

    def get_queryset(self):
        user = User.objects.filter(id=self.request.user.id).first()
        if user.is_staff:
            return Message.objects.all()
        else:
            query_filter = Q(user1__id=self.request.user.id) | Q(user2__id=self.request.user.id)
            conv = get_object_or_404(Conversation, query_filter)
            return Message.objects.filter(conversation_id=conv.id)


class UserConversationViewSet(UserNestedModelViewSet):
    serializer_class = ConversationSerializer
    queryset = Conversation.objects.all()
    model_class = Conversation

    def list(self, request, user_pk=None, **kwargs):
        if not request.user.is_staff:
            query_filter = (Q(user1__id=user_pk) | Q(user2__id=user_pk)) & \
                           (Q(user1__id=request.user.id) | Q(user2__id=request.user.id))
        else:
            query_filter = Q(user1__id=user_pk) | Q(user2__id=user_pk)
        queryset = self.model_class.objects.filter(query_filter)
        serializer = self.serializer_class(queryset, many=True, context={'request': request})
        return Response(serializer.data)

    def retrieve(self, request, pk=None, user_pk=None, *args, **kwargs):
        if not request.user.is_staff:
            query_filter = Q(id=pk) & ((Q(user1__id=user_pk) | Q(user2__id=user_pk)) &
                           (Q(user1__id=request.user.id) | Q(user2__id=request.user.id)))
        else:
            query_filter = Q(id=pk) & (Q(user1__id=user_pk) | Q(user2__id=user_pk))
        queryset = self.model_class.objects.filter(query_filter)
        obj = get_object_or_404(queryset, pk=pk)
        serializer = self.serializer_class(obj, context={'request': request})
        return Response(serializer.data)

    def create(self, request, user_pk=None, *args, **kwargs):
        return NotFound()


class ConversationMessagesViewSet(viewsets.ModelViewSet):
    model_class = Message
    queryset = Message.objects.all()
    relation_field_name = 'conversation'
    many = True
    serializer_class = ConversationMessagesSerializer

    @classmethod
    def init_firebase(cls):
        import firebase_admin
        if not hasattr(cls, 'initialized') and 'excero' not in firebase_admin._apps.keys():
            firebase_admin.initialize_app(name='excero')
            cls.initialized = True

    def list(self, request, conversation_pk=None, **kwargs):
        if not request.user.is_staff:
            query_filter = Q(conversation__pk=conversation_pk) & \
                            (Q(conversation__user1_id=request.user.id) | Q(conversation__user2_id=request.user.id))
            _ = get_object_or_404(Conversation, Q(pk=conversation_pk) & \
                                  (Q(user1_id=request.user.id) | Q(user2_id=request.user.id)))
        else:
            query_filter = Q(conversation__pk=conversation_pk)

        queryset = self.model_class.objects.filter(query_filter)
        serializer = self.serializer_class(queryset, many=True, context={'request': request})
        return Response(serializer.data)

    def retrieve(self, request, pk=None, conversation_pk=None, *args, **kwargs):
        if not request.user.is_staff:
            query_filter = Q(pk=pk) & (Q(conversation__pk=conversation_pk) &
                           (Q(conversation__user1_id=request.user.id) | Q(conversation__user2_id=request.user.id)))
            _ = get_object_or_404(Conversation, Q(pk=conversation_pk) & \
                                  (Q(user1_id=request.user.id) | Q(user2_id=request.user.id)))
        else:
            query_filter = Q(pk=pk) & Q(conversation__pk=conversation_pk)
        queryset = self.model_class.objects.filter(query_filter)
        obj = get_object_or_404(queryset, pk=pk)
        serializer = self.serializer_class(obj, context={'request': request})
        return Response(serializer.data)

    def create(self, request, conversation_pk=None, *args, **kwargs):
        from rest_framework import status
        from firebase_admin import get_app, firestore
        from backend.settings import FIREBASE_DOCUMENT_BASEPATH
        serializer = self.serializer_class(data=request.data)
        if not serializer.is_valid():
            return Response(status=status.HTTP_400_BAD_REQUEST)
        obj = serializer.save()
        setattr(obj, 'author_user', request.user)
        obj.save()
        conversation = get_object_or_404(Conversation, Q(pk=conversation_pk) & \
                                  (Q(user1_id=request.user.id) | Q(user2_id=request.user.id)))

        if obj.author_user is not None and conversation is not None:
            ConversationMessagesViewSet.init_firebase()
            app = get_app('excero')
            if ((conversation.user1 == obj.author_user or conversation.user2 == obj.author_user)
                    and conversation.simulated_peer is not None):
                from api.agents import run_openai_chat
                message = run_openai_chat(conversation, conversation.simulated_peer, request.user, obj.content)
                try:
                    firebase_cloud_messaging_send_notification(app, {'destination_token': conversation.user1.fcm_token,
                                                                     'title': 'Nouveau message',
                                                                     'message': conversation.simulated_peer.name + ': ' + message,
                                                                     'has_badge': True,
                                                                     'notification_type': 'chat'})
                except Exception as e:
                    print(e)

                conversation_document_path = FIREBASE_DOCUMENT_BASEPATH.format(conversation_id=conversation.uuid)
                db = firestore.client(app=app)
                db.collection('discussions').document(str(conversation.uuid)).collection('message-feed') \
                    .add({
                    'content': message,
                    'created': timezone.now(),
                    'senderId': conversation.simulated_peer.name,
                    'senderName': 'SEP'
                })
                msg = Message()
                msg.content = message
                msg.author_simulated_peer = conversation.simulated_peer
                msg.save()
                if not self.many:
                    setattr(conversation, self.relation_field_name, msg)
                    conversation.save()
                else:
                    setattr(msg, self.relation_field_name, conversation)
                    msg.save()
            elif (conversation.user1 != obj.author_user and conversation.user2 is not None and
                    conversation.user1.fcm_token is not None):
                firebase_cloud_messaging_send_notification(app, {'destination_token': conversation.user1.fcm_token,
                                                                 'title': 'Nouveau message',
                                                                 'message': conversation.user2.username + ': ' + obj.content,
                                                                 'has_badge': True,
                                                                 'notification_type': 'chat'})
            elif (conversation.user2 is not None and conversation.user2 != obj.author_user
                  and conversation.user1 is not None and conversation.user2.fcm_token is not None):
                firebase_cloud_messaging_send_notification(app, {'destination_token': conversation.user2.fcm_token,
                                                                 'title': 'Nouveau message',
                                                                 'message': conversation.user1.username + ': ' + obj.content,
                                                                 'has_badge': True,
                                                                 'notification_type': 'chat'})
        if not self.many:
            setattr(conversation, self.relation_field_name, obj)
            conversation.save()
        else:
            setattr(obj, self.relation_field_name, conversation)
            obj.save()
        return self.retrieve(request, obj.id, conversation_pk, *args, **kwargs)


class AvatarTypeViewSet(viewsets.ModelViewSet):
    queryset = AvatarType.objects.all()
    serializer_class = AvatarTypeSerializer


class AvatarPieceViewSet(viewsets.ModelViewSet):
    queryset = AvatarPiece.objects.all()
    serializer_class = AvatarPieceSerializer


class AvatarTypeAvatarPiecesViewSet(viewsets.ModelViewSet):
    queryset = AvatarPiece.objects.all()
    serializer_class = AvatarTypeAvatarPieceSerializer
    model_class = AvatarPiece
    relation_field_name = 'type'
    many = True

    def list(self, request, avatartype_pk=None, **kwargs):
        queryset = self.model_class.objects.filter(type__id=avatartype_pk)
        serializer = self.serializer_class(queryset, many=True, context={'request': request})
        return Response(serializer.data)

    def retrieve(self, request, pk=None, avatartype_pk=None, *args, **kwargs):
        queryset = self.model_class.objects.filter(id=pk, type__pk=avatartype_pk)
        obj = get_object_or_404(queryset, pk=pk)
        serializer = self.serializer_class(obj, context={'request': request})
        return Response(serializer.data)

    def create(self, request, avatartype_pk=None, *args, **kwargs):
        from rest_framework import status
        serializer = self.serializer_class(data=request.data)
        if not serializer.is_valid():
            return Response(status=status.HTTP_400_BAD_REQUEST)
        obj = serializer.save()

        avatartype = AvatarType.objects.filter(id=avatartype_pk).first()
        if not self.many:
            setattr(avatartype, self.relation_field_name, obj)
            avatartype.save()
        else:
            setattr(obj, self.relation_field_name, avatartype)
            obj.save()
        return self.retrieve(request, obj.id, avatartype_pk, *args, **kwargs)


class InterventionWeekViewSet(viewsets.ModelViewSet):
    queryset = InterventionWeek.objects.all()
    serializer_class = InterventionWeekSerializer


class AnalyticInteractionViewSet(viewsets.ModelViewSet):
    serializer_class = AnalyticInteractionSerializer
    permission_classes = (IsOwner, DjangoModelPermissions, )

    def get_queryset(self):
        user = User.objects.filter(id=self.request.user.id).first()
        if user.is_staff:
            return AnalyticInteraction.objects.all()
        else:
            return AnalyticInteraction.objects.filter(user__id=self.request.user.id)


class UserAnalyticInteractionViewSet(UserNestedModelViewSet):
    serializer_class = UserAnalyticInteractionSerializer
    model_class = AnalyticInteraction
    relation_field_name = 'user'
    many = True


    def list(self, request, user_pk=None, **kwargs):
        if not request.user.is_staff:
            if int(user_pk) == request.user.id:
                return super().list(request, user_pk, **kwargs)
            else:
                raise PermissionDenied()
        else:
            return super().list(request, user_pk, **kwargs)

    def retrieve(self, request, pk=None, user_pk=None, *args, **kwargs):
        if not request.user.is_staff:
            if int(user_pk) == request.user.id:
                return super().retrieve(request, pk, user_pk, **kwargs)
            else:
                raise PermissionDenied()
        else:
            return super().retrieve(request, pk, user_pk, **kwargs)

class FirebaseNotificationsAPIView(APIView):
    authentication_classes = (authentication.JWTTokenUserAuthentication,)
    permission_classes = (IsAdminUser,)

    @classmethod
    def init_firebase(cls):
        import firebase_admin
        if not hasattr(cls, 'initialized') and 'excero' not in firebase_admin._apps.keys():
            firebase_admin.initialize_app(name='excero')
            cls.initialized = True

    def _create_access_token(self):
        from google.oauth2 import service_account
        from google.auth.transport.requests import Request
        from backend.settings import FIREBASE_AUTHENTICATION_FILE, FIREBASE_AUTHETICATION_SCOPES
        credentials = service_account.Credentials.from_service_account_file(filename=FIREBASE_AUTHENTICATION_FILE,
                                                                            scopes=FIREBASE_AUTHETICATION_SCOPES)
        request = Request()
        credentials.refresh(request)
        return credentials.token

    def get(self, request, format=None):
        notifiable_users = User.objects.filter(fcm_token__isnull=False)
        users = UserSerializer(notifiable_users, many=True, context={'request': request})
        return Response(users.data)

    def post(self, request, format=None):
        from firebase_admin import messaging, get_app
        request_content = NotificationPayloadSerializer(data=request.data)

        if not request_content.is_valid():
            return Response(request_content.errors, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        FirebaseNotificationsAPIView.init_firebase()
        app = get_app('excero')
        data = request_content.validated_data
        response = firebase_cloud_messaging_send_notification(app, data)

        if response is not None:
            return Response()


class GoalSettingsView(APIView):
    authentication_classes = (authentication.JWTTokenUserAuthentication,)
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request, format=None):
        from api.processing import compute_weekly_goal
        steps = list(StepRecord.objects.filter(user__id=request.user.id))
        new_goal = compute_weekly_goal(steps, request.user.id)
        return None


class UserAdminView(APIView):
    authentication_classes = (authentication.JWTTokenUserAuthentication,)
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, format=None):
        request_content = UserAdminReportSerializer(data=request.data)
        if not request_content.is_valid():
            Response(request_content.errors, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        import smtplib
        from email.message import EmailMessage
        from backend.settings import EMAIL_SMTP_SERVER, EMAIL_SMTP_PORT, \
                                      EMAIL_SMTP_USER, EMAIL_SMTP_PASSWORD, \
                                      EMAIL_SMTP_SENDER, EMAIL_SMTP_RECIPIENTS

        email = EmailMessage()
        email['Subject'] = 'Excero Report - One of the participants has been reported'
        email['From'] = EMAIL_SMTP_SENDER
        email['To'] = EMAIL_SMTP_RECIPIENTS
        issuer = request_content.validated_data.get('issuer')
        reported = request_content.validated_data.get('reported_user')
        email.set_content('Here are the data linked to this report:\n- Issuer: {issuer}\n - Reported user: {reported}\n- Content of the report: {content}'.format(
                              issuer=issuer.username,
                              reported=reported.username,
                              content=request_content.validated_data.get('issue')
                          ))
        mail = smtplib.SMTP_SSL(EMAIL_SMTP_SERVER, EMAIL_SMTP_PORT)
        mail.ehlo()
        mail.login(EMAIL_SMTP_USER, EMAIL_SMTP_PASSWORD)
        mail.send_message(email)
        mail.close()
        return Response(status=status.HTTP_200_OK)


class BugAdminView(APIView):
    authentication_classes = (authentication.JWTTokenUserAuthentication,)
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, format=None):
        request_content = BugAdminReportSerializer(data=request.data)

        if not request_content.is_valid():
            Response(request_content.errors, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        import smtplib
        from email.message import EmailMessage
        from backend.settings import EMAIL_SMTP_SERVER, EMAIL_SMTP_PORT, \
            EMAIL_SMTP_USER, EMAIL_SMTP_PASSWORD, \
            EMAIL_SMTP_SENDER, EMAIL_SMTP_RECIPIENTS, REPORTS_ROOT
        from datetime import datetime

        email = EmailMessage()
        email['Subject'] = 'Excero Report - One of the participants has reported an issue with the app'
        email['From'] = EMAIL_SMTP_SENDER
        email['To'] = EMAIL_SMTP_RECIPIENTS
        issuer = request_content.validated_data.get('issuer')
        file_destination = ''
        if request_content.validated_data.get('app_logs') is not None:
            report_file = request.FILES['app_logs']
            file_destination = REPORTS_ROOT + '/report_' + datetime.now().strftime('%Y%m%d%H%M%S') + '_' + issuer.username + '.txt'
            with open(file_destination, 'wb+') as f:
                for chunk in report_file.chunks():
                    f.write(chunk)

        email.set_content('Here are the data linked to this report:\n- Issuer: {issuer}\n- Issue: {issue}\n- Has uploaded app logs: {app_logs}'.format(
                              issuer=issuer.username,
                              issue=request_content.validated_data.get('issue'),
                              app_logs=file_destination
                          ))
        mail = smtplib.SMTP_SSL(EMAIL_SMTP_SERVER, EMAIL_SMTP_PORT)
        mail.ehlo()
        mail.login(EMAIL_SMTP_USER, EMAIL_SMTP_PASSWORD)
        mail.send_message(email)
        mail.close()
        return Response(status=status.HTTP_200_OK)


class AppReportView(APIView):
    authentication_classes = (authentication.JWTTokenUserAuthentication,)
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, format=None):
        request_content = AppReportSerializer(data=request.data)

        if not request_content.is_valid():
            Response(request_content.errors, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        from backend.settings import REPORTS_ROOT
        from django.utils import timezone
        app_logs = request.FILES['app_logs']
        issuer = None
        if request_content.validated_data.get('issuer') is not None:
           issuer = request_content.validated_data.get('issuer')
        if issuer is None:
            issuer = {'username': 'anonymous'}
        file_destination = REPORTS_ROOT + '/report_' + timezone.now().strftime(
            '%Y%m%d%H%M%S') + '_' + issuer.username + '.txt'
        with open(file_destination, 'wb+') as f:
            for chunk in app_logs.chunks():
                f.write(chunk)

        return Response(status=status.HTTP_200_OK)