from django.contrib.auth import get_user_model

from api.models import SimulatedPeer
from custom_auth.models import Conversation, Message

User = get_user_model()


def run_openai_chat(conversation: Conversation, sep: SimulatedPeer, user: User, user_input: str):
    from openai import OpenAI
    from datetime import datetime, timedelta
    from django.utils import timezone
    from custom_auth.models import StepRecord, Goal, Message
    from django.db.models import Sum
    from backend.settings import OPENAI_API_KEY, OPENAI_MODEL, DEBUG

    lastweek = timezone.now() - timedelta(days=7)
    steps_done = None

    steps_lastweek = StepRecord.objects.filter(user=user, start__lte=lastweek, end__gte=lastweek) \
        .aggregate(Sum('count'))['count__sum']

    current_goal = Goal.objects.filter(user=user, start__lte=timezone.now(), end__gte=timezone.now()).first()
    if current_goal is not None:
        steps_done = StepRecord.objects.filter(user=user, start__lte=current_goal.start, end__gte=current_goal.end) \
            .aggregate(Sum('count'))['count__sum']
    else:
        current_goal = {'value': 70000}

    if steps_done is None:
        steps_done = 0

    today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = timezone.now().replace(hour=23, minute=59, second=59, microsecond=0)
    steps_today = StepRecord.objects.filter(user=user, start__gte=today_start, end__lte=today_end) \
        .aggregate(Sum('count'))['count__sum']

    if steps_today is None:
        steps_today = 0

    steps_per_day = current_goal['value'] / 7
    steps_remaining_for_goal = current_goal['value'] - steps_done
    steps_remaining_today = steps_per_day - steps_today

    sep_initial_instruction = sep.simulated_peer_model.initial_prompt.format(sep_name=sep.name, username=user.username)
    sep_repeated_prompt = sep.simulated_peer_model.repeated_prompt

    repeated_prompt_data = {}
    if sep_repeated_prompt is not None:
        if 'username' in sep_repeated_prompt:
            repeated_prompt_data['username'] = user.username
        if 'sep_name' in sep_repeated_prompt:
            repeated_prompt_data['sep_name'] = sep.name
        if 'current_date' in sep_repeated_prompt:
            repeated_prompt_data['current_date'] = datetime.now().strftime("%d.%m.%Y")
        if 'current_time' in sep_repeated_prompt:
            repeated_prompt_data['current_time'] = datetime.now().strftime("%H:%M:%S")
        if 'weekly_goal' in sep_repeated_prompt:
            repeated_prompt_data['weekly_goal'] = str(steps_remaining_for_goal)
        if 'steps_remaining_today' in sep_repeated_prompt:
            repeated_prompt_data['steps_remaining_today'] = str(steps_remaining_today)
        if 'steps_remaining_week' in sep_repeated_prompt:
            repeated_prompt_data['steps_remaining_week'] = str(steps_remaining_for_goal)
        if 'steps_dayhour_lastweek' in sep_repeated_prompt:
            repeated_prompt_data['steps_dayhour_lastweek'] = str(steps_lastweek)

    sep_contextual_prompt = sep_repeated_prompt.format(**repeated_prompt_data)

    conversation_history = []
    conversation_messages = Message.objects.filter(conversation=conversation)
    for message in conversation_messages:
        msg = {'content': message.content}
        if message.author_user is None:
            msg['role'] = 'assistant'
        else:
            msg['role'] = 'user'
        conversation_history.append(msg)

    client = OpenAI(
        api_key=OPENAI_API_KEY,
    )

    m_history = []
    if len(conversation_history) > 10:
        m_history = conversation_history[-10:]
    else:
        m_history = conversation_history
    openai_payload = [
            {
                "role": "system",
                "content": sep_initial_instruction,
            },
        ] + m_history + [
            {
                "role": "system",
                "content": sep_contextual_prompt,
            },
            {
                "role": "user",
                "content": user_input,
            }
        ]

    if DEBUG:
        print(openai_payload)

    chat_completion = client.chat.completions.create(
        messages=openai_payload,
        model=OPENAI_MODEL,
    )

    chat_content = chat_completion.choices[0].message.content
    if DEBUG:
        print('Agent response:', chat_content)

    return chat_content