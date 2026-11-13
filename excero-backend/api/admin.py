from django.contrib import admin

# Register your models here.
from django.contrib.admin import ModelAdmin

from api.models import ExperimentalCondition, Avatar, SimulatedPeer, AvatarType, AvatarPiece, InterventionWeek, \
    SimulatedPeerModel
from custom_auth.models import StepRecord, Goal, Conversation, Message, AnalyticInteraction


class ExperimentalConditionAdmin(ModelAdmin):
    list_display = ('acronym', 'start', 'end', )


class StepRecordAdmin(ModelAdmin):
    list_display = ('start', 'end', 'count', 'user', )
    list_select_related = ('user', )


class GoalAdmin(ModelAdmin):
    list_display = ('start', 'end', 'attained', 'value', 'user', )
    list_select_related = ('user', )


class AvatarAdmin(ModelAdmin):
    list_display = ('type', 'created_at', 'updated_at', )


class AvatarPieceAdmin(ModelAdmin):
    list_display = ('name', 'created_at', 'updated_at', 'type', )
    list_select_related = ('type', )


class AvatarTypeAdmin(ModelAdmin):
    list_display = ('type_name', 'created_at', 'updated_at', )


class SimulatedPeerModelAdmin(ModelAdmin):
    list_display = ('avatar', 'preview', )
    list_select_related = ('avatar', )


class SimulatedPeerAdmin(ModelAdmin):
    list_display = ('name', 'simulated_peer_model', )
    list_select_related = ('simulated_peer_model', )


class ConversationAdmin(ModelAdmin):
    list_display = ('uuid', 'user1', 'user2', 'simulated_peer', )
    list_select_related = ('user1', 'user2', 'simulated_peer', )


class MessageAdmin(ModelAdmin):
    list_display = ('created_at', 'conversation', )


class InterventionWeekAdmin(ModelAdmin):
    list_display = ('begin', 'end', )


class AnalyticInteractionAdmin(ModelAdmin):
    list_display = ('target', 'action_name', 'user', )
    list_select_related = ('user', )


admin.site.register(ExperimentalCondition, ExperimentalConditionAdmin)
admin.site.register(StepRecord, StepRecordAdmin)
admin.site.register(Goal, GoalAdmin)
admin.site.register(Avatar, AvatarAdmin)
admin.site.register(SimulatedPeerModel, SimulatedPeerModelAdmin)
admin.site.register(SimulatedPeer, SimulatedPeerAdmin)
admin.site.register(Conversation, ConversationAdmin)
admin.site.register(Message, MessageAdmin)
admin.site.register(AvatarType, AvatarTypeAdmin)
admin.site.register(AvatarPiece, AvatarPieceAdmin)
admin.site.register(InterventionWeek, InterventionWeekAdmin)
admin.site.register(AnalyticInteraction, AnalyticInteractionAdmin)
