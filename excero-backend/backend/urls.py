"""backend URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import SimpleRouter
from rest_framework_nested.routers import NestedSimpleRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from api.views import UserViewSet, StepRecordViewSet, AvatarViewSet, GoalViewSet, ExperimentalConditionViewSet, \
    SimulatedPeerViewSet, UserAvatarViewSet, UserStepRecordViewSet, UserSimulatedPeerViewSet, UserGoalViewSet, \
    ConversationViewSet, MessageViewSet, ConversationMessagesViewSet, AvatarTypeViewSet, AvatarTypeAvatarPiecesViewSet, \
    AvatarPieceViewSet, UserOwnViewSet, InterventionWeekViewSet, SimulatedPeerModelViewSet, \
    FirebaseNotificationsAPIView, GoalSettingsView, UserAdminView, BugAdminView, AnalyticInteractionViewSet, \
    UserAnalyticInteractionViewSet, SimulatedPeerStepRecordViewSet, UserConversationViewSet, AppReportView
from custom_auth.views import FirebaseTokenObtainPairView
from usr.views import set_newuser_passwd, reset_user_passwd, reset_user_email, activation_email, deep_activation_email

router = SimpleRouter(trailing_slash=True)
router.register(r'users', UserViewSet, basename='user')
router.register(r'steps', StepRecordViewSet, basename='steprecord')
router.register(r'avatars', AvatarViewSet, basename='avatar')
router.register(r'goals', GoalViewSet, basename='goal')
router.register(r'expcond', ExperimentalConditionViewSet, basename='experimentalcondition')
router.register(r'simpeer', SimulatedPeerViewSet, basename='simulatedpeer')
router.register(r'conversations', ConversationViewSet, basename='conversation')
router.register(r'messages', MessageViewSet, basename='message')
router.register(r'avatartypes', AvatarTypeViewSet, basename='avatartype')
router.register(r'avatarpieces', AvatarPieceViewSet, basename='avatarpiece')
router.register(r'interventions', InterventionWeekViewSet, basename='interventionweek')
router.register(r'simpeermodels', SimulatedPeerModelViewSet, basename='simulatedpeermodel')
router.register(r'analytics', AnalyticInteractionViewSet, basename='analytic')

users_router = NestedSimpleRouter(router, r'users', lookup='user')
users_router.register(r'steps', UserStepRecordViewSet, basename='user-steprecord')
users_router.register(r'avatars', UserAvatarViewSet, basename='user-avatar')
users_router.register(r'goals', UserGoalViewSet, basename='user-goal')
users_router.register(r'simpeer', UserSimulatedPeerViewSet, basename='user-simulatedpeer')
users_router.register(r'peer', UserViewSet, basename='peer')
users_router.register(r'analytics', UserAnalyticInteractionViewSet, basename='user-analytic')
users_router.register(r'conversations', UserConversationViewSet, basename='user-conversation')

simulated_peer_router = NestedSimpleRouter(router, r'simpeer', lookup='simulatedpeer')
simulated_peer_router.register(r'avatars', AvatarViewSet, basename='simulatedpeer-avatar')
simulated_peer_router.register(r'steps', SimulatedPeerStepRecordViewSet, basename='simulatedpeer-steprecord')

conversations_router = NestedSimpleRouter(router, r'conversations', lookup='conversation')
conversations_router.register(r'messages', ConversationMessagesViewSet, basename='conversation-message')

avatartypes_router = NestedSimpleRouter(router, r'avatartypes', lookup='avatartype')
avatartypes_router.register(r'pieces', AvatarTypeAvatarPiecesViewSet, basename='avatartype-avatarpiece')


urlpatterns = [
    path('api/token/', TokenObtainPairView.as_view()),
    path('api/token/refresh/', TokenRefreshView.as_view()),
    path('api/fb/token/', FirebaseTokenObtainPairView.as_view()),
    path('api/fb/notifications/', FirebaseNotificationsAPIView.as_view()),
    path('api/admin/reports/users/', UserAdminView.as_view()),
    path('api/admin/reports/bugs/', BugAdminView.as_view()),
    path('api/admin/reports/crash/', AppReportView.as_view()),
    #path('api/goal_setting/', GoalSettingsView.as_view()),
    path('api/', include(router.urls)),
    path('api/', include(users_router.urls)),
    path('api/', include(simulated_peer_router.urls)),
    path('api/', include(conversations_router.urls)),
    path('api/', include(avatartypes_router.urls)),
    path('v/users/<str:uuid>/endreg/', set_newuser_passwd, name='endreg'),
    path('v/users/<str:reset_token>/resetpassword/', reset_user_passwd, name='resetpassword'),
    path('v/users/reset/', reset_user_email, name='reset'),

    path('v/users/communication/<str:uuid>/', activation_email, name='communication'),
    path('v/users/da/<str:token>/', deep_activation_email, name='deepactivate'),
    path('admin/', admin.site.urls),
]
