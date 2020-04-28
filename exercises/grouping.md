# Aggregating

## 1. Find players that won the most matches

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select winner_id, winner_name, count(*) as matches_won
from atp_matches m
group by winner_id, winner_name
order by matches_won desc
```
  
  </p>
</details>

## 2. Find players that won the most matches per given year

`extract(year from <date|timestamp>)` will return year from date or timestamp

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select winner_id, winner_name, extract(year from tourney_date) as year, count(*) as matches_won
from atp_matches m
group by winner_id, winner_name, year
order by matches_won desc, year desc;
```
  
  </p>
</details>


## 3. Find players that won the most tournaments

Field `round` represents what type of the match it was within given tournament.
To win the tournament is to win the final. 

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select winner_name,
       count(*) tournament_wins
from atp_matches
where round = 'F'
group by winner_name
order by tournament_wins desc
```
  
  </p>
</details>

## 4. Find players that won the most tournaments and display tournaments which he/she won
 
Tournament should inform about it's name and year, e.g. `Wimbledon (2008)`,

`string_agg( expression, separator [order_by_clause] )`


<details>
  <summary>Answer</summary>
  <p>
  
```sql
select winner_name,
       count(*) tournament_wins,
       string_agg(tourney_name || ' (' || extract(year from tourney_date) || ')', ', ' order by tourney_date)
from atp_matches
where round = 'F'
group by winner_name
order by tournament_wins desc
```
  
  </p>
</details>


## 5. Find players that won at least 20 tournaments

Display player name & number of tournaments won

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select winner_name,
       count(*) tournament_wins
from atp_matches
where round = 'F'
group by winner_name
having count(*) >= 20
order by tournament_wins desc
```

  </p>
</details>


## 6. Count how many players that won at least 20 tournaments

Display count only

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select count(*)
from (
    select winner_name,
           count(*) tournament_wins
    from atp_matches
    where round = 'F'
    group by winner_name
    having count(*) >= 20
) at_least_20
```

  </p>
</details>

## 7. Find pairs of players (winners vs losers) that finished the game with the same result (who won vs who lost) 

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select winner_name,
       loser_name,
       count(*) matches_played
from atp_matches
group by winner_name, loser_name
order by matches_played desc
```
  
  </p>
</details>

## 8. Find players that have the biggest average wins per tournament 

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select winner_name,
       avg(wins_on_tournament) as wins_per_tournament
from (
         select winner_name, count(*) wins_on_tournament
         from atp_matches
         group by winner_name, tourney_id
     ) subset
group by winner_name
order by wins_per_tournament desc
```
  </p>
</details>

## 9. Find players that have the biggest average wins per tournament but played in at least 20 tournaments

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select winner_name,
       avg(wins_on_tournament) as wins_per_tournament,
       count(*) as tournaments_participated
from (
         select winner_name, count(*) wins_on_tournament
         from atp_matches
         group by winner_name, tourney_id
     ) subset
group by winner_name
having count(*) >= 20
order by wins_per_tournament desc
```
  </p>
</details>

## 10. Find players that have the biggest average wins per tournament but played in at least 20 per decade

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select winner_name,
       decade,
       avg(wins_on_tournament) as wins_per_tournament,
       count(*)                as tournaments_participated
from (
         select winner_name,
                count(*)                                  wins_on_tournament,
                extract(decade from tourney_date) * 10 as decade
         from atp_matches
         group by winner_name, tourney_id, decade
     ) subset
group by winner_name, decade
having count(*) >= 20
order by wins_per_tournament desc
```
  </p>
</details>

## 11. Find player that on each decade have the biggest average wins per tournament but played in at least 20 

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select distinct on (decade) *
from (
         select winner_name,
                decade,
                avg(wins_on_tournament) as wins_per_tournament,
                count(*)                as tournaments_participated
         from (
                  select winner_name,
                         count(*)                                  wins_on_tournament,
                         extract(decade from tourney_date) * 10 as decade
                  from atp_matches
                  group by winner_name, tourney_id, decade
              ) subset
         group by winner_name, decade
         having count(*) >= 20
         order by decade, wins_per_tournament desc
     ) per_decade
```
  
  </p>
</details>

## 12. Find pairs of players that played together the most often

Display how many times they played together

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select *
from (
         select distinct on (pair_id) pair,
                                      (matches_won +
                                       (select count(*)
                                        from atp_matches lost_matches
                                        where won_matches.loser_id = lost_matches.winner_id
                                          and won_matches.winner_id = lost_matches.loser_id)) as total_matches
         from (
                  select winner_name || ' vs ' || loser_name                                   as pair,
                         greatest(winner_id, loser_id) || ' vs ' || least(winner_id, loser_id) as pair_id,
                         winner_id,
                         loser_id,
                         count(*)                                                              as matches_won
                  from atp_matches
                  group by pair, pair_id, winner_id, loser_id
              ) won_matches
         order by pair_id, matches_won desc
     ) sorted
order by total_matches desc
```
  
  </p>
</details>

## 13. Find pairs of players that played together the most often

Display how many times they played together and what is the ratio of wins to loses in order of player names, e.g.

| pair | balance | total
| --- | --- | --- |
| X vs Y | 5:2 | 7

that means that X & Y played together 7 times, 5 of which X won 

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select *
from (
         select distinct on (pair_id) pair,
                                      matches_won || ':' || matches_lost as balance,
                                      matches_won + matches_lost         as total_matches
         from (
                  select pair,
                         pair_id,
                         matches_won,
                         (select count(*)
                          from atp_matches lost_matches
                          where won_matches.loser_id = lost_matches.winner_id
                            and won_matches.winner_id = lost_matches.loser_id) as matches_lost
                  from (
                           select winner_name || ' vs ' || loser_name                                   as pair,
                                  greatest(winner_id, loser_id) || ' vs ' || least(winner_id, loser_id) as pair_id,
                                  winner_id,
                                  loser_id,
                                  count(*)                                                              as matches_won
                           from atp_matches
                           group by pair, pair_id, winner_id, loser_id
                       ) won_matches
              ) total
         order by pair_id, matches_won desc
     ) sortable
order by total_matches desc
```
  
  </p>
</details>

