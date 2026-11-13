from datetime import datetime

from django import forms


class EndRegistrationForm(forms.Form):
    pwd1 = forms.CharField(label='Votre mot de passe', widget=forms.PasswordInput)
    pwd2 = forms.CharField(label='Répétez votre mot de passe', widget=forms.PasswordInput)

    def clean_pwd2(self):
        cleaned_data = super().clean()
        pwd1 = cleaned_data.get('pwd1')
        pwd2 = cleaned_data.get('pwd2')

        if pwd1 != pwd2:
            msg = "La valeur de ce mot de passe est différente de celle entrée dans le premier champs."
            raise forms.ValidationError(msg)


class PasswordResetRequestForm(forms.Form):
    email = forms.EmailField(label='Email', widget=forms.EmailInput)