--1--
select p.playerID as playerid,p.nameFirst as firstname,p.nameLast as lastname, coalesce(sum(b.CS),0) as total_caught_stealing from People p, Batting b 
where(p.playerID=b.playerID)
group by p.playerID,p.nameFirst,p.nameLast
order by total_caught_stealing desc ,p.nameFirst asc , p.nameLast asc, p.playerID asc limit 10;

--2--
select p.playerID as playerid,p.nameFirst as firstname,(2*coalesce(sum(b.H2B),0)+3*coalesce(sum(b.H3B),0)+4*coalesce(sum(HR),0)) as runscore
from People p,Batting b
where p.playerID=b.playerID
group by p.playerID,p.nameFirst
order by runscore desc,p.nameFirst desc,p.playerID asc limit 10;

--3--
select p.playerID as playerid,coalesce(p.nameFirst,'')||' '||p.nameLast as playername ,(coalesce(sum(asp.pointsWon),0)) as total_points
from People p, AwardsSharePlayers asp
where (p.playerID=asp.playerID and asp.yearID>=2000) 
group by p.playerID,playername
order by total_points desc,p.playerID asc;

--4--
with bat(playerID,hits,ab) as
(
    select b.playerID,coalesce(sum(b.H),0),coalesce(sum(b.AB),0)
    from Batting b where b.H is not null and b.AB is not null and b.AB>0
    group by b.playerID
),
seasons(playerID,num_seasons) as
(
    select playerID,count(distinct yearID)
    from Batting where H is not null and AB is not null and AB>0 
    group by playerID
)
select b.playerID as playerid,p.nameFirst as firstname,p.nameLast as lastname,(b.hits)::float/(b.ab)::float as career_batting_average
from People p, bat b,seasons s
where (b.playerID=p.playerID and s.playerID=p.playerID and s.num_seasons>=10)
group by b.playerID,p.nameFirst,p.nameLast,b.hits,b.ab
order by career_batting_average desc,playerid asc,firstname asc, lastname asc limit 10;

--5--
with bp1f(playerID,yearID) as
(
    (
        select playerID,yearID 
        from Pitching
    )
    union
    (
        select playerID,yearID 
        from Batting 
    )
    union
    (
        select playerID,yearID 
        from Fielding 
    )
),
num(playerID,num_seasons) as
(
    select playerID,count(distinct yearID)
    from bp1f
    group by playerID
)
select distinct p.playerID,p.nameFirst as firstname,p.nameLast as lastname,to_char(p.birthYear,'FM0999')||'-'||to_char(p.birthMonth,'FM09')||'-'||to_char(p.birthDay,'FM09') as date_of_birth,num.num_seasons
from People p,num
where p.playerID=num.playerID
group by p.playerID,firstname,lastname,date_of_birth,num_seasons
order by num_seasons desc,p.playerID asc,firstname asc,lastname asc,date_of_birth asc;

--6--
with wins(teamID,num_wins) as
(
    select t.teamID,coalesce(max(W),0) 
    from Teams t
    where t.DivWin=True group by t.teamID
)
select t.teamID,t.name,f.franchName,w.num_wins as num_wins
from Teams t,TeamsFranchises f, wins w
where (t.teamID=w.teamID and t.franchID=f.franchID and t.yearID=(select max(t1.yearID) from Teams t1 where t1.teamID=t.teamID))
group by  t.teamID,t.name,f.franchName,num_wins
order by num_wins desc ,t.teamID asc ,t.name asc, f.franchName asc;

--7--
with winpercent(teamID,seasonID,wp)
as
(
    select t.teamID,t.yearID,(t.W*1.0)/t.G
    from Teams t
)
select t.teamID,t.name,t.yearID,coalesce(max(w.wp),0)*100 as winning_percentage
from Teams t,winpercent w
where t.teamID=w.teamID and (select coalesce(sum(t1.W),0) from Teams t1 where t1.teamID=t.teamID )>=20 
and((1.0*t.W)/t.G=(select coalesce(max(w1.wp),0) from Teams t1,winpercent w1
where t1.teamID=w1.teamID and t1.teamID=t.teamID))   
group by t.teamID,t.name,t.yearID
order by winning_percentage desc , t.teamID asc ,t.name asc,t.yearID asc limit 5;

--8--
with sal(yearId,teamID,playerID,salary) as
(
    select s.yearID,s.teamID,s.playerID,s.salary
    from Salaries s
    where s.salary=(select coalesce(max(s1.salary),0) from Salaries s1 where s1.teamID=s.teamID and s1.yearID=s.yearID)
),
latest(teamID,tname) as
(
    select distinct t.teamID,t.name from Teams t
    where t.yearID=(select max(t1.yearID) from Teams t1 where t1.teamID=t.teamID)
)
select t.teamID as teamid,l.tname as teamname,t.yearID as seasonid,p.playerID as playerid,p.nameFirst as player_firstname,p.nameLast as player_lastname,s.salary as salary
from Teams t,People p, sal s,latest l
where t.teamID=l.teamID and t.teamID=s.teamID and p.playerID=s.playerID and t.yearID=s.yearID
order by  t.teamID asc,t.name asc,t.yearID asc,p.playerID asc,p.nameFirst asc,p.nameLast asc ,s.salary desc;

--9--
with sal(player_category,avg_salary) as
(
    (
        select 'batting',avg(s.salary)
        from Batting b,Salaries s
        where b.playerID=s.playerID and b.yearID=s.yearID and b.teamID=s.teamID and b.lgID=s.lgID
    )
    union
    (
        select 'pitching',avg(s.salary)
        from Pitching p,Salaries s
        where p.playerID=s.playerID and p.yearID=s.yearID and b.teamID=s.teamID and b.lgID=s.lgID
    )
    union
    (
        select 'fielding',avg(s.salary)
        from Fielding f,Salaries s
        where f.playerID=s.playerID and f.yearID=s.yearID and b.teamID=s.teamID and b.lgID=s.lgID
    )
)
select * from sal order by avg_salary desc limit 1;

--10--
with batchmate(player1,player2) as
(
    select distinct p.playerID,p1.playerID
    from CollegePlaying p,CollegePlaying p1
    where p.schoolID=p1.schoolID and p.yearID=p1.yearID and p.playerID!=p1.playerID
)
select p.playerID as playerid,coalesce(p.nameFirst,'')||' '||p.nameLast as playername, count(*) as number_of_batchmates
from batchmate b,People p
where b.player1=p.playerID and b.player1!=b.player2
group by p.playerID,playername
order by number_of_batchmates desc,p.playerID asc;

--11--
with latest(teamID,tname) as
(
    select distinct t.teamID,t.name from Teams t
    where t.yearID=(select max(t1.yearID) from Teams t1 where t1.teamID=t.teamID)
),
total(teamid,teamname,WSWin,G) as
(
    select t.teamID,l.tname,t.WSWin,t.G
    from Teams t,latest l where l.teamID=t.teamID
)
select t.teamid,t.teamname,count(*) as total_WS_wins
from total t
where t.WSWin=True and t.G>=110
group by t.teamid,t.teamname
order by total_WS_wins desc ,t.teamid asc,t.teamname asc limit 5;

--12--
with pitch(playerID,seasons) as
(                                                              
    select p.playerID,count(distinct p.yearID)                   
    from Pitching p
    group by p.playerID                                                                                  )          
select p.playerID  as playerid,p1.nameFirst as firstname,p1.nameLast as lastname,coalesce(sum(p.SV),0) as career_saves,p2.seasons as num_seasons                                                             
from Pitching p,People p1,Pitch p2                                                                       
where p.playerID=p1.playerID and p.playerID=p2.playerID and p2.seasons>=15
group by p.playerID,p1.nameFirst,p1.nameLast,num_seasons
order by career_saves desc, num_seasons desc, p.playerID asc,p1.nameFirst asc,p1.nameLast asc limit 10;

--13--
with latest(teamID,tname) as
(
    select distinct t.teamID,t.name from Teams t
    where t.yearID=(select max(t1.yearID) from Teams t1 where t1.teamID=t.teamID)
),
temp1(playerID,num_teams) as
(
    select playerID,count(distinct teamID)
    from Pitching group by playerID
),
temp2(playerID) as
(
    select distinct playerID from temp1 t
    where t.num_teams>=5
),
playerteams(playerID,yearID,stint,teamID) as 
(
    select p.playerID,p.yearID,p.stint,p.teamID
    from Pitching p,temp2 t
    where t.playerID=p.playerID
),
fteam(playerID,teamname) as
(
    select  pt.playerID,l.tname 
    from playerteams pt,latest l
    where pt.teamID=l.teamID and pt.yearID=(select min(pt1.yearID) from playerteams pt1 where pt1.playerID=pt.playerID) and pt.stint=1
),
steam(playerID,teamname) as
(
    select  pt.playerID,l.tname 
    from playerteams pt,latest l
    where pt.teamID=l.teamID and ((pt.yearID=(select min(pt1.yearID) from playerteams pt1 where pt1.playerID=pt.playerID) and pt.stint=2) or (pt.stint=1 and pt.yearID=(select min(pt1.yearID) from playerteams pt1 where pt1.playerID=pt.playerID and pt1.yearID !=(select min(pt2.yearID) from playerteams pt2 where pt2.playerID=pt.playerID))))
)
select p.playerID as playerid,p.nameFirst as firstname,p.nameLast as lastname,lower(p.birthCity||' '||p.birthState||' '||p.birthCountry) as birth_address,ft.teamname as first_teamname,st.teamname as second_teamname
from fteam ft,steam st,People p
where p.playerID=ft.playerID and p.playerID=st.playerID
order by playerid asc,firstname asc,lastname asc,birth_address asc, first_teamname asc,second_teamname asc;

--14--
begin;

insert into People (playerID, nameFirst, nameLast)
select 'dunphil02', 'Phil', 'Dunphy'
where not exists (select 1 from People where playerID = 'dunphil02');

insert into People (playerID, nameFirst, nameLast)
select 'tuckcam01', 'Cameron', 'Tucker'
where not exists (select 1 from People where playerID = 'tuckcam01');

insert into People (playerID, nameFirst, nameLast)
select 'scottm02', 'Michael', 'Scott'
where not exists (select 1 from People where playerID = 'scottm02');

insert into People (playerID, nameFirst, nameLast)
select 'waltjoe', 'Joe', 'Walt'
where not exists (select 1 from People where playerID = 'waltjoe');

insert into People (playerID, nameFirst, nameLast)
select 'adamswi01', 'Willie', 'Adams'
where not exists (select 1 from People where playerID = 'adamswi01');

insert into People (playerID, nameFirst, nameLast)
select 'yostne01', 'Ned', 'Yost'
where not exists (select 1 from People where playerID = 'yostne01');

insert into awardsplayers (awardID, playerID, yearID, lgID, tie)
select 'Best Baseman', 'dunphil02', 2014, '', true
where not exists (select 1 from awardsplayers where awardID  = 'Best Baseman' AND playerID = 'dunphil02' AND yearID = 2014);

insert into awardsplayers (awardID , playerID, yearID, lgID, tie)
select 'Best Baseman', 'tuckcam01', 2014,'', true
where not exists (select 1 from awardsplayers where awardID  = 'Best Baseman' AND playerID = 'tuckcam01' AND yearID = 2014);

insert into awardsplayers (awardID , playerID, yearID, lgID, tie)
select 'ALCS MVP', 'scottm02', 2015, 'AA', false
where not exists (select 1 from awardsplayers where awardID  = 'ALCS MVP' AND playerID = 'scottm02' AND yearID = 2015);

insert into awardsplayers (awardID , playerID, yearID,lgID)
select 'Triple Crown', 'waltjoe', 2016, ''
where not exists (select 1 from awardsplayers where awardID  = 'Triple Crown' AND playerID = 'waltjoe' AND yearID = 2016);

insert into awardsplayers (awardID , playerID, yearID,lgID, tie)
select 'Gold Glove', 'adamswi01', 2017,'', false
where not exists (select 1 from awardsplayers where awardID  = 'Gold Glove' AND playerID = 'adamswi01' AND yearID = 2017);

insert into awardsplayers (awardID , playerID, yearID,lgID)
select 'ALCS MVP', 'yostne01', 2017,''
where not exists (select 1 from awardsplayers where awardID  = 'ALCS MVP' AND playerID = 'yostne01' AND yearID = 2017);

commit;
with awards(awardID,playerID,num_wins) 
as
(
    select ap1.awardID,ap1.playerID,count(distinct yearID) as num_wins
    from AwardsPlayers ap1
    group by ap1.awardID,ap1.playerID
),
max_awards(awardID,playerID,num_wins)
as
(
    select a.awardID,a.playerID,a.num_wins
    from awards a
    where a.num_wins=(select max(a1.num_wins) from awards a1 where a1.awardID=a.awardID)
)
select ap.awardID as awardid,p.playerID as playerid,p.nameFirst as firstname,p.nameLast as lastname,ap.num_wins as num_wins
from max_awards ap,People p
where p.playerID=ap.playerID and ap.playerID=(select min(ap1.playerID) from max_awards ap1 where ap1.awardID=ap.awardID)
order by awardid asc,num_wins desc;

--15--
with latest(teamID,tname) as
(
    select distinct t.teamID,t.name from Teams t
    where t.yearID=(select max(t1.yearID) from Teams t1 where t1.teamID=t.teamID)
)
select t.teamID,l.tname,t.yearID,m.playerID,p.nameFirst,p.nameLast
from Teams t,Managers m, People p,latest l
where l.teamID=t.teamID and t.teamID=m.teamID and t.lgID=m.lgID and t.yearID>=2000 and t.yearID<=2010 and  t.yearID=m.yearID and m.playerID=p.playerID and (m.inseason=0 or m.inseason=1)
group by t.teamID,l.tname,t.yearID,m.playerID,p.nameFirst,p.nameLast
order by t.teamID asc,l.tname asc,t.yearID desc,m.playerID asc,p.nameFirst asc,p.nameLast asc;

--16--
with awards(playerID,num) as
(
    select playerID,count(awardID) as c
    from AwardsPlayers
    group by playerID
    order by c desc limit 10
)
,latest(playerID,cname) as
(
    select s.playerID,s.schoolID
    from CollegePlaying s
    where s.yearID=(select coalesce(max(s1.yearID),0) from CollegePlaying s1 where s1.playerID=s.playerID)
),
school(playerID,sname,num) as
(
    select p.playerID,c.cname,a.num
    from People p left join latest c on(p.playerID=c.playerID),awards a where a.playerID=p.playerID
)
select s.playerID as playerid,coalesce(s1.schoolName,'') as colleges_name,s.num as total_awards
from school s left join Schools s1 on(s.sname=s1.schoolID)
order by total_awards desc,colleges_name asc,s.playerID asc;

--17--
with fplayer(playerID,awardID,yearID)
as
(
    select ap.playerID,ap.awardID,ap.yearID
    from AwardsPlayers ap
    where ap.yearID=(select coalesce(min(ap1.yearID),0) from AwardsPlayers ap1 where ap1.playerID=ap.playerID)
),
fplayer1(playerID,awardID,yearID)
as
(
    select ap.playerID,ap.awardID,ap.yearID
    from fplayer ap
    where ap.awardID=(select coalesce(min(ap1.awardID),'') from fplayer ap1 where ap1.playerID=ap.playerID)
),
fmanager(playerID,awardID,yearID)
as
(
    select ap.playerID,ap.awardID,ap.yearID
    from AwardsManagers ap
    where ap.yearID=(select coalesce(min(ap1.yearID),0) from AwardsManagers ap1 where ap1.playerID=ap.playerID)
),
fmanager1(playerID,awardID,yearID)
as
(
    select ap.playerID,ap.awardID,ap.yearID
    from fmanager ap
    where ap.awardID=(select coalesce(min(ap1.awardID),'') from fmanager ap1 where ap1.playerID=ap.playerID)
)
select distinct fp.playerID as playerid,p.nameFirst as firstname, p.nameLast as lastname,fp.awardID as playerawardid,fp.yearID as playerawardyear,fm.awardID as managerawardid,fm.yearID as managerawardyear
from fplayer1 fp,fmanager1 fm,People p
where fp.playerID=p.playerID and fm.playerID=fp.playerID 
order by fp.playerID asc, firstname asc, lastname asc;

--18--
with hof(playerID,num_honoured_categories) as
(
    select h.playerID,count(distinct h.category) 
    from HallOfFame h
    group by h.playerID
)
,
asp(playerID,seasonid) as
(
    select a.playerID,a.yearID
    from AllstarFull a
    where a.GP=1 and a.yearID=(select coalesce(min(a1.yearID),0) from AllstarFull a1 where a1.GP=1 and a1.playerID=a.playerID)
)
select p.playerID as playerid,p.nameFirst as firstname, p.nameLast as lastname,h.num_honoured_categories,a.seasonid
from People p,asp a,hof h
where p.playerID=a.playerID and p.playerID=h.playerID and h.num_honoured_categories>=2
order by h.num_honoured_categories desc,p.playerID asc ,firstname asc,lastname asc,a.seasonid asc;

--19--
with basemen(playerID,G_all,G_1b,G_2b,G_3b)
as
(
    select a.playerID,coalesce(sum(a.G_all),0),coalesce(sum(a.G_1b),0),coalesce(sum(a.G_2b),0),coalesce(sum(a.G_3b),0)
    from Appearances a
    group by a.playerID
)
select p.playerID as playerid,p.nameFirst as firstname , p.nameLast as lastname,b.G_all,b.G_1b,b.G_2b,b.G_3b
from basemen b,People p
where b.playerID=p.playerID and (b.G_1b*b.G_2b+b.G_1b*b.G_3b+b.G_2b*b.G_3b>0)
order by b.G_all desc,playerid asc,firstname asc,lastname asc,b.G_1b desc,b.G_2b desc,b.G_3b desc;

--20--
with num_players(schoolID,num) as
(
    select s.schoolID,count(distinct playerid) as n
    from CollegePlaying s
    group by s.schoolID
    order by n desc limit 5
)
select distinct s.schoolID as schoolid,s.schoolName as schoolname, lower(schoolCity ||' '|| schoolState) as schooladdr,p.playerID as playerid,p.nameFirst as firstname,p.nameLast as lastname
from num_players np,People p,Schools s,CollegePlaying cp
where np.schoolID=s.schoolID and np.schoolID=cp.schoolID and cp.playerID=p.playerID
order by schoolid asc,schoolname asc,schooladdr asc ,playerid asc,firstname asc,lastname asc;

--21--
with bat(playerID,yearID,teamID,birthCity,birthState) as
(
    select b.playerID,b.yearID,b.teamID,p.birthCity,p.birthState
    from Batting b,People p
    where b.playerID=p.playerID and p.birthCity is not null and p.birthState is not null
),
pitch(playerID,yearID,teamID,birthCity,birthState) as
(
    select b.playerID,b.yearID,b.teamID,p.birthCity,p.birthState
    from Pitching b,People p
    where b.playerID=p.playerID and p.birthCity is not null and p.birthState is not null 
),
batsame(player1,player2,birthCity,birthState) as
(
    select distinct b1.playerID,b2.playerID,b1.birthCity,b2.birthState
    from bat b1,bat b2
    where b1.birthCity=b2.birthCity and b1.birthState=b2.birthState and b1.playerID!=b2.playerID  and b1.teamID=b2.teamID
),
pitchsame(player1,player2,birthCity,birthState) as
(
    select distinct b1.playerID,b2.playerID,b1.birthCity,b2.birthState
    from pitch b1,pitch b2
    where b1.birthCity=b2.birthCity and b1.birthState=b2.birthState and b1.playerID!=b2.playerID  and b1.teamID=b2.teamID
),
bothbp as
(
    (
        select * from batsame
    )
    intersect
    (
        select * from pitchsame
    )
),
onlyb as
(
    (
        select * from batsame
    )
    except
    (
        select * from bothbp
    )
),
onlyp as
(
    (
        select * from pitchsame
    )
    except
    (
        select * from bothbp
    )
),
total(player1_id,player2_id,birthcity,birthstate,role) as
(
    (
        select player1,player2,birthCity,birthState,'batted' from onlyb
    )
    union
    (
        select player1,player2,birthCity,birthState,'pitched' from onlyp
    )
    union
    (
        select player1,player2,birthCity,birthState,'both' from bothbp
    )
)
select distinct * from total
order by birthcity asc,birthstate asc,player1_id asc ,player2_id asc;

--22--
select asp.awardID as awardid,asp.yearID as seasonid, asp.pointsWon as playerpoints ,asp.playerID as playerid
from AwardsSharePlayers asp
where asp.pointsWon>=(select coalesce(avg(asp1.pointsWon),0) from AwardsSharePlayers asp1 where asp1.awardID=asp.awardId and asp1.yearID=asp.yearID)
order by awardid asc,seasonid asc,playerpoints desc,playerid asc;

--23--
select distinct p.playerID as playerid,coalesce(p.nameFirst,'')||' '||p.nameLast as playername,not (cast(coalesce(p.deathDay,0) as bool) and cast(coalesce(p.deathMonth,0) as bool) and cast(coalesce(p.deathYear,0) as bool)) as alive
from People p
where p.playerID not in (select distinct playerID from AwardsManagers)and p.playerID not in (select distinct playerID from AwardsPlayers)
group by p.playerID,playername,p.deathDay,p.deathMonth,p.deathYear
order by p.playerID asc, playername asc;

--24--
with recursive  same_team(playerID,teamID,yearID) as
(
    (
        select playerID,teamID,yearID from Pitching
    )
    union
    (
        select playerID,teamID,yearID from AllstarFull
        where GP=1
    )
),
edges(playerID1,playerID2,edgewt) as
(
    select p1.playerID,p2.playerID,least(count(distinct p1.yearID),3)
    from same_team p1 ,same_team p2 
    where p1.teamID=p2.teamID and p1.yearID=p2.yearID and p1.playerID!=p2.playerID
    group by p1.playerID,p2.playerID
),
graph1(playerID1,playerID2,edgewt) as
(
    select playerID1,playerID2,edgewt from edges
    where playerID1='webbbr01' 
    union
    select g1.playerID1 as playerID1,ed.playerID2 as playerID2,least((g1.edgewt+ed.edgewt),3) as edgewt
    from graph1 g1,edges ed
    where g1.playerID2=ed.playerID1
)
select coalesce(max(edgewt),0)>=3 as pathexists 
from graph1
where playerID1='webbbr01' and playerID2='clemero02';

--25--
with recursive  same_team(playerID,teamID,yearID) as
(
    (
        select playerID,teamID,yearID from Pitching
    )
    union
    (
        select playerID,teamID,yearID from AllstarFull
        where GP=1
    )
),
edges(playerID1,playerID2,edgewt,n) as
(
    select p1.playerID,p2.playerID,count(distinct p1.yearID),0
    from same_team p1 ,same_team p2 
    where p1.teamID=p2.teamID and p1.yearID=p2.yearID and p1.playerID!=p2.playerID
    group by p1.playerID,p2.playerID
),
graph1(playerID1,playerID2,edgewt,n) as
(
    select playerID1,playerID2,edgewt,n from edges
    where playerID1='garcifr02' 
    union
    select g1.playerID1 as playerID1,ed.playerID2 as playerID2,g1.edgewt+ed.edgewt,g1.n+1
    from graph1 g1,edges ed
    where g1.playerID2=ed.playerID1 and g1.n<4
)
select coalesce(min(edgewt),100000) as pathlength 
from graph1
where playerID1='garcifr02' and playerID2='leagubr01';

--26--
with recursive edges(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select distinct teamIDwinner,teamIDloser,1,0,false,ARRAY[teamIDwinner]::text[] from SeriesPost
),
graph2(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select team1,team2,edgewt,depth,is_cycle,patharr 
    from edges 
    where edges.team1='ARI'
    union all
    select g2.team1,ed.team2,g2.edgewt+ed.edgewt,g2.depth+1,ed.team2=ANY(g2.patharr),g2.patharr||ed.team2::text
    from graph2 g2,edges ed
    where g2.team2=ed.team1 and not g2.is_cycle and g2.depth<6
)
select count(*) 
from  graph2 g2
where g2.team1='ARI' and g2.team2='DET';

--27--
with recursive edges(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select distinct teamIDwinner,teamIDloser,1,0,false,ARRAY[teamIDwinner]::text[] from SeriesPost
),
graph2(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select team1,team2,edgewt,depth,is_cycle,patharr 
    from edges 
    where edges.team1='HOU'
    union all
    select g2.team1,ed.team2,g2.edgewt+ed.edgewt,g2.depth+1,ed.team2=ANY(g2.patharr),g2.patharr||ed.team2::text
    from graph2 g2,edges ed
    where g2.team2=ed.team1 and not g2.is_cycle and g2.depth<4
)
select g2.team2 as teamid,max(g2.depth)+1 as num_hops 
from  graph2 g2
where g2.team1='HOU' and g2.team2!='HOU' and g2.depth<3
group by teamid
order by teamid asc;

--28--
with recursive edges(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select distinct teamIDwinner,teamIDloser,1,0,false,ARRAY[teamIDwinner]::text[] from SeriesPost
),
graph2(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select team1,team2,edgewt,depth,is_cycle,patharr 
    from edges 
    where edges.team1='WS1'
    union all
    select g2.team1,ed.team2,g2.edgewt+ed.edgewt,g2.depth+1,ed.team2=ANY(g2.patharr),g2.patharr||ed.team2::text
    from graph2 g2,edges ed
    where g2.team2=ed.team1 and not g2.is_cycle and g2.depth<5
),
latest(teamID,tname) as
(
    select distinct t.teamID,t.name from Teams t
    where t.yearID=(select max(t1.yearID) from Teams t1 where t1.teamID=t.teamID)
),
longestpath(teamID,pathlength) as
(
    select g2.team2,g2.depth from graph2 g2
    where g2.team1='WS1' and g2.depth+1=(select max(g3.depth)+1 from graph2 g3 where g3.team1='WS1')
)
select distinct lp.teamID as teamid,l.tname as teamname,lp.pathlength
from longestpath lp,latest l
where lp.teamID=l.teamID
order by teamid asc,teamname asc;

--29--
with recursive newteams(teamID) as
(
    (
        select distinct teamIDwinner from SeriesPost where ties>losses
    )
    union
    (    
        select distinct teamIDwinner from SeriesPost where ties>losses 
    )
)
, 
edges(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select distinct teamIDwinner,teamIDloser,1,0,false,ARRAY[teamIDwinner]::text[] from SeriesPost
),
graph2(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select team1,team2,edgewt,depth,is_cycle,patharr 
    from edges 
    where edges.team1='NYA'
    union all
    select g2.team1,ed.team2,g2.edgewt+ed.edgewt,g2.depth+1,ed.team2=ANY(g2.patharr),g2.patharr||ed.team2::text
    from graph2 g2,edges ed
    where g2.team2=ed.team1 and not g2.is_cycle and g2.depth<7
)
select distinct n.teamID as teamid ,g2.depth+1 as pathlength
from graph2 g2,newteams n
where n.teamID=g2.team2
order by teamid asc,pathlength asc; 

--30--
with recursive edges(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select distinct teamIDwinner,teamIDloser,1,0,false,ARRAY[teamIDwinner]::text[] from SeriesPost
),
graph2(team1,team2,edgewt,depth,is_cycle,patharr) as
(
    select team1,team2,edgewt,depth,is_cycle,patharr 
    from edges 
    where edges.team1='DET'
    union all
    select g2.team1,ed.team2,g2.edgewt+ed.edgewt,g2.depth+1,ed.team2=ANY(g2.patharr),g2.patharr||ed.team2::text
    from graph2 g2,edges ed
    where g2.team2=ed.team1 and not g2.is_cycle and g2.depth<7
)
select g2.depth+1 as cyclelength,count(distinct g2.patharr) as numcycles
from graph2 g2
where g2.team1='DET' and g2.team2='DET' and g2.depth=(select max(g3.depth) from graph2 g3 where g3.team1='DET' and g3.team2='DET')
group by cyclelength;