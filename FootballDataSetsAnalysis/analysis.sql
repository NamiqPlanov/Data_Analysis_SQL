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


Analyze the distribution of tournaments by country and city.

select Country,City,Tournament,count(*) as NumberOfGames from results
group by Country,City,Tournament



alter table results
add TotalGoals int

update results
set TotalGoals = HomeScore+AwayScore





Find the tournaments with the highest average goals scored per match.

select Tournament,AvgGoals from(
select Tournament,avg(TotalGoals) as AvgGoals,
rank()over(order by avg(TotalGoals) desc) as rn
from results
group by Tournament
)info
where rn<=3




Determine the most frequent neutral venue for tournaments.

select Tournament,NeutralVenues from (
select Tournament, sum(cast(Neutral as int)) as NeutralVenues,
DENSE_RANK() over(order by sum(cast(Neutral as int)) desc) as rn
from results
group by Tournament
) info
where rn=1



Rank countries by the number of matches hosted and goals scored.

select Country,sum(cast(HomeWin as int)+cast(AwayWin as int)+cast(NoWinner as int)) as NumberOfMatches,
sum(TotalGoals) as TotalGoals,DENSE_RANK() over(order by sum(cast(HomeWin as int)+cast(AwayWin as int)+cast(NoWinner as int)) desc) as rnForMatches,
RANK()over(order by sum(TotalGoals) desc) as rnForGoals
from results
group by Country



Find the number of matches played in each year or month.

select year(Date) as Year,Sum(cast(NoWinner as int)+cast(HomeWin as int)+cast(AwayWin as int)) as NumberOfMatches
from results
group by year(Date)
order by year(Date)


select case 
when Month(Date)=1 then 'January'
when month(Date)=2 then 'February'
when month(Date)=3 then 'March'
when month(Date)=4 then 'April'
when month(Date)=5 then 'May'
when month(Date)=6 then 'June'
when month(Date)=7 then 'July'
when month(Date)=8 then 'August'
when month(date)=9 then 'September'
when month(Date)=10 then 'October'
when month(Date)=11 then 'November'
else 'December'
end as Month,
Sum(cast(NoWinner as int)+cast(HomeWin as int)+cast(AwayWin as int)) as NumberOfMatches
from results
group by case 
when Month(Date)=1 then 'January'
when month(Date)=2 then 'February'
when month(Date)=3 then 'March'
when month(Date)=4 then 'April'
when month(Date)=5 then 'May'
when month(Date)=6 then 'June'
when month(Date)=7 then 'July'
when month(Date)=8 then 'August'
when month(date)=9 then 'September'
when month(Date)=10 then 'October'
when month(Date)=11 then 'November'
else 'December'
end
order by case 
when Month(Date)=1 then 'January'
when month(Date)=2 then 'February'
when month(Date)=3 then 'March'
when month(Date)=4 then 'April'
when month(Date)=5 then 'May'
when month(Date)=6 then 'June'
when month(Date)=7 then 'July'
when month(Date)=8 then 'August'
when month(date)=9 then 'September'
when month(Date)=10 then 'October'
when month(Date)=11 then 'November'
else 'December'
end asc






Analyze trends in scoring patterns over time (e.g., goals per match by year).
select Year(Date) as Year,Sum(TotalGoals) as TotalGoalsPerYear from results
group by Year(Date)
order by Year(Date) asc





Determine the busiest months for matches across all tournaments.

select Month,NumberOfMatches from(
select case 
when Month(Date)=1 then 'January'
when month(Date)=2 then 'February'
when month(Date)=3 then 'March'
when month(Date)=4 then 'April'
when month(Date)=5 then 'May'
when month(Date)=6 then 'June'
when month(Date)=7 then 'July'
when month(Date)=8 then 'August'
when month(date)=9 then 'September'
when month(Date)=10 then 'October'
when month(Date)=11 then 'November'
else 'December'
end as Month,
Sum(cast(NoWinner as int)+cast(HomeWin as int)+cast(AwayWin as int)) as NumberOfMatches,
DENSE_RANK() over(order by Sum(cast(NoWinner as int)+cast(HomeWin as int)+cast(AwayWin as int)) desc) as rank
from results
group by case 
when Month(Date)=1 then 'January'
when month(Date)=2 then 'February'
when month(Date)=3 then 'March'
when month(Date)=4 then 'April'
when month(Date)=5 then 'May'
when month(Date)=6 then 'June'
when month(Date)=7 then 'July'
when month(Date)=8 then 'August'
when month(date)=9 then 'September'
when month(Date)=10 then 'October'
when month(Date)=11 then 'November'
else 'December'
end)info
where rank<=3


