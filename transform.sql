with bets_events as (
	select * from bets b inner join events e using (event_id)
),
-- С 12:00 14.03.2022 сделали ставку в пре-матч на события раздела «Киберспорт».
bets_events_task_1 as (
	select * from bets_events where
		accept_time >= timestamp '2022-03-14 12:00:00' and
		event_stage = 'Prematch' and
		sport = 'E-Sports'
),
-- Минимальная сумма ставки для участия в Бонусном предложении составляет 10 BYN с коэффициентом не менее 1,5,
-- В экспрессе все события на киберспорт с кф каждого события от 1.50
bets_events_task_2_1 as (
	select * from bets_events_task_1 where
		amount >= 10 and
		accepted_bet_odd  >= 1.5
),
bets_events_task_2_2 as (
    select * from bets_events_task_2_1 where
    	bet_type <> 'Express'
    union
	select * from bets_events_task_2_1 where
		event_id in (
			select event_id from bets_events_task_2_1
			  where bet_type = 'Express'
			  group by event_id
			  having MIN(accepted_odd) >= 1.5
		)
),
-- Ставка должна быть рассчитана не позднее 12:00 15.03.2022.
bets_events_task_3 as (
	select * from bets_events_task_2_2 where
		settlement_time <= timestamp '2022-03-15 12:00:00'
),
-- Ставки вида «система» не учитываются.
bets_events_task_4 as (
	select * from bets_events_task_3 where
		bet_type <> 'System'
),
-- Ставки CashOut, возвраты и FreeBet не участвуют в Бонусе.
bets_events_task_5 as (
	select * from bets_events_task_4 where
		 item_result not in ('Cashout', 'Return') and
		 not is_free_bet
)
select distinct player_id from bets_events_task_5

