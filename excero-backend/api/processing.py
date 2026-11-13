
def _normalize_dataset(df):
    import numpy as np

    def apply_l2(r):
        w = np.sqrt(np.sum(r ** 2))
        x_norm2 = r / w
        return x_norm2, w

    result = []
    ws = []

    for row in df:
        row_n, weight = apply_l2(row)
        result.append(row_n)
        ws.append(weight)

    return np.array(result), ws


def _denormalize_dataset(df, ws):
    import numpy as np

    def reverse_l2(r, w):
        return r * w

    result = []

    for row, weight in zip(df, ws):
        row_n = reverse_l2(row, weight)
        result.append(row_n)

    return np.array(result)


"""def compute_weekly_goal(user_dataset, user_id):
    import pandas as pd
    import numpy as np
    from sklearn.ensemble import GradientBoostingRegressor
    from joblib import load, dump
    from os.path import exists
    from backend.settings import MODELS_DIR

    converted_data = []
    for d in user_dataset:
        converted_data.append([d.start.day, d.start.month, d.start.year, d.count])

    df = (pd.DataFrame(converted_data, columns=['day_of_month', 'month', 'year', 'steps']).apply(lambda x: x.values)
          .to_numpy())
    df_norm, user_weights = _normalize_dataset(df)
    model = None
    user_model_file = MODELS_DIR + 'goal_' + str(user_id) + '.joblib'
    #if exists(user_model_file):
    #    model = load(user_model_file)
    #else:
    model = GradientBoostingRegressor()
    model.fit(df_norm[:, 0:3], df_norm[:, 3])
    print('Fitting model')
    dump(model, user_model_file)

    from datetime import datetime, timedelta
    current_date = datetime.now()
    next_week = []
    for x in range(0, 7):
        new_date = current_date + timedelta(days=x+1)
        next_week.append([new_date.day, new_date.month, new_date.year])
    week = np.array(next_week)
    week_norm, user_week_weights = _normalize_dataset(week)
    y_steps_norm = model.predict(week_norm)
    y_steps_pred = _denormalize_dataset(y_steps_norm, user_week_weights)
    print(y_steps_pred)
    sum_estimated_steps = np.sum(y_steps_pred)
    return sum_estimated_steps"""


