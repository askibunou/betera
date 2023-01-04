with bets_events as (
	select * from bets b inner join events e using (event_id)
),
bets_events_task_1 as (
	select * from bets_events where
		accept_time >= timestamp '2022-03-14 12:00:00' and settlement_time <= timestamp '2022-03-15 12:00:00' and
		event_stage = 'Prematch' and
		bet_type <> 'System' and
		amount >= 10 and
		accepted_bet_odd  >= 1.5 and
		item_result not in ('Cashout', 'Return') and not is_free_bet
),
bets_events_task_2 as (
    select * from bets_events_task_1 where
        sport = 'E-Sports' and
    	bet_type <> 'Express'
),
bets_events_task_3 as (
	select * from bets_events_task_1 where
		bet_id not in (
            select distinct bet_id from bets inner join events using (event_id)
                where sport <> 'E-Sports' or bet_type <> 'Express'
                group by bet_id, event_id, sport
		)
),
bets_events_task_4 as (
	select * from bets_events_task_3 where
		event_id in (
			select event_id from bets_events_task_3
			  group by event_id
			  having MIN(accepted_odd) >= 1.5
		)
	union
	select * from bets_events_task_2
)
select distinct player_id from bets_events_task_4;

