exec sp_help goalscorers

select * from goalscorers
where Date is null or
HomeTeam is null or
AwayTeam is null or
Team is null or Scorer is null or Minute is null


alter table goalscorers 
add constraint defaultminute default 'unknown' for Minute

update goalscorers
set Minute = case
when cast(Minute as int)%2=0 then 24
else 76
end
where Minute is null



exec sp_help results

select * from results 
where Date is null or
HomeTeam is null or AwayTeam is null or
Tournament is null or City is null or Country is null



select count(*) as totalmatches from results 
where HomeScore>AwayScore
union all
select count(*) as totalmatches from results 
where HomeScore<AwayScore 
union all
select count(*) as totalmatches from results 
where HomeScore=AwayScore



select HomeTeam,totalscore from (
select HomeTeam,sum(HomeScore)+sum(AwayScore) as totalscore,
Rank()over(order by sum(HomeScore)+sum(AwayScore) desc) as rn
from results
group by HomeTeam
) info
where rn=1


select AwayTeam,totalscore from(
select AwayTeam,sum(HomeScore)+sum(AwayScore) as totalscore,
Row_number()over(order by sum(HomeScore)+sum(AwayScore) desc) as rn
from results
group by AwayTeam
)info
where rn=1

select round(cast(sum(case when Neutral=1 then 1 else 0 end) as float)/count(*)*100,1) as NeutalmathcesPercentage
from results



alter table results
add  HomeWin bit

update results
set HomeWin = case when HomeScore>AwayScore then 1 else 0 end

alter table results
add AwayWin bit

update results
set AwayWin=case when AwayScore>HomeScore then 1 else 0 end

select round(cast(sum(case when Neutral=1 then 1 else 0 end) as float)/count(*)*100,1) as NeutalmathcesPercentage
from results


alter table results
add NoWinner bit

update results 
set NoWinner=case when HomeScore=AwayScore then 1 else 0 end
select round(cast(sum(case when NoWinner=1 then 1 else 0 end) as float)/count(*)*100,1) as NeutralPercentage from results




select * from results
where city='Coffs Harbour'

select Date,City,HomeTeam,AwayTeam,totalgoals from(
select Date,City,HomeTeam,AwayTeam,sum(AwayScore)+sum(HomeScore) as totalgoals,
DENSE_RANK() over(order by sum(AwayScore)+sum(HomeScore) desc) as rn
from results
group by Date,City,HomeTeam,AwayTeam
)info
where rn=1





select HomeTeam,avg(HomeScore) as avgHomeGoals from results
group by HomeTeam
order by HomeTeam asc

select AwayTeam,avg(AwayScore) as avgAwayGoals from results
group by AwayTeam
order by AwayTeam asc



Rank teams based on their goal differences in tournaments (HomeScore - AwayScore).
select HomeTeam,AwayTeam,
cast(abs(cast(HomeScore as int)-cast(AwayScore as int))as int) as differenceInGoals,
DENSE_RANK()over(order by cast(abs(cast(HomeScore as int)-cast(AwayScore as int)) as int) desc) as rank
from results
group by HomeTeam,AwayTeam,HomeScore,AwayScore




alter table goalscorers
add Goal bit
update goalscorers
set Goal=case 
when  OwnGoal=0 and Penalty=0 then 1
else 0 end





Identify the players with the most goals (Scorer), considering penalties and own goals (Penalty, OwnGoal).

select Scorer,totalGoals,rn from (
select Scorer,
sum(cast(Goal as int))+sum(cast(OwnGoal as int))+sum(cast(Penalty as int)) as totalGoals,
DENSE_RANK() over (order by sum(cast(Goal as int))+sum(cast(OwnGoal as int))+sum(cast(Penalty as int)) desc) as rn
from goalscorers
group by Scorer
)info
where rn<=10








alter table goalscorers
add TotalGoals int

update goalscorers
set TotalGoals=cast(OwnGoal as int)+cast(Penalty as int)+cast(Goal as int)


Analyze the average scoring minute for all goals scored.

select Minute,avg(TotalGoals) as AvgGoals from goalscorers
group by Minute






Determine the players with the highest number of penalty goals.

select Scorer,PenaltyGoals from(select
Scorer,sum(cast(Penalty as int)) as PenaltyGoals,
DENSE_RANK() over(order by sum(cast(Penalty as int)) desc) as rn 
from goalscorers
group by Scorer
)info
where rn<=5






Find the number of own goals scored by each team.

select HomeTeam, sum(cast(OwnGoal as int)) as OwnGoals from goalscorers
group by HomeTeam
order by sum(cast(OwnGoal as int)) desc

select AwayTeam, sum(cast(OwnGoal as int)) as OwnGoals from goalscorers
group by AwayTeam
order by sum(cast(OwnGoal as int)) desc




Compare the number of goals scored in the first half (minute ≤ 45) versus the second half (minute > 45).

select
case 
when Minute<45 then 'FirstHalf' else 'SecondHalf' end
as Halves,
sum(TotalGoals) as TotalGoals
from goalscorers
group by 
case 
when Minute<45 then 'FirstHalf' else 'SecondHalf' end
order by sum(TotalGoals) desc