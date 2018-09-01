
--1. List all the company names (and countries) 
--   that are incorporated outside Australia.
-- 10 row
create or replace view Q1(Name, Country) as 
  select Name, Country 
  from Company 
  where Country <>'Australia'
  ;

--2. List all the company codes that have more than
--   five executive members on record (i.e., at least six).
--  0 row 
create or replace view Q2(Code) as
  select  c.code
  from (
      select Company.code, count(Executive.person) as num
      from Company, Executive
      where Company.Code=Executive.Code
      group by Company.code
    )  as c
  where num>5
  ;
------mohan-------
---复习having-----
select code
FROM executive
GROUP by Code
HAVING count(person) > 5;




--3. List all the company names that are in the sector of "Technology"
-- 10 row
create or replace view Q3(Name) as
  select Company.Name 
  from Company, Category
  where Company.Code = Category.Code and Sector='Technology'
  ;

-----
SELECT co.name
FROM company AS co
INNER JOIN category ca ON co.code = ca.code AND ca.sector = 'Technology';


--4. Find the number of Industries in each Sector
--   8 rows
create or replace view Q4(Sector, Number) as
  select Sector, count(Industry) 
  from Category
  group by Sector
  ; 
-------------------distinct--------
SELECT c.sector,
    count(DISTINCT c.industry)  -- eliminate the duplicated records since an industry can consist of multiple companies
FROM category AS c
GROUP BY c.sector;



--5. Find all the executives (i.e., their names) that are 
--   affiliated with companies in the sector of "Technology". 
--   If an executive is affiliated with more than one company,
--   he/she is counted if one of these companies is in the sector of "Technology".
--   (50 rows)
create or replace view Q5(Name) as
  select distinct Person 
  from Executive, Category
  where Executive.Code=Category.Code and Sector='Technology'
  ; 

---------------
SELECT DISTINCT e.person 
FROM executive AS e 
INNER JOIN category AS c ON e.code = c.code 
AND c.sector = 'Technology';



--6. List all the company names in the sector of "Services" 
--   that are located in Australia with the first digit of their zip code being 2.
--   (14 rows)
create or replace view Q6(Name) as
  select Name
  from Company, Category
  where Company.Code=Category.Code 
         and Sector='Services' 
         and Country='Australia'
         and zip like '2%'   ----here
         ;
----------------------------         
 SELECT co.name
FROM category AS ca
INNER JOIN company AS co ON co.code = ca.code AND co.country = 'Australia'
AND co.zip like '2%'
WHERE ca.sector = 'Services';

--7. Create a database view of the ASX table that contains previous Price, 
--   Price change (in amount, can be negative) and Price gain (in percentage, 
--   can be negative). (Note that the first trading day should be excluded 
--   in your result.) For example, if the PrevPrice is 1.00, Price is 0.85;
--   then Change is 0.15 and Gain is 15.00 (in percentage but you do not need
--   to print out the percentage sign).
--   10452 row

create or replace view Q7("Date", Code, Volume, PrevPrice, Price, Change, Gain) as
  with B as (select *, row_number() over (order by Code,"Date") as index  
             from  ASX
             ),
       C as (select *, row_number() over (order by Code,"Date") as index  
             from  ASX
             )  
  select C."Date",C.Code,C.Volume,B.Price as PrevPrice ,C.Price,C.Price-B.Price as Change,(C.Price-B.Price)/B.Price*100 as Gain
  from B,C
  where C.index=B.index+1 and C.Code=B.Code
  order by C."Date",C.Code
  ;           
    -- numbering the records for each code for later use
    -- link the previous date by this num
    Row_number() over(PARTITION BY a.code ORDER BY a.code, a."Date") AS num, 
    a.* 
FROM asx AS a;

CREATE OR REPLACE VIEW Q7("Date", Code, Volume, PrevPrice, Price, Change, Gain) AS 
SELECT 
    a.dt, 
    a.code, 
    a.volume, 
    aPre.price                                   AS PrevPrice, 
    a.price                                      AS CurrPrice, 
    a.price - aPre.price                         AS PriceChange, 
    (a.price - aPre.price) * 100.00 / aPre.price AS Gain 
FROM ASXNum AS a 
     left JOIN ASXNum AS aPre 
            ON a.code = aPre.code 
           AND a.num  = aPre.num + 1 
WHERE  a.num > 1;

  
--8. Find the most active trading stock (the one with the maximum trading volume;
--   if more than one, output all of them) on every trading day.
--   Order your output by "Date" and then by Code.  
--  (63 rows)
create or replace view Q8("Date", Code, Volume) as
  select ASX."Date",ASX.Code, A.maxx as Volume
  from ASX,
    (select A1."Date", max(A1.Volume) as maxx
    from ASX as A1, ASX as A2
    where  A1."Date"=A2."Date"
    group by A1."Date") as A 
  where ASX."Date"=A."Date" and ASX.Volume>=A.maxx
  order by A."Date",ASX.Code
  ;


--9. Find the number of companies per Industry.
--   Order your result by Sector and then by Industry.
--   (62 rows) 
create or replace view Q9(Sector, Industry, Number) as
  select Sector, Industry, count(Category.Code)
  from Company, Category
  where Company.Code=Category.Code
  group by Sector, Industry
  order by Sector, Industry
  ;

SELECT
    c.sector,
    c.industry,
    count(DISTINCT c.code) AS cnt
FROM category AS c
GROUP BY c.sector, c.industry
ORDER BY c.sector, c.industry;

--10. List all the companies (by their Code) that are the 
--    only one in their Industry (i.e., no competitors).
--  (25 rows) 
create or replace view Q10(Code, Industry) as
  select Company.Code, m.Industry
  from Company, Category,(
      select Sector, Industry, count(Category.Code) as c
      from Company, Category
      where Company.Code=Category.Code
      group by Sector, Industry) as m
  where Company.Code=Category.Code and Category.Industry=m.Industry and m.c=1
  ;
-------------------------
  SELECT
    c.code,
    c.industry
FROM category AS c
WHERE not EXISTS
(
    SELECT
        tmp.code
    FROM category AS tmp
    WHERE tmp.industry = c.industry
          AND tmp.code <> c.code
);

--11. List all sectors ranked by their average ratings in 
--    descending order. AvgRating is calculated by finding 
--    the average AvgCompanyRating for each sector
--    (where AvgCompanyRating is the average rating of a company).
--    (8 rows)

create or replace view Q11(Sector, AvgRating) as
  select C1.Sector, (sum(A.AvgCompanyRating)/count(A.Code)) as AvgRating
  from Category as C1, Category as C2,
       ( select Code,avg(star) AS AvgCompanyRating
         from Rating
         group by Code
        ) as A  -- each Code's avg star
  where C1.Sector=C2.Sector and C1.Code=A.Code and C2.Code=A.Code
  group by C1.Sector
  order by AvgRating desc
  ; 
-------------------
SELECT
    cmpy.sector,
    AVG(cmpy.AvgConpanyStar)
FROM
(
    -- calculate the average star for each company first
    SELECT
        c.sector,
        c.code,
        AVG(r.star) AS AvgConpanyStar
    FROM category AS c
    INNER JOIN rating AS r 
            ON c.code = r.code
    GROUP BY c.sector, c.code
) AS cmpy
GROUP BY cmpy.sector
ORDER BY AVG(cmpy.AvgConpanyStar) DESC;

--12. Output the person names of the executives that are 
--    affiliated with more than one company.  
--    (2 rows) 
create or replace view Q12(Name) as
  select Person
  from Executive
  group by Person
  having count(Code)>1
  ;
------------------------------------
SELECT
    tmp.person
FROM
(
    SELECT
        e.person,
        COUNT(DISTINCT e.code)
    FROM executive AS e
    GROUP BY e.person
    HAVING COUNT(DISTINCT e.code) > 1 -- more than one company
) AS tmp;

--13. Find all the companies with a registered address in Australia, 
--    in a Sector where there are no overseas companies in the same Sector.
--    i.e., they are in a Sector that all companies there have 
--    local Australia address.   
--    (44 rows)
create or replace view Q13(Code, Name, Address, Zip, Sector) as

select Company.Code, Name, Address, Zip, Category.Sector
from Category, Company,
  (
  select A.Sector
  from ((select Sector
        from Category
        group by Sector
       ) 
      except
      ( select Sector
        from Company, Category
        where Company.Code=Category.Code and Country<>'Australia'
        group by Sector
      )) as A  ) as B --- except 3 sectors
  where B.Sector=Category.Sector and Category.Code=Company.Code
  ;

--------------------------
SELECT
    co.code,
    co.name,
    co.address,
    co.zip,
    ca.sector
FROM company AS co
INNER JOIN category AS ca 
        ON co.code = ca.code
-- list the companies that do not in those sectors
WHERE ca.sector NOT IN
(
    -- retrieve the sectors which have oversea companies
    SELECT
        ca.sector
    FROM company AS co
    INNER JOIN category AS ca 
       ON co.code = ca.code
    WHERE co.country <> 'Australia'
);


--14. Calculate stock gains based on their prices of the first trading day
--    and last trading day (i.e., the oldest "Date" and the most recent "Date" 
--    of the records stored in the ASX table). Order your result by Gain in 
--    descending order and then by Code in ascending order.
-- (169 rows)

create or replace view Q14(Code, BeginPrice, EndPrice, Change, Gain) as
    
  select E.Code, B.Price as BeginPrice, E.Price as EndPrice, E.Price-B.Price as Change,(E.Price-B.Price)/B.Price*100  as Gain
  from (select * 
       from (select min("Date") as mindate from ASX) as a, ASX
       where  a.mindate=ASX."Date") as B,

       (select * 
       	from (select max("Date") as maxdate from ASX) as d, ASX
       	where d.maxdate=ASX."Date") as E
  where E.Code=B.Code

  order by Gain desc, E.Code
  ;
---------------------
SELECT
    asxn.code,
    old.price,
    new.price,
    new.price - old.price                        AS change,
    (new.price - old.price) * 100.00 / old.price AS Gain
FROM 
(
    -- retrieve the oldest and latest trading date for each company
    SELECT
        a.code,
        MIN(a."Date") AS mi,
        MAX(a."Date") AS mx
    FROM ASX AS a
    GROUP BY a.code
) AS asxn
-- retrieve the prices for both the oldest and latest date for each company
INNER JOIN ASX old 
        ON old.code    = asxn.code
       AND old."Date"  = asxn.mi
INNER JOIN ASX new
        ON new.code    = asxn.code
       AND new."Date"  = asxn.mx
ORDER BY Gain DESC, asxn.code ASC;


--15. For all the trading records in the ASX table, produce the following 
--    statistics as a database view (where Gain is measured in percentage). 
--    AvgDayGain is defined as the summation of all the daily gains 
--    (in percentage) then divided by the number of trading days (as noted above, 
--    the total number of days here should exclude the first trading day).
--    (169 rows)
create or replace view Q15(Code, MinPrice, AvgPrice, MaxPrice,
                           MinDayGain, AvgDayGain, MaxDayGain) as
    select ASX.Code, 
           min(ASX.price)as MinPrice, 
           (sum(ASX.Price)/count(ASX.Code)) as AvgPrice, 
           max(ASX.Price) as MaxPrice,
                           D.MinDayGain, D.AvgDayGain, D.MaxDayGain
    from ASX,
        (with B as (select *, row_number() over (order by Code,"Date") as index from  ASX),
              C as (select *, row_number() over (order by Code,"Date") as index from  ASX)
         select C.Code,
                min((C.Price-B.Price)/B.Price*100) as MinDayGain,
                avg((C.Price-B.Price)/B.Price*100) as AvgDayGain,
                max((C.Price-B.Price)/B.Price*100) as MaxDayGain
         from B,C
         where C.index=B.index+1 and C.Code=B.Code
         group by C.Code         
        ) as D
     where ASX.Code=D.Code
     group by ASX.Code,D.MinDayGain, D.AvgDayGain, D.MaxDayGain 
     order by ASX.Code
     ;    

--16. Create a trigger on the Executive table, to check and disallow any insert 
--    or update of a Person in the Executive table to be an executive of 
--    more than one company.

--function for update
create or replace function executive_check_update() returns trigger
as $$
begin 
    if (new.Code!=old.Code and new.Person=old.Person) then --different Code,same person  
        if (select count(Code) from Executive where Person=new.Person)>1 then 
        raise exception '% is an executive of more than one company.',new.Person;
        end if; -- update Code
    end if;    

    if (new.Code=old.Code and new.Person!=old.Person) then --same code,different person 
        if (select count(Code) from Executive where Person=new.Person)>0 then  
        raise exception '% is an executive of more than one company.',new.Person;
        end if; -- update Person     
    end if;  
    return new;
end;
$$ language plpgsql;
--function for insert
create or replace function executive_check_insert() returns trigger
as $$ 
begin 

     if (select count(Code) as C from Executive where Person=new.Person)>0 then  
     raise exception '% is an executive of more than one company.',new.Person;
     end if;
     return new;
end;
$$ language plpgsql;
--trigger for update
create trigger executive_check_update
before update on Executive
for each row execute procedure executive_check_update()
;
--trigger for insert
create trigger executive_check_insert
before insert on Executive
for each row execute procedure executive_check_insert()
;     
--drop trigger executive_check on executive;
--INSERT INTO Executive VALUES('DUE', 'Mr. Alain Ludwig Schibl');
--INSERT INTO Executive VALUES('AAD', 'Mr. Alain Ludwig Schibl');
--success--update Executive set Code='DUE' where Person='Mr. Alain Ludwig Schibl';
--success--update Executive set Code='ABC' where Person='Mr. Alain Ludwig Schibl';
--error----update Executive set Code='ABC' where Person='Mr. David John Southon';
--INSERT INTO Executive VALUES('FWD', 'Mr. Bradley Denison');
--INSERT INTO Executive VALUES('FWD', 'Mr. Bradley Denison');
--INSERT INTO Executive VALUES('SUL', 'Mr. David Burns'); 
--select * from Executive where code='SUL' and Person= 'Mr. David Burns';

--17. Suppose more stock trading data are incoming into the ASX table. 
--    Create a trigger to increase the stock's rating (as Star's) to 5 when the 
--    stock has made a maximum daily price gain (when compared with the price on
--    the previous trading day) in percentage within its sector. 
--    For example, for a given day and a given sector, if Stock A has the maximum
--    price gain in the sector, its rating should then be updated to 5.
--    If it happens to have more than one stock with the same maximum price gain,
--    update all these stocks' ratings to 5. 
--    Otherwise, decrease the stock's rating to 1 when the stock has performed 
--    the worst in the sector in terms of daily percentage price gain. 
--    If there are more than one record of rating for a given stock that need to 
--    be updated, update (not insert) all these records.

create or replace view Q174("Date",Code,Sector,Gain) as  
with A as (
  with B as (select *, row_number() over (order by Code,"Date") as index  from  ASX),
       C as (select *, row_number() over (order by Code,"Date") as index  from  ASX)  
  select C."Date",C.Code,Category.Sector,(C.Price-B.Price)/B.Price*100 as Gain
  from B,C,Category
  where C.index=B.index+1 and C.Code=B.Code and Category.Code=C.Code
  order by C."Date",C.Code
  )
 select A."Date",A.Code,A.Sector,A.Gain
 from A
 group by A."Date",A.Sector,A.Code,A.Gain
 order by A."Date",A.Code,A.Sector
 ; ---select data for function

 create or replace function Rating_update() returns trigger
 as $$ declare newGain numeric;
       declare newSector varchar;  
 begin    
       
       newGain=(select Gain from Q174 where new.Code= Q174.Code and new."Date"=Q174."Date");
       newSector=(select Sector from Q174 where new.Code= Q174.Code and new."Date"=Q174."Date");
       if (newGain>=
          (select max(Gain) from Q174  where Sector=newSector and "Date"=new."Date" group by Sector))  then 
       update Rating set  Star=5 where Code=new.Code;
       end if; 

       if (newGain<=
          (select min(Gain) from Q174 where Sector=newSector and "Date"=new."Date" group by Sector))  then 
       update Rating set  Star=1 where Code=new.Code;
       end if;        
       
    return new;
 end;
 $$ language plpgsql;


 create trigger Rating_update 
 after insert on ASX
 for each row execute procedure Rating_update()
 ;  


--18. Stock price and trading volume data are usually incoming data and seldom 
--    involve updating existing data. However, updates are allowed in order to
--    correct data errors. All such updates (instead of data insertion) are logged
--    and stored in the ASXLog table. Create a trigger to log any updates on 
--    Price and/or Voume in the ASX table and log these updates (only for update,
--    not inserts) into the ASXLog table. Here we assume that Date and Code
--    cannot be corrected and will be the same as their original, old values. 
--    Timestamp is the date and time that the correction takes place.
--    Note that it is also possible that a record is corrected more than once,
--    i.e., same Date and Code but different Timestamp.


 create or replace function ASXlog_check() returns trigger
 as $$ declare 
        a ASXlog;
 begin

    insert into ASXlog("Timestamp","Date",Code,OldVolume, OldPrice) 
         values(current_timestamp, new."Date",new.Code,old.Volume,old.Price);    
    return new;
 end;
 $$ language plpgsql;

 create trigger ASXlog_check 
 after update on ASX
 for each row execute procedure ASXlog_check()
 ;   













