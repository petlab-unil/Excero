import datetime

from django.contrib.auth import get_user_model
from django.db import models
from django.utils import timezone


class TimestampMixin(models.Model):

    class Meta:
        abstract = True

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class ExperimentalCondition(TimestampMixin, models.Model):
    acronym = models.CharField(max_length=4, blank=False, null=False)
    name = models.CharField(max_length=100, blank=False, null=False)
    start = models.DateTimeField()
    end = models.DateTimeField()

    class Meta:
        verbose_name = 'Experimental Condition'


class AvatarType(TimestampMixin, models.Model):
    type_name = models.CharField(max_length=50, blank=False, null=False)

    class Meta:
        verbose_name = 'Avatar Type'


class AvatarPiece(TimestampMixin, models.Model):
    name = models.CharField(max_length=50, blank=False, null=False)
    width = models.FloatField(null=False)
    height = models.FloatField(null=False)
    position_x = models.FloatField(null=False)
    position_y = models.FloatField(null=False)
    position_z = models.IntegerField(null=False)

    type = models.ForeignKey(AvatarType, on_delete=models.SET_NULL, null=True, related_name='avatarpieces')
    file = models.FileField(upload_to='avatarpieces', null=True, blank=True)

    class Meta:
        verbose_name = 'Avatar Piece'


class Avatar(TimestampMixin, models.Model):
    tint = models.CharField(max_length=7, blank=True, null=True)

    base = models.ForeignKey(AvatarPiece, on_delete=models.SET_NULL, null=True, related_name='avatar_bases')
    head = models.ForeignKey(AvatarPiece, on_delete=models.SET_NULL, null=True, related_name='avatar_heads')
    torso = models.ForeignKey(AvatarPiece, on_delete=models.SET_NULL, null=True, related_name='avatar_torsoes')
    legs = models.ForeignKey(AvatarPiece, on_delete=models.SET_NULL, null=True, related_name='avatar_legs')
    shoes = models.ForeignKey(AvatarPiece, on_delete=models.SET_NULL, null=True, related_name='avatar_shoes')

    type = models.ForeignKey(AvatarType, on_delete=models.SET_NULL, null=True, related_name='avatars')

    class Meta:
        verbose_name = 'Avatar'


class SimulatedPeerModel(TimestampMixin, models.Model):
    preview = models.FileField(upload_to='sep_previews')
    initial_prompt = models.TextField(blank=True, null=True)
    repeated_prompt = models.TextField(blank=True, null=True)
    avatar = models.OneToOneField(Avatar, on_delete=models.SET_NULL, null=True, related_name='simulated_peer')

    class Meta:
        verbose_name = 'Simulated Peer Model'


class SimulatedPeer(TimestampMixin, models.Model):
    name = models.CharField(max_length=100, blank=False, null=False)

    simulated_peer_model = models.ForeignKey(SimulatedPeerModel, on_delete=models.SET_NULL, null=True,
                                             related_name='model')

    class Meta:
        verbose_name = 'Simulated Peer'


class InterventionWeek(TimestampMixin, models.Model):
    begin = models.DateTimeField(default=timezone.now, blank=False, null=False)

    @property
    def end(self):
        from datetime import timedelta
        return self.begin + timedelta(days=6, hours=23, minutes=59, seconds=59)

    class Meta:
        verbose_name = 'Intervention Week'
