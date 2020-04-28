# Window functions

## 1. Rank the longest matches

List winner, loser, duration and rank

`rank() over (order by <ranking field> asc|desc)` will display the ranking of records over ordered window. Rank will skip positions when 2 or more rows has same value by which ranking takes place

<details>
  <summary>Answer</summary>
  <p>
  
```sql
 select
        winner_name,
        loser_name,
        minutes,
        rank() over (order by minutes desc nulls last)
 from atp_matches
```
  
  </p>
</details>

## 2. Rank players that won the most tournaments

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select
       winner_name,
       tournament_wins,
       rank() over (order by tournament_wins desc)
from (
         select winner_name, count(*) tournament_wins
         from atp_matches
         where round = 'F'
         group by winner_name
         order by tournament_wins desc
     ) tournaments
```
  
  </p>
</details>

## 3. Find the top 3 players for each year

top 3 - players that won the most matches (disregarding the level)

`extract(year from date|timestamp)` will return year from date or timestamp

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select *
from (
         select *,
                rank() over (partition by year order by wins desc) as player_rank
         from (
                  select winner_name,
                         extract(year from tourney_date) as year,
                         count(*)                        as wins
                  from atp_matches
                  group by winner_name, extract(year from tourney_date)
              ) player_results_per_year
     ) ranked_results
where player_rank <= 3
```
  
  </p>
</details>

## 4. Find the top 3 players for each year (2)

Display each year as a single row enlisting all top 3 players with their rank and number of wins ordered by rank.

Example:

year | top3
--- | ---
1968 | 1. Arthur Ashe (34), 1. Tom Okker (34), 3. Rod Laver (33)
1969 | 1. Tom Okker (63), 2. Rod Laver (62), 2. Tony Roche (62)
1970 | 1. Rod Laver (85), 2. Cliff Richey (82), 3. Ken Rosewall (68), 3. Arthur Ashe (68)


top 3 - players that won the most matches (disregarding the level)

`extract(year from date|timestamp)` will return year from date or timestamp

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select year, string_agg(player_rank || '. ' || winner_name || ' (' || wins || ')', ', ') as top3
from (
         select *
         from (
                  select *,
                         rank() over (partition by year order by wins desc) as player_rank
                  from (
                           select winner_name,
                                  extract(year from tourney_date) as year,
                                  count(*)                        as wins
                           from atp_matches
                           group by winner_name, extract(year from tourney_date)
                       ) player_results_per_year
              ) ranked_results
         where player_rank <= 3
     ) ranked
group by year
```

or 

```sql
with player_results_per_year as (
    select winner_name,
           extract(year from tourney_date) as year,
           count(*)                        as wins
    from atp_matches
    group by winner_name, extract(year from tourney_date)
),
     ranked_players as (
         select *, rank() over (partition by year order by wins desc) as player_rank
         from player_results_per_year
     ),
     top3_players as (
         select *
         from ranked_players
         where player_rank <= 3
     )
select year, string_agg(player_rank || '. ' || winner_name || ' (' || wins || ')', ', ') as top3
from top3_players
group by year
```
  
  </p>
</details>

## 5. Take all players from 2018 and split them into 16 groups 

top 3 - players that won the most matches (disregarding the level)

`extract(year from date|timestamp)` will return year from date or timestamp

`ntile(num integer)` will split your results to `num` buckets/shards

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select player,
       ntile(16) over () as shard_number
from (
         select winner_name as player
         from atp_matches
         where extract(year from tourney_date) = 2018
         union
         distinct
         select loser_name as player
         from atp_matches
         where extract(year from tourney_date) = 2018
     ) all_players
```
  
  </p>
</details>

## 6. Find the top 3 players for each year and display how many matches they are behind the best player and previous player

top 3 - players that won the most matches (disregarding the level)

`extract(year from date|timestamp)` will return year from date or timestamp

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select *
from (
         select *,
                rank() over wins_per_year as player_rank,
                (first_value(wins) over wins_per_year - wins) to_winner,
                (coalesce(lag(wins) over wins_per_year, wins) - wins) to_previous
         from (
                  select winner_name,
                         extract(year from tourney_date) as year,
                         count(*)                        as wins
                  from atp_matches
                  group by winner_name, extract(year from tourney_date)
              ) player_results_per_year
         window wins_per_year as (partition by year order by wins desc)
     ) ranked_results
where player_rank <= 3
```
  
  </p>
</details>

## 7. Find top 1 players for each year and sort them by the percentage advantage they had on the second best player

assuming best = won the most matches

advantage = how many more matches did he/she won

`extract(year from date|timestamp)` will return year from date or timestamp

<details>
  <summary>Answer</summary>
  <p>
  
```sql
select *,
       (1.0 * above_next / wins) as percentage_diff
from (
         select *
         from (
                  select *,
                         rank() over wins_per_year               as player_rank,
                         lead(wins, 1) as second_best_score,
                         wins - lead(wins, 1) over wins_per_year as above_next
                  from (
                           select winner_name,
                                  extract(year from tourney_date) as year,
                                  count(*)                        as wins
                           from atp_matches
                           group by winner_name, extract(year from tourney_date)
                       ) player_results_per_year
                      window wins_per_year as (partition by year order by wins desc)
              ) ranked_results
         where player_rank <= 1
     ) top_1
order by percentage_diff desc
```
  
  </p>
</details>
