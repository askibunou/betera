import logging
import os
import pandas as pd
import sqlalchemy
import argparse
from sqlalchemy import create_engine

DB_URL = os.getenv('DB_URL')


def extract(bets_path, events_path):
    df_bets = pd.read_csv(filepath_or_buffer=bets_path)
    df_events = pd.read_csv(filepath_or_buffer=events_path)
    return df_bets, df_events


def transform(df_bets, df_events):
    df = pd.merge(df_bets, df_events, on='event_id', how='inner')

    # С 12:00 14.03.2022 сделали ставку в пре-матч на события раздела «Киберспорт».
    df = df[df.accept_time >= '2022-03-14 12:00:00']
    df = df[df.event_stage == 'Prematch']
    df = df[df.sport == 'E-Sports']

    # Минимальная сумма ставки для участия в Бонусном предложении составляет 10 BYN с коэффициентом не менее 1,5,
    # в экспрессе все события на киберспорт с кф каждого события от 1.50
    df = df[df.amount >= 10]
    df = df[df.accepted_bet_odd >= 1.5]

    df_exp = df[df.bet_type == 'Express']
    df_exp = df_exp[df_exp.accepted_odd >= 1.5]

    df_oth = df[df.bet_type != 'Express']

    df = pd.concat([df_exp, df_oth])

    # Ставка должна быть рассчитана не позднее 12:00 15.03.2022.
    df = df[df.settlement_time <= '2022-03-15 12:00:00']

    # Ставки вида «система» не учитываются.
    df = df[df.bet_type != 'System']

    # Ставки CashOut, возвраты и FreeBet не участвуют в Бонусе.
    df = df[~df.item_result.isin(('Cashout', 'Return'))]
    df = df[~df.is_free_bet]

    df_players = df["player_id"].drop_duplicates()
    return df_players


def load(df, table, load_mode, schema=None):
    # Create engine for database
    engine = create_engine(DB_URL)

    # Load data
    df.to_sql(name=table, con=engine, index=False, if_exists=load_mode, dtype=schema)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,
                        format='%(asctime)s - %(name)s - %(levelname)s:\n %(message)s')

    parser = argparse.ArgumentParser()

    parser.add_argument('--bets_path', default='data/bets.csv', type=str)
    parser.add_argument('--events_path', default='data/events.csv', type=str)

    parser.add_argument('--table', default='players', type=str)
    parser.add_argument('--load_mode', default='replace', type=str)

    args = parser.parse_args()

    # extract
    bets, events = extract(args.bets_path, args.events_path)

    # transform
    players = transform(bets, events)

    # load
    schema = dict(player_id=sqlalchemy.String)
    load(players, args.table, args.load_mode, schema)

    # Logging
    logging.info(players)