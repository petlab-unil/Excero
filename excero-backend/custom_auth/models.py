import logging
from datetime import timedelta
from logging import Logger

from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, Group, Permission, ContentType
from django.db import models
from django.utils import timezone

from api.models import ExperimentalCondition, SimulatedPeer, Avatar, TimestampMixin
import uuid


class CustomUserManager(BaseUserManager):

    def create_user(self, email, username, password=None):
        user = self.model(
            username=username,
            email=self.normalize_email(email),
            password_set_token=uuid.uuid4().hex
        )
        user.set_password(password)
        user.save(using=self._db)

        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        user = self.create_user(email, username, password)

        user.is_staff = True
        user.is_superuser = True
        user.save(using=self._db)

        return user


class User(AbstractBaseUser, models.Model):
    id = models.BigAutoField(primary_key=True, serialize=False, unique=True, verbose_name='ID')
    email = models.EmailField(max_length=255, null=False, blank=False, unique=True)
    username = models.CharField(max_length=100, null=False, blank=False, unique=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)

    fcm_token = models.CharField(max_length=255, null=True, blank=True)

    groups = models.ManyToManyField(Group, blank=True, related_name='users')
    user_permissions = models.ManyToManyField(Permission, blank=True, related_name='users')

    experimental_condition = models.ForeignKey(ExperimentalCondition, on_delete=models.SET_NULL, null=True,
                                               related_name='users')
    simulated_peer = models.OneToOneField(SimulatedPeer, on_delete=models.SET_NULL, null=True, blank=True,
                                          related_name='user')
    avatar = models.OneToOneField(Avatar, on_delete=models.SET_NULL, null=True, blank=True, related_name='user')

    password_set_token = models.CharField(max_length=255, null=True, blank=True)
    password_set_date = models.DateTimeField(null=True, blank=True, default=(timezone.now()+timedelta(weeks=1)))

    password_reset_token = models.CharField(max_length=255, null=True, blank=True)
    password_reset_date = models.DateTimeField(null=True, blank=True)

    # TODO: add onetoone on the same model for the human peer

    objects = CustomUserManager()

    USERNAME_FIELD = 'username'
    #REQUIRED_FIELDS = ['email']

    class Meta:
        app_label = 'custom_auth'

    def _format_permission(self, perm, logger=None):
        if logger is not None:
            logger.warning('- Permission content: {}'.format(perm.keys()))
        ct = ContentType.objects.get(id=perm['content_type_id'])
        return '{app_label}.{codename}'.format(app_label=ct.app_label, codename=perm['codename'])

    def _check_group_perm(self, perm, logger):
        from datetime import datetime
        for group in self.groups.all():
            group_perms = [self._format_permission(p) for p in group.permissions.all().values()]
            if logger is not None:
                logger.warning(
                    '{time}: Checking that {perm} is in {group} permissions {group_p}'.format(
                        time=datetime.now().strftime('%d.%m.%Y %H:%M:%S'),
                        perm=perm, group=group, group_p=(perm in group_perms)))
            if perm in group_perms:
                return True
        return False

    def has_perm(self, perm):
        user_perms = [self._format_permission(p, None) for p in self.user_permissions.all().values()]
        return self.is_superuser or perm in user_perms or self._check_group_perm(perm, None)

    def has_perms(self, perms):
        for perm in perms:
            if not self.has_perm(perm):
                return False
        return True

    def has_module_perms(self, app_label):
        return self.is_superuser


class StepRecord(models.Model):
    count = models.IntegerField()
    start = models.DateTimeField()
    end = models.DateTimeField()

    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='step_records')
    sep = models.ForeignKey(SimulatedPeer, on_delete=models.SET_NULL, null=True, blank=True, related_name='step_records')

    class Meta:
        verbose_name_plural = 'Step Record'


class Goal(models.Model):
    value = models.IntegerField()
    start = models.DateTimeField()
    end = models.DateTimeField()
    attained = models.BooleanField(default=False)

    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='goals')

    class Meta:
        verbose_name_plural = 'User Goal'


class Conversation(TimestampMixin, models.Model):
    uuid = models.UUIDField(auto_created=True, default=uuid.uuid4, editable=False)
    user1 = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='user1_conversations')
    user2 = models.ForeignKey(User, on_delete=models.SET_NULL, blank=True, null=True,
                              related_name='user2_conversations')
    simulated_peer = models.ForeignKey(SimulatedPeer, on_delete=models.SET_NULL, blank=True, null=True,
                                       related_name='simulatedpeer_conversations')

    class Meta:
        verbose_name = 'Conversation'


class Message(TimestampMixin, models.Model):
    content = models.TextField(blank=False, null=False)
    author_user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='user_messages')
    author_simulated_peer = models.ForeignKey(SimulatedPeer,
                                              on_delete=models.SET_NULL, blank=True, null=True, related_name='messages')
    conversation = models.ForeignKey(Conversation, on_delete=models.SET_NULL, null=True, related_name='messages')

    class Meta:
        verbose_name = 'Message'


class AnalyticInteraction(TimestampMixin, models.Model):
    action_name = models.CharField(max_length=200, blank=False, null=False)
    target = models.CharField(max_length=500, blank=False, null=False)
    app_version = models.CharField(max_length=50, blank=False, null=False)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='analytic_interactions')

    class Meta:
        verbose_name = 'Analytic Record'