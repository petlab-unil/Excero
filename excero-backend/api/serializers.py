from django.conf import settings
from django.utils import timezone

from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework_nested.relations import NestedHyperlinkedRelatedField, NestedHyperlinkedIdentityField
from rest_framework_nested.serializers import NestedHyperlinkedModelSerializer

from api.models import ExperimentalCondition, Avatar, SimulatedPeer, AvatarType, AvatarPiece, InterventionWeek, \
    SimulatedPeerModel
from custom_auth.models import Goal, StepRecord, Message, Conversation, AnalyticInteraction

User = get_user_model()


class AvatarPiecesHyperlink(serializers.HyperlinkedRelatedField):
    view_name = 'avatartype-avatarpiece-detail'
    queryset = AvatarPiece.objects.all()

    def get_url(self, obj, view_name, request, format):
        from rest_framework.reverse import reverse
        url_kwargs = {
            'pk': obj.pk
        }
        return reverse('avatarpiece-detail', kwargs=url_kwargs, request=request, format=format)

    def get_object(self, view_name, view_args, view_kwargs):
        lookup_kwargs = {
            'type': view_kwargs['avatartype_pk'],
            'pk': view_kwargs['pk']
        }
        obj = self.get_queryset().get(**lookup_kwargs)
        return obj


class ExperimentalConditionSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='experimentalcondition-detail')

    class Meta:
        model = ExperimentalCondition
        fields = [
            'url',
            'id',
            'acronym',
            'name',
            'start',
            'end'
        ]


class StepRecordSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='steprecord-detail')

    class Meta:
        model = StepRecord
        fields = [
            'url',
            'id',
            'count',
            'start',
            'end'
        ]


class UserStepRecordSerializer(NestedHyperlinkedModelSerializer):
    url = NestedHyperlinkedIdentityField(view_name='user-steprecord-detail',
                                                     parent_lookup_kwargs={'user_pk': 'user__pk'})

    class Meta:
        model = StepRecord
        fields = [
            'url',
            'id',
            'count',
            'start',
            'end'
        ]


class SimulatedPeerStepRecordSerializer(NestedHyperlinkedModelSerializer):
    url = NestedHyperlinkedIdentityField(view_name='simulatedpeer-steprecord-detail',
                                         parent_lookup_kwargs={'simulatedpeer_pk': 'sep__pk'})

    class Meta:
        model = StepRecord
        fields = [
            'url',
            'id',
            'count',
            'start',
            'end'
        ]


class GoalSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='goal-detail')

    class Meta:
        model = Goal
        fields = [
            'url',
            'id',
            'value',
            'start',
            'end',
            'attained'
        ]


class UserGoalSerializer(NestedHyperlinkedModelSerializer):
    url = NestedHyperlinkedIdentityField(view_name='user-goal-detail',
                                         parent_lookup_kwargs={'user_pk': 'user__pk'})

    class Meta:
        model = Goal
        fields = [
            'url',
            'id',
            'value',
            'start',
            'end',
            'attained'
        ]


class AvatarTypeAvatarPieceSerializer(NestedHyperlinkedModelSerializer):
    url = NestedHyperlinkedIdentityField(view_name='avatartype-avatarpiece-detail',
                                         parent_lookup_kwargs={'avatartype_pk': 'type__pk'})

    class Meta:
        model = AvatarPiece
        fields = [
            'url',
            'name',
            'width',
            'height',
            'position_x',
            'position_y',
            'position_z',
            'file'
        ]


class AvatarPieceSerializer(NestedHyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='avatarpiece-detail')

    class Meta:
        model = AvatarPiece
        fields = [
            'url',
            'name',
            'width',
            'height',
            'position_x',
            'position_y',
            'position_z',
            'file'
        ]


class AvatarTypeSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='avatartype-detail')
    avatarpieces = NestedHyperlinkedRelatedField(view_name='avatarpiece-detail', many=True, read_only=True)

    class Meta:
        model = AvatarType
        fields = [
            'url',
            'type_name',
            'avatarpieces'
        ]

    def get_avatarpieces(self, obj):
        pieces = AvatarPiece.objects.filter(type_id=obj.id)
        return AvatarTypeAvatarPieceSerializer(data=pieces, many=True)


class AvatarSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='avatar-detail')

    type = serializers.HyperlinkedRelatedField(view_name='avatartype-detail', queryset=AvatarType.objects.all(),
                                               lookup_field='pk')

    class Meta:
        model = Avatar
        fields = [
            'url',
            'id',
            'base',
            'head',
            'torso',
            'legs',
            'shoes',
            'tint',
            'type',
        ]


class AvatarAvatarPiecesSerializer(NestedHyperlinkedModelSerializer):
    url = NestedHyperlinkedIdentityField(view_name='avatar-avatarpiece-detail',
                                         parent_lookup_kwargs={'avatar_pk': 'avatar__pk'})

    class Meta:
        model = AvatarPiece
        fields = [
            'url',
            'name',
            'width',
            'height',
            'position_x',
            'position_y',
            'position_z',
            'file'
        ]


class UserAvatarSerializer(NestedHyperlinkedModelSerializer):
    url = NestedHyperlinkedIdentityField(view_name='user-avatar-detail', parent_lookup_kwargs={'user_pk': 'user__pk'})
    base = AvatarPiecesHyperlink()
    head = AvatarPiecesHyperlink()
    torso = AvatarPiecesHyperlink()
    legs = AvatarPiecesHyperlink()
    shoes = AvatarPiecesHyperlink()

    type = serializers.HyperlinkedRelatedField(view_name='avatartype-detail', queryset=AvatarType.objects.all(),
                                               lookup_field='pk')

    class Meta:
        model = Avatar
        fields = [
            'url',
            'id',
            'base',
            'head',
            'torso',
            'legs',
            'shoes',
            'type',
            'tint',
        ]


class SimulatedPeerModelSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='simulatedpeermodel-detail')
    avatar = serializers.HyperlinkedRelatedField(view_name='avatar-detail',
                                                 queryset=Avatar.objects.all(), lookup_field='pk')

    class Meta:
        model = SimulatedPeerModel
        fields = [
            'url',
            'id',
            'preview',
            'initial_prompt',
            'avatar'
        ]


class SimulatedPeerSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='simulatedpeer-detail')
    simulated_peer_model = serializers.HyperlinkedRelatedField(view_name='simulatedpeermodel-detail',
                                                 queryset=SimulatedPeerModel.objects.all(), lookup_field='pk')

    class Meta:
        model = SimulatedPeer
        fields = [
            'url',
            'id',
            'name',
            'simulated_peer_model'
        ]


class UserSimulatedPeerSerializer(NestedHyperlinkedModelSerializer):
    url = NestedHyperlinkedIdentityField(view_name='user-simulatedpeer-detail',
                                         parent_lookup_kwargs={'user_pk': 'user__pk'})
    simulated_peer_model = serializers.HyperlinkedRelatedField(view_name='simulatedpeermodel-detail',
                                                 queryset=SimulatedPeerModel.objects.all(), lookup_field='pk')

    class Meta:
        model = SimulatedPeer
        fields = [
            'url',
            'id',
            'name',
            'simulated_peer_model',
        ]


class UserSelfSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='user-detail')
    simulated_peer = serializers.HyperlinkedRelatedField(view_name='simulatedpeer-detail', read_only=True)
    avatar = NestedHyperlinkedRelatedField(view_name='user-avatar-detail',
                                           read_only=True, parent_lookup_kwargs={'user_pk': 'user__pk'})
    experimental_condition = serializers.HyperlinkedRelatedField(view_name='experimentalcondition-detail',
                                                                 queryset=ExperimentalCondition.objects
                                                                 .filter(start__lte=timezone.now(),
                                                                         end__gte=timezone.now()), lookup_field='pk')

    class Meta:
        model = User
        fields = [
            'url',
            'id',
            'username',
            'is_active',
            'fcm_token',
            'experimental_condition',
            'simulated_peer',
            'avatar',
        ]


class UserAdminSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='user-detail')
    experimental_condition = serializers.HyperlinkedRelatedField(view_name='experimentalcondition-detail',
                                                                 queryset=ExperimentalCondition.objects
                                                                 .filter(start__lte=timezone.now(),
                                                                         end__gte=timezone.now()), lookup_field='pk')
    simulated_peer = serializers.HyperlinkedRelatedField(view_name='simulatedpeer-detail', read_only=True)
    avatar = NestedHyperlinkedRelatedField(view_name='user-avatar-detail',
                                                 read_only=True, parent_lookup_kwargs={'user_pk': 'user__pk'})
    step_records = serializers.HyperlinkedRelatedField(view_name='steprecord-detail',
                                                         many=True, read_only=True)

    class Meta:
        model = User
        fields = [
            'url',
            'id',
            'username',
            'fcm_token',
            'experimental_condition',
            'simulated_peer',
            'avatar',
            'step_records'
        ]

class UserSimplifiedAdminSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='user-detail')
    experimental_condition = serializers.HyperlinkedRelatedField(view_name='experimentalcondition-detail',
                                                                 queryset=ExperimentalCondition.objects
                                                                 .filter(start__lte=timezone.now(),
                                                                         end__gte=timezone.now()), lookup_field='pk')
    simulated_peer = serializers.HyperlinkedRelatedField(view_name='simulatedpeer-detail', read_only=True)
    avatar = NestedHyperlinkedRelatedField(view_name='user-avatar-detail',
                                           read_only=True, parent_lookup_kwargs={'user_pk': 'user__pk'})

    class Meta:
        model = User
        fields = [
            'url',
            'id',
            'username',
            'fcm_token',
            'experimental_condition',
            'simulated_peer',
            'avatar',
        ]

class UserSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='user-detail')
    experimental_condition = serializers.HyperlinkedRelatedField(view_name='experimentalcondition-detail',
                                                                 queryset=ExperimentalCondition.objects
                                                                 .filter(start__lte=timezone.now(),
                                                                         end__gte=timezone.now()), lookup_field='pk')
    simulated_peer = serializers.HyperlinkedRelatedField(view_name='simulatedpeer-detail', read_only=True)
    avatar = NestedHyperlinkedRelatedField(view_name='user-avatar-detail',
                                                 read_only=True, parent_lookup_kwargs={'user_pk': 'user__pk'})
    step_records = serializers.HyperlinkedRelatedField(view_name='steprecord-detail',
                                                         many=True, read_only=True)

    class Meta:
        model = User
        fields = [
            'url',
            'id',
            'username',
            'fcm_token',
            'avatar',
            'step_records',
            'simulated_peer',
            'experimental_condition'
        ]


class UserEditSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='user-detail')
    simulated_peer = serializers.HyperlinkedRelatedField(view_name='simulatedpeer-detail', read_only=True)
    avatar = NestedHyperlinkedRelatedField(view_name='user-avatar-detail',
                                                 read_only=True, parent_lookup_kwargs={'user_pk': 'user__pk'})
    step_records = serializers.HyperlinkedRelatedField(view_name='steprecord-detail',
                                                         many=True, read_only=True)

    class Meta:
        model = User
        fields = [
            'url',
            'id',
            'username',
            'fcm_token',
            'avatar',
            'step_records',
            'simulated_peer'
        ]


class MessageSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='message-detail')
    author_user = serializers.HyperlinkedRelatedField(view_name='user-detail',
                                                 read_only=True)
    author_simulated_peer = serializers.HyperlinkedRelatedField(view_name='simulatedpeer-detail',
                                                 read_only=True)

    class Meta:
        model = Message
        fields = [
            'url',
            'content',
            'author_user',
            'author_simulated_peer'
        ]


class ConversationSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='conversation-detail')
    user1 = serializers.HyperlinkedRelatedField(view_name='user-detail',
                                                 read_only=True)
    user2 = serializers.HyperlinkedRelatedField(view_name='user-detail',
                                                 read_only=True)
    simulated_peer = serializers.HyperlinkedRelatedField(view_name='simulatedpeer-detail',
                                                 read_only=True)
    messages = serializers.HyperlinkedRelatedField(view_name='message-detail',
                                                   read_only=True, many=True)
    document_path = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'url',
            'document_path',
            'user1',
            'user2',
            'simulated_peer',
            'messages'
        ]

    def get_document_path(self, obj):
        return settings.FIREBASE_DOCUMENT_BASEPATH.format(conversation_id=obj.uuid)


class ConversationMessagesSerializer(NestedHyperlinkedModelSerializer):
    url = NestedHyperlinkedIdentityField(view_name='conversation-message-detail',
                                               parent_lookup_kwargs={'conversation_pk': 'conversation__pk'})
    author_user = serializers.HyperlinkedRelatedField(view_name='user-detail',
                                                      read_only=True)
    author_simulated_peer = serializers.HyperlinkedRelatedField(view_name='simulatedpeer-detail',
                                                                read_only=True)

    class Meta:
        model = Message
        fields = [
            'url',
            'content',
            'author_user',
            'author_simulated_peer'
        ]


class InterventionWeekSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='interventionweek-detail')

    class Meta:
        model = InterventionWeek
        fields = [
            'url',
            'begin',
            'end',
        ]


class NotificationPayloadSerializer(serializers.Serializer):
    destination_token = serializers.CharField(max_length=255)
    title = serializers.CharField(max_length=100)
    message = serializers.CharField(max_length=500)
    has_badge = serializers.BooleanField(default=False)
    notification_type = serializers.CharField(max_length=20, allow_blank=True, required=False)
    additional_payload = serializers.JSONField(required=False)


class UserAdminReportSerializer(serializers.Serializer):
    issuer = serializers.HyperlinkedRelatedField(view_name='user-detail', queryset=User.objects.all())
    reported_user = serializers.HyperlinkedRelatedField(view_name='user-detail', queryset=User.objects.all())
    report_date = serializers.DateTimeField(required=False, default=timezone.now)
    issue = serializers.CharField(max_length=1000)


class BugAdminReportSerializer(serializers.Serializer):
    issuer = serializers.HyperlinkedRelatedField(view_name='user-detail', queryset=User.objects.all())
    report_date = serializers.DateTimeField(required=False, default=timezone.now)
    issue = serializers.CharField(max_length=1000)
    app_logs = serializers.FileField(required=False)


class AppReportSerializer(serializers.Serializer):
    issuer = serializers.HyperlinkedRelatedField(view_name='user-detail', queryset=User.objects.all())
    report_date = serializers.DateTimeField(required=False, default=timezone.now)
    app_logs = serializers.FileField(required=True)


class AnalyticInteractionSerializer(serializers.HyperlinkedModelSerializer):
    url = serializers.HyperlinkedIdentityField(view_name='analytic-detail')
    user = serializers.HyperlinkedRelatedField(view_name='user-detail', read_only=True)

    class Meta:
        model = AnalyticInteraction
        fields = [
            'url',
            'action_name',
            'target',
            'app_version',
            'user',
        ]


class UserAnalyticInteractionSerializer(NestedHyperlinkedModelSerializer):
    url = NestedHyperlinkedIdentityField(view_name='user-analytic-detail',
                                         parent_lookup_kwargs={'user_pk': 'user__pk'})

    class Meta:
        model = AnalyticInteraction
        fields = [
            'url',
            'action_name',
            'target',
            'app_version',
        ]