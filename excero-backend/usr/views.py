from email.mime.multipart import MIMEMultipart

from django.contrib.auth import get_user_model
from django.http import HttpResponsePermanentRedirect
from django.shortcuts import render, get_object_or_404, redirect
from django.utils import timezone
from django.utils.termcolors import background
from rest_framework.exceptions import NotFound

import api.apps
from usr.forms import EndRegistrationForm, PasswordResetRequestForm

User = get_user_model()


def send_user_password_reset_email(user):
    from usr.utils import send_email

    content = '<html><head></head><body>Bonjour {username},<br><br>Nous avons reçu votre demande de réinitialisation de mot de passe.<br>Afin d\'effectuer la réinitialisation merci d\'utiliser le lien suivant: {link}<br><br>N\'hésitez pas à nous contacter en cas de problème.<br><br>Ceci est un message automatique, merci de ne pas y répondre.<br><br>Cordialement,<br>Team Excero</body></html>'.format(
            username=user.username,
            link='<a href="BACKEND ADDRESS/v/users/' + user.password_reset_token + '/resetpassword/">BACKEND ADDRESS/v/users/' + user.password_reset_token + '/resetpassword/</a>',
        )
    send_email(user, content)


def set_newuser_passwd(request, uuid):
    user = get_object_or_404(User, password_set_token=uuid, password_set_date__gte=timezone.now())
    success = None
    if request.method == 'POST':
        form = EndRegistrationForm(request.POST)
        if form.is_valid():
            user = get_object_or_404(User, password_set_token=uuid, password_set_date__gte=timezone.now())
            user.set_password(form.cleaned_data['pwd1'])
            user.password_set_token = None
            user.password_set_date = None
            user.password_reset_token = None
            user.password_reset_date = None
            user.save()
            success = "Vous avez terminée la procédure de mise en route, vous pouvez maintenant quitter la page."
    else:
        form = EndRegistrationForm(initial={'pwd1': '', 'pwd2': ''})
    context = {
        "success": success,
        "form": form,
        "user": user
    }
    return render(request, "users/endreg.html", context)


def reset_user_passwd(request, reset_token):
    user = get_object_or_404(User, password_reset_token=reset_token, password_reset_date__gte=timezone.now())
    success = None
    if request.method == 'POST':
        form = EndRegistrationForm(request.POST)
        if form.is_valid():
            user = get_object_or_404(User, password_reset_token=reset_token, password_reset_date__gte=timezone.now())
            user.set_password(form.cleaned_data['pwd1'])
            user.password_set_token = None
            user.password_set_date = None
            user.password_reset_token = None
            user.password_reset_date = None
            user.save()
            success = "Votre mot de passe a été réinitialisé avec succès, vous pouvez maintenant quitter la page."
    else:
        form = EndRegistrationForm(initial={'pwd1': '', 'pwd2': ''})
    context = {
        "success": success,
        "form": form,
        "user": user
    }
    return render(request, "users/resetpassword.html", context)


def reset_user_email(request):
    import uuid
    from datetime import timedelta
    success = None
    if request.method == 'POST':
        form = PasswordResetRequestForm(request.POST)
        if form.is_valid():
            user = get_object_or_404(User, email=form.cleaned_data['email'])
            user.password_set_token = None
            user.password_set_date = None
            user.password_reset_token = uuid.uuid4().hex
            user.password_reset_date = timezone.now() + timedelta(days=1)
            user.save()
            success = "Vous allez prochainement recevoir les instructions de réinitialisation, vous pouvez maintenant quitter la page."
            send_user_password_reset_email(user)
    else:
        form = PasswordResetRequestForm()
    context = {
        "success": success,
        "form": form,
    }
    return render(request, "users/resetreq.html", context)

def activation_email(request, uuid):
    user = get_object_or_404(User, password_set_token=uuid, password_set_date__gte=timezone.now())
    from segno import make_qr
    qrcode = make_qr('excero://set?t=' + uuid)
    context = {
        "userlink": '/v/users/communication/' + uuid + '/',
        "username": user.username,
        "qrcode": qrcode.png_data_uri(scale=6, border=2, light='white'),
    }
    return render(request, "users/activation_email_final.html", context)


class ExceroHttpResponsePermanentRedirect(HttpResponsePermanentRedirect):
    allowed_schemes = ['excero',]


def deep_activation_email(request, token):
    if User.objects.filter(password_set_token=token).exists():
        return ExceroHttpResponsePermanentRedirect('excero://set?t=' + token)
    else:
        raise NotFound()
