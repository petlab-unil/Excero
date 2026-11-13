import os

import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()


from django.contrib.auth import get_user_model

from api.models import SimulatedPeerModel, SimulatedPeer, ExperimentalCondition
from custom_auth.models import Conversation

User = get_user_model()


def activate_user_mail(user):
    import uuid
    from usr.utils import send_email
    from segno import make_qr
    from django.template.loader import render_to_string
    from backend.settings import DEV, STATIC_ROOT

    if DEV:
        META = {'HTTP_HOST': 'localhost:8000'}
    else:
        META = {'HTTP_HOST': 'BACKEND ADDRESS'}

    set_url = 'https://' + META['HTTP_HOST'] + '/v/users/da/' + user.password_set_token
    qrcode = make_qr('excero://set?t=' + user.password_set_token)
    qr_path = str(uuid.uuid4()) + '.png'
    qrcode.save(STATIC_ROOT + '/resources/' + qr_path, scale=6, border=2, light='white')
    context = {
        "userlink": '/v/users/communication/' + user.password_set_token + '/',
        "username": user.username,
        "qrcode": qr_path,
        "activation_url": set_url,
        "request": {'scheme': 'https', 'META': META}
    }

    content = render_to_string("users/activation_email_final.html", context)
    send_email(user, content, 'Excero - Activation de votre compte',
               STATIC_ROOT + '/resources/excero_user_guide.pdf')


def create_user(email, pseudonym, experimental_condition, peer=None, sep_model=None, group=None):
    import uuid
    from django.utils import timezone
    from datetime import datetime, timedelta
    if User.objects.filter(username=pseudonym).exists():
        print("USER WITH PSEUDONYM {} ALREADY EXISTS".format(pseudonym))
    user = User.objects.create_user(email=email,
                                    username=pseudonym,
                                    password=str(uuid.uuid4()))
    user.experimental_condition = experimental_condition
    user.password_set_token = str(uuid.uuid4())
    user.password_set_date = timezone.now() + timedelta(days=10)
    user.save()
    if group is not None:
        user.groups.add(group)
    print('Created user {}'.format(user.username))
    if experimental_condition.acronym == 'HUM':
        conversation = Conversation()
        conversation.user1 = user
        if User.objects.filter(username=peer['pseudonym']).exists():
            print("USER WITH PSEUDONYM {} ALREADY EXISTS".format(pseudonym))
        peer_user = User.objects.create_user(email=peer['email'],
                                    username=peer['pseudonym'],
                                    password=str(uuid.uuid4()))
        peer_user.experimental_condition = experimental_condition
        peer_user.password_set_token = str(uuid.uuid4())
        peer_user.password_set_date = timezone.now() + timedelta(days=10)
        peer_user.save()
        if group is not None:
            peer_user.groups.add(group)
        print('Created peer user {}'.format(peer_user.username))
        conversation.user2 = peer_user
        conversation.save()
        activate_user_mail(peer_user)
    elif experimental_condition.acronym == 'SEP':
        if sep_model is not None:
            model = sep_model
            sep = SimulatedPeer()
            sep.name = 'Alex'
            sep.simulated_peer_model = model
            sep.save()
            conversation = Conversation()
            conversation.user1 = user
            conversation.simulated_peer = sep
            conversation.save()
            user.simulated_peer = sep
            user.save()
            if group is not None:
                user.groups.add(group)
    activate_user_mail(user)

def create_human_human_pairings(df):
    from itertools import product
    from random import shuffle
    print('Starting Human-Human pairing process')
    print('Here is a glimpse of your dataset by Gender:')
    print(df['Gender'].value_counts())

    genders = df['Gender'].unique()
    couple_ns = {}
    if len(genders) > 1:
        print('There are more than one gender.')
        for gender in genders:
            g_couple = input('How many couple of the same gender({gender}) do you want? '.format(gender=gender))
            couple_ns[gender] = int(g_couple)

        print('Should mixed couple be considered?')
        gender_combinations = product(genders, genders)
        for g_1, g_2 in gender_combinations:
            if g_1 == g_2:
                continue
            g_couple = input('How many couple of the combination {g_1}-{g_2} do you want? '.format(g_1=g_1, g_2=g_2))
            couple_ns[(g_1, g_2)] = int(g_couple)

    hum_couples = []
    attributed_pidx = []
    for gender, couple_n in couple_ns.items():
        if type(gender) is tuple:
            df_g_1 = df.query('Gender == "{}"'.format(gender[0]))
            df_g_2 = df.query('Gender == "{}"'.format(gender[1]))
            avail_g_1_ids = [id for id in df_g_1.index.to_list() if id not in attributed_pidx]
            avail_g_2_ids = [id for id in df_g_2.index.to_list() if id not in attributed_pidx]
            shuffle(avail_g_1_ids)
            shuffle(avail_g_2_ids)
            for i in range(0, couple_n):
                id_g_1 = avail_g_1_ids[0]
                id_g_2 = avail_g_2_ids[0]
                del avail_g_1_ids[0]
                del avail_g_2_ids[0]
                attributed_pidx.append(id_g_1)
                attributed_pidx.append(id_g_2)
                hum_couples.append((df_g_1.loc[id_g_1], df_g_2.loc[id_g_2]))
        else:
            df_g = df.query('Gender == "{}"'.format(gender))
            avail_g_ids = [id for id in df_g.index.to_list() if id not in attributed_pidx]
            shuffle(avail_g_ids)
            for i in range(0, couple_n, 2):
                id_g_1 = avail_g_ids[0]
                id_g_2 = avail_g_ids[1]
                del avail_g_ids[0]
                del avail_g_ids[0]
                attributed_pidx.append(id_g_1)
                attributed_pidx.append(id_g_2)
                hum_couples.append((df_g.loc[id_g_1], df_g.loc[id_g_2]))

    print('Created a total of {n} couples'.format(n=len(hum_couples)))

    return hum_couples


def create_sep_pairings(df):
    print('Starting Human-SEP pairing process')
    print('Here is a glimpse of your dataset by Gender:')
    print(df['Gender'].value_counts())

    genders = df['Gender'].unique()
    sep_models = list(SimulatedPeerModel.objects.all())
    print('The system has detected {n} models in your database.'.format(n=len(sep_models)))
    sep_pairs = []
    df_avail = df.copy()
    for gender in genders:
        for sep_model in sep_models:
            n_for_model = input('How many participants with gender {gender} do you want to associate with SEP model ID {id}'.format(gender=gender, id=sep_model.id))
            n_for_model = int(n_for_model)
            df_parts = df_avail.query('Gender == "{}"'.format(gender)).sample(n=n_for_model)
            df_avail = df_avail.drop(df_parts.index, axis=0)
            for index, row in df_parts.iterrows():
                sep_pairs.append((row, sep_model))

    return sep_pairs



def create_users(participant_file):
    import pandas as pd
    from django.contrib.auth.models import Group
    df = pd.read_csv(participant_file)
    total_men = df.query('Gender == "Male"').shape[0]
    total_women = df.query('Gender == "Female"').shape[0]
    men_per_condition = int(total_men / 4)
    women_per_condition = int(total_women / 4)
    assigned_men = 0
    assigned_women = 0

    print('Here is a glimpse of your dataset by Gender:')
    print(df['Gender'].value_counts())

    genders = df['Gender'].unique()
    total_by_genders = df.groupby('Gender').count()

    expconds = list(ExperimentalCondition.objects.all())
    print('The system has identified {n} conditions in the database, with the following acronyms:\n- {conditions}'.format(n=len(expconds), conditions='\n- '.join([exp.acronym for exp in expconds])))
    conditional_assignment = {}
    df_avail = df.copy()
    for condition in expconds:
        assign_r = input('Do you want to assign participants to condition: {condition} [y/N]'.format(condition=condition.acronym))
        if assign_r.lower() != 'y':
            if assign_r.lower() != 'yes':
                continue
        for gender in genders:
            assign_gender = input('-- [{condition}] How many participants with gender: {gender} do you want to assign? '.format(condition=condition.acronym, gender=gender))
            if assign_gender == '0' or not assign_gender.isnumeric():
                continue
            n_participants = int(assign_gender)
            avail_parts = df_avail.query('Gender == "{}"'.format(gender)).shape[0]
            if n_participants > avail_parts:
                print('This number exceeds current available participants in that gender. Number has been changed to the maximum of participants available for that gender {n}'.format(n=avail_parts))
            df_sample = df_avail.query('Gender == "{}"'.format(gender)).sample(n=n_participants, axis=0)
            if condition.acronym in conditional_assignment.keys():
                conditional_assignment[condition.acronym].append(df_sample)
            else:
                conditional_assignment[condition.acronym] = [df_sample]
            df_avail = df_avail.drop(df_sample.index, axis=0)
            print('-- [{condition}] Assigned {n} participants with gender {gender} to condition {condition}'.format(n=n_participants, gender=gender, condition=condition.acronym))

    df_hum = None
    df_sep = None
    df_con = None
    if 'HUM' in conditional_assignment.keys() and len(conditional_assignment['HUM']) > 0:
        df_hum = pd.concat(conditional_assignment['HUM'], axis=0)
    if 'SEP' in conditional_assignment.keys() and len(conditional_assignment['SEP']) > 0:
        df_sep = pd.concat(conditional_assignment['SEP'], axis=0)
    if 'CON' in conditional_assignment.keys() and len(conditional_assignment['CON']) > 0:
        df_con = pd.concat(conditional_assignment['CON'])
    if df_hum is not None:
        hum_couples = create_human_human_pairings(df_hum)
    else:
        hum_couples = []
    if df_sep is not None:
        sep_couples = create_sep_pairings(df_sep)
    else:
        sep_couples = []
    participant_group = Group.objects.get(name='Participant')
    print('Starting user creations')
    print('-- Starting HUM condition users')
    hum_condition = ExperimentalCondition.objects.get(acronym='HUM')
    for u_1, u_2 in hum_couples:
        user_2_dict = {'pseudonym': u_2['Pseudonym'], 'email': u_2['Email']}
        create_user(u_1['Email'], u_1['Pseudonym'], hum_condition, peer=user_2_dict, group=participant_group)
    print('-- Finished creating HUM condition users')
    print('-- Starting SEP condition users')
    sep_condition = ExperimentalCondition.objects.get(acronym='SEP')
    for u, sep_model in sep_couples:
        create_user(u['Email'], u['Pseudonym'], sep_condition, peer=None, sep_model=sep_model, group=participant_group)
    print('-- Finished creating SEP condition users')
    print('-- Starting CON condition users')

    con_condition = ExperimentalCondition.objects.get(acronym='CON')
    if df_con is not None:
        for index, u in df_con.iterrows():
            create_user(u['Email'], u['Pseudonym'], con_condition, group=participant_group)
    print('-- Finished creating CON condition users')

    print('-- Post assignment verification')
    users = User.objects.all()
    pseudonyms = [user.username for user in users]
    df_pseudo = df['Pseudonym'].to_list()
    remaining_users = [x for x in df_pseudo if x not in pseudonyms]
    if len(remaining_users) > 0:
        print('/!\ There are still participants that haven\'t been assigned.')
        print(remaining_users)
    else:
        print('All participants have been assigned.')
    print('-- End of post assignment verification')
    df_assignments = pd.DataFrame()
    for condition, dfs in conditional_assignment.items():
        condition_df = pd.concat(dfs, axis=0)
        cond_sr = pd.Series([condition for i in range(0, condition_df.shape[0])], index=condition_df.index)
        condition_df['Condition'] = cond_sr
        df_assignments = pd.concat([df_assignments, condition_df], axis=0)
    from datetime import datetime
    output_filename = 'experiment_assignements_{}.csv'.format(datetime.now().strftime('%d%m%Y_%H%M%S'))
    print('-- Reporting assignments to {}'.format(output_filename))
    df_assignments.to_csv(output_filename)
    print('-- Finished assignments.')

if __name__ == '__main__':
    import os
    from argparse import ArgumentParser
    file_input = os.path.abspath('') + '/test_auto_assignment.csv'
    import custom_auth.utils
    parser = ArgumentParser(prog='Excero Participant Util',
                            description='Utilitary tool to import participants in Excero.')
    parser.add_argument('--file', nargs='?', help='input file')
    args = parser.parse_args()
    if args.file is not None:
        file_input = args.file

    print('Using input file {}'.format(file_input))
    custom_auth.utils.create_users(file_input)
