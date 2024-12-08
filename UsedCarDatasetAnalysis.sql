use usedCars
exec sp_help used_car_dataset

select Brand,Model,count(*) as numberOfCars from used_car_dataset
group by Brand,Model

select Brand, avg(Age) as AVGAge from used_car_dataset
group by Brand


alter table used_car_dataset
alter column FuelType varchar(45)

alter table used_car_dataset
add constraint defaultname default 'unknown' for FuelType

select FuelType,numberOfCars from(
select FuelType,count(*) as numberOfCars,
DENSE_RANK() over(order by count(*) desc) as rn
from used_car_dataset
group by FuelType
)as info1
where rn=1


select FuelType,Transmission,avg(kmDriven) as AVGKm from used_car_dataset
group by FuelType,Transmission

select YEAR(PostedDate) as PostedYear, count(*) as TotalPosts from used_car_dataset
group by Year(PostedDate)
order by PostedYear asc

select Transmission,count(*) as TotalCars from used_car_dataset
group by Transmission


select Year,Age,year(getdate())-Year as differenceInYears,
case
when year(getdate())-Year = Age then 'Valid'
else 'Not-Valid'
end as validation
from used_car_dataset


select Brand,Model,Year,count(*) as numberOfDuplicates
from used_car_dataset
group by Brand,Model,Year
having Count(*)>1


update used_car_dataset
set FuelType = UPPER(FuelType)


update used_car_dataset
set Transmission = UPPER(Transmission)


select FuelType,Transmission from used_car_dataset



select year(PostedDate) as year ,month(PostedDate) as month,count(*) as cars from used_car_dataset
group by YEAR(PostedDate),MONTH(PostedDate)
order by YEAR(PostedDate),MONTH(PostedDate)



SELECT 
    DATEADD(MONTH, 1, CAST(CONCAT(PostedYear, '-', PostedMonth,'-01') AS DATE)) AS PredictedMonth,
    AVG(TotalPosts) AS AvgTotalPosts
FROM (
    SELECT 
        YEAR(PostedDate) AS PostedYear, 
        MONTH(PostedDate) AS PostedMonth, 
        COUNT(*) AS TotalPosts
    FROM used_car_dataset
    GROUP BY YEAR(PostedDate), MONTH(PostedDate)
) AS MonthlyData
group by PostedMonth,PostedYear
order by PostedMonth,PostedYear asc
