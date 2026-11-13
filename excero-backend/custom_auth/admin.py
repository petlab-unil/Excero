from django import forms
from django.contrib import admin

# Register your models here.
from django.contrib.admin import ModelAdmin, TabularInline
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from backend import settings
from custom_auth.models import User, StepRecord


class CustomUserCreationForm(forms.ModelForm):
    password1 = forms.CharField(label='Password', widget=forms.PasswordInput)
    password2 = forms.CharField(label='Password Confirmation', widget=forms.PasswordInput)

    class Meta:
        model = User
        fields = ('email', 'username', )

    def clean_password2(self):
        password1 = self.cleaned_data.get('password1')
        password2 = self.cleaned_data.get('password2')

        if password1 and password2 and password1 != password2:
            raise forms.ValidationError('Passwords don\'t match')
        return password2

    def save(self, commit=True):
        import uuid
        from usr.utils import send_email
        from django.template.loader import render_to_string
        from segno import make_qr

        user = super().save(commit=False)
        user.username = user.username
        user.email = user.email
        user.set_password(self.cleaned_data.get('password1'))
        user.password_set_token = uuid.uuid4().hex
        if commit:
            user.save()
        if settings.DEV:
            META = {'HTTP_HOST': 'localhost:8000'}
        else:
            META = {'HTTP_HOST': 'BACKEND ADDRESS'}

        qrcode = make_qr('excero://set?t=' + user.password_set_token)
        context = {
            "userlink": '/v/users/communication/' + user.password_set_token + '/',
            "username": user.username,
            "qrcode": qrcode.png_data_uri(scale=6, border=2, light='white'),
            "request": {'scheme': 'https', 'META': META}
        }

        content = render_to_string("users/activation_email_final.html", context)
        #content = '<html><head></head><body>Bonjour {username},<br><br>Votre compte vient d\'être créé.<br><br>Afin de terminer votre inscription veuiller définir votre mot de passe en utilisant le lien suivant: {link}<br><br>N\'hésitez pas à nous contacter en cas de problème.<br><br>Vous pouvez maintenant télécharger l\'application Excero par le biais de la plateforme <a href="TESTFLIGHT LINK">Testflight d\'Apple</a>, pour ce faire, rendez-vous sur le lien suivant: <a href="TESTFLIGHT LINK">TESTFLIGHT LINK</a>.<br>Vous trouverez ci-joint les explications sur l\'application et son fonctionnement.<br><br>Ceci est un message automatique, merci de ne pas y répondre.<br><br>Cordialement,<br>Team Excero</body></html>'.format(
        #    username=user.username,
        #    link='<a href="BACKEND ADDRESS/v/users/' + user.password_set_token + '/endreg/">BACKEND ADDRESS/v/users/' + user.password_set_token + '/endreg/</a>',
        #)
        send_email(user, content, 'Excero - Activation de votre compte', settings.STATIC_ROOT + '/resources/excero_user_guide.pdf')
        return user


class StepRecordInline(TabularInline):
    model = StepRecord


class UserAdmin(BaseUserAdmin):
    add_form = CustomUserCreationForm
    filter_horizontal = ['groups', 'user_permissions']
    fieldsets = (
        ('User Credentials', {
            'fields': ('email', 'username', 'password', 'fcm_token', 'password_set_token', 'password_set_date',
                       'password_reset_token', 'password_reset_date')
        }),
        ('User Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser','groups', 'user_permissions', )
        }),
        ('Experiment Attributes', {
            'fields': ('experimental_condition', 'avatar', 'simulated_peer', )
        })
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide', ),
            'fields': ('email', 'username', 'password1', 'password2', )
        }),
    )
    list_display = ('username', )
    #inlines = [StepRecordInline, ]


admin.site.register(User, UserAdmin)

