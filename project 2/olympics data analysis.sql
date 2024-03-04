use namastesql;

/*
There are 2 csv files present in this zip file. The data contains 120 years of olympics history. There are 2 daatsets 
1- athletes : it has information about all the players participated in olympics
2- athlete_events : it has information about all the events happened over the year.(athlete id refers to the id column in athlete table)

import these datasets in sql server and solve below problems:
*/

select * from athlete_events;
select * from athletes;

--1 which team has won the maximum gold medals over the years.
select top 1 team, count(distinct event) as total_golds 
from athlete_events ae
inner join athletes a
on ae.athlete_id = a.id
where ae.medal = 'Gold'
group by team
order by total_golds desc; 



--2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver
with cte as (
select a.team,ae.year , count(distinct event) as silver_medals
,rank() over(partition by team order by count(distinct event) desc) as rn
from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where medal='Silver'
group by a.team,ae.year)
select team,sum(silver_medals) as total_silver_medals, max(case when rn=1 then year end) as  year_of_max_silver
from cte
group by team;



--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years

with cte as (
select athlete_id, sum(case when medal = 'Gold' then 1 else 0 end) as total_gold,
sum(case when medal = 'Silver' then 1 else 0 end) as total_silver,
sum(case when medal = 'Bronze' then 1 else 0 end) as total_bronze
from athlete_events
group by athlete_id ),
cte2 as (
select top 1 athlete_id, total_gold
from cte
where total_silver = 0 and total_bronze = 0 and total_gold > 0
order by total_gold desc )
select *
from cte2 
inner join athletes a
on cte2.athlete_id = a.id;




--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names.
with cte as (
select year, athlete_id, count(1) as total_gold
from athlete_events
where medal = 'Gold'
group by year, athlete_id ),
cte2 as (
select *, rank() over(partition by year order by total_gold desc) as rn
from cte )
select year, max(total_gold) as max_gold_per_yr, STRING_AGG(name, ', ') within group(order by name) as player_names
from cte2
inner join 
athletes a 
on cte2.athlete_id = a.id
where rn = 1
group by year
order by year;


--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport
with cte as(
select *, rank() over(partition by medal order by year) as rn
from athlete_events ae
inner join 
athletes a 
on ae.athlete_id = a.id
where team = 'India' and medal is not null)
select medal, name, year, event
from cte 
where rn = 1;

--6 find players who won gold medal in summer and winter olympics both.
--substring(games, 5, len(games))

select name
from athlete_events ae
inner join athletes a
on ae.athlete_id = a.id
where medal = 'Gold'
group by name
having count(distinct season) = 2;


--7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.
with cte as (
select athlete_id, year
from athlete_events
where medal is not null
group by athlete_id, year
having count(distinct medal) = 3
)
select name, year--, gold_count, Silver_count, Bronze_count, team
from cte 
inner join athletes a
on cte.athlete_id = a.id

--8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.
with cte as (
select athlete_id, event, year as curr_year
from athlete_events
where medal = 'Gold' and year >= 2000 and season = 'Summer'
group by athlete_id, year, event),
cte2 as (
select *, lag(curr_year, 1, 0) over(partition by athlete_id, event order by curr_year) as last_year, lag(curr_year, 2, 0) over(partition by athlete_id, event order by curr_year) as second_last_year
from cte )
select name, event, curr_year, last_year, second_last_year
from cte2 
inner join athletes a
on cte2.athlete_id = a.id
where curr_year = last_year+ 4 and last_year = second_last_year + 4 
order by name;
