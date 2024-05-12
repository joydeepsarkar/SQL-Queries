use painting;

-- 1) Fetch all the paintings which are not displayed on any museums?
select * from work where museum_id is null;

-- 2) Are there museuems without any paintings?
select m.museum_id, m.name from museum m
left join work w on m.museum_id = w.museum_id
where w.museum_id is null; -- No.

-- 3) How many paintings have an asking price of more than their regular price?
select count(*) as Total_count from product_size
where sale_price>regular_price; -- 0

-- 4) Identify the paintings whose asking price is less than 50% of its regular price
select w.work_id,w.name from product_size ps, work w 
where ps.work_id = w.work_id and ps.sale_price < (0.5 * ps.regular_price); -- 58 records

-- 5) Which canva size costs the most?
select cs.label, ps.sale_price from product_size ps, canvas_size cs
where ps.size_id = cs.size_id 
order by ps.sale_price desc
limit 1; -- '48" x 96"(122 cm x 244 cm)', '1115'

-- 6) Delete duplicate records from work
delete from painting.work
where work_id not in (select * from (select max(work_id) from work group by work_id) AS temp);

-- 7) Identify the museums with invalid city information in the given dataset
select * from museum where city REGEXP '[0-9]'; -- 6 records 

-- 8) Museum_Hours table has 1 invalid entry. Identify it and remove it.
delete from museum_hours 
where museum_id not in (select * from (select min(museum_id) from museum_hours group by museum_id, day ) AS temp);

-- 9) Fetch the top 10 most famous painting subject

select subject,count(subject) as Count_Subject from subject join work on 
subject.work_id = work.work_id 
group by subject
order by count(subject) desc
limit 10;

-- 10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select name,city from museum_hours join 
museum on museum.museum_id = museum_hours.museum_id 
where day ='Sunday' and
exists (select * from museum_hours mh2 where mh2.museum_id = museum_hours.museum_id 
and day = 'Monday');

-- 11) How many museums are open every single day?
SELECT distinct name, city 
FROM museum_hours mh1
JOIN museum ON museum.museum_id = mh1.museum_id 
WHERE
  EXISTS (
    SELECT * 
    FROM museum_hours mh2 
    WHERE mh2.museum_id = mh1.museum_id 
    AND day = 'Monday'
  )
  AND EXISTS (
    SELECT * 
    FROM museum_hours mh3 
    WHERE mh3.museum_id = mh1.museum_id 
    AND day = 'Tuesday'
  )
  AND EXISTS (
    SELECT * 
    FROM museum_hours mh4 
    WHERE mh4.museum_id = mh1.museum_id 
    AND day = 'Wednesday'
  )
  AND EXISTS (
    SELECT * 
    FROM museum_hours mh5 
    WHERE mh5.museum_id = mh1.museum_id 
    AND day = 'Thursday'
  )
  AND EXISTS (
    SELECT * 
    FROM museum_hours mh6 
    WHERE mh6.museum_id = mh1.museum_id 
    AND day = 'Friday'
  )
  AND EXISTS (
    SELECT * 
    FROM museum_hours mh7 
    WHERE mh7.museum_id = mh1.museum_id 
    AND day = 'Saturday'
  )
  AND EXISTS (
    SELECT * 
    FROM museum_hours mh7 
    WHERE mh7.museum_id = mh1.museum_id 
    AND day = 'Sunday');

-- 12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)

SELECT museum.name AS museum_name, work.museum_id, COUNT(work.museum_id) AS Total_painting 
FROM work 
JOIN museum ON work.museum_id = museum.museum_id 
GROUP BY museum_name, work.museum_id, museum.museum_id
ORDER BY Total_painting DESC 
LIMIT 5;

-- 13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
SELECT artist.artist_id, artist.full_name AS Name, COUNT(work.work_id) AS total_art_works 
FROM artist 
JOIN work ON artist.artist_id = work.artist_id
GROUP BY artist.artist_id, artist.full_name
ORDER BY total_art_works DESC
LIMIT 5;

-- 14) Display the 3 least popular canva sizes
SELECT cs.label, COUNT(ps.work_id) AS total_works
FROM canvas_size cs
JOIN product_size ps ON cs.size_id = ps.size_id
GROUP BY cs.label
order by total_works asc
limit 3;

-- 15) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
select mh.museum_id,m.name,mh.day,mh.open,mh.close,
timestampdiff(second,str_to_date(open,'%h:%i:%p'),str_to_date(mh.close,'%h:%i:%p'))/ 3600.0 as total_hours,
timestampdiff(second,str_to_date(open,'%h:%i:%p'),str_to_date('12:00:PM','%h:%i:%p'))/ 3600.0 as total_daytime_hours
from painting.museum_hours mh
join painting.museum m on 
mh.museum_id = m.museum_id
order by total_hours desc;

-- 16) Which museum has the most no of most popular painting style?

with pop_style as
		(select style,rank() over (order by count(work.style) desc) as rnk from work 
		group by style
		),
mus as
		(select w.style, m.name,count(w.style) as Total_Count ,
        rank() over (order by count(1) desc) as count_paintings from work w
        join museum m on 
        w.museum_id = m.museum_id
        join pop_style ps on
        ps.style = w.style where w.museum_id is not null
        and ps.rnk<2
        group by w.museum_id, m.name,ps.style
        )
select name,style,Total_Count
	from mus; 

-- 17) Identify the artists whose paintings are displayed in multiple countries

select full_name,count(m.country) as total_countries from artist a 
join work w on
a.artist_id = w.artist_id
join museum m on w.museum_id = m.museum_id
group by full_name
order by total_countries desc;

-- 18) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
-- Display the artist name, sale_price, painting name, museum name, museum city and canvas label
   
with cte as 
		(select *
		, rank() over(order by sale_price desc) as rnk
		, rank() over(order by sale_price ) as rnk_asc
		from product_size )
	select w.name as painting
	, cte.sale_price
	, a.full_name as artist
	, m.name as museum, m.city
	, cz.label as canvas
	from cte
	join work w on w.work_id=cte.work_id
	join museum m on m.museum_id=w.museum_id
	join artist a on a.artist_id=w.artist_id
	join canvas_size cz on cz.size_id = cte.size_id
	where rnk=1 or rnk_asc=1;

-- 19) Which country has the 5th highest no of paintings?

with cte as 
(select m.country,count(m.country) as total_paintings,
rank() over (order by count(m.country) desc)as CountryRank from work w join museum m on
w.museum_id = m.museum_id
group by country
)
select * from cte where CountryRank=5;

-- 20) Which are the 3 most popular and 3 least popular painting styles?
with cte as
(select style,count(style) as TotalStyle, 
rank() over (order by count(style) desc) as MostPop,
rank() over (order by count(style)) as LeastPop 
from work
group by style
order by TotalStyle desc)
select * from cte where MostPop<4
or LeastPop <=3;

-- 21) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	