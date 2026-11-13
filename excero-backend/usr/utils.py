from email import encoders
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from pathlib import Path

from django.contrib.auth import get_user_model

User = get_user_model()


def send_email(user: User, content: str, title: str = 'Excero - Réinitialisation de votre mot de passe', attachment=None):
    import smtplib
    from email.message import EmailMessage
    from email.mime.text import MIMEText
    from backend.settings import EMAIL_SMTP_SERVER, EMAIL_SMTP_PORT, \
        EMAIL_SMTP_USER, EMAIL_SMTP_PASSWORD, \
        EMAIL_SMTP_SENDER, EMAIL_SMTP_RECIPIENTS

    email = MIMEMultipart('alternative')
    email['Subject'] = title
    email['From'] = EMAIL_SMTP_SENDER
    email['To'] = user.email

    if attachment is not None:
        part = MIMEBase('application', "octet-stream")
        with open(attachment, 'rb') as file:
            part.set_payload(file.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition',
                        'attachment; filename={}'.format(Path(attachment).name))
        email.attach(part)

    email.attach(MIMEText(content, 'html'))
    mail = smtplib.SMTP_SSL(EMAIL_SMTP_SERVER, EMAIL_SMTP_PORT)
    mail.ehlo()
    mail.login(EMAIL_SMTP_USER, EMAIL_SMTP_PASSWORD)
    mail.send_message(email)
    mail.close()