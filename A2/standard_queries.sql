--1--
with intr(pid,tname,tid) AS
    (select distinct p.PersonId,t.name,t.id
    from Person_hasInterest_Tag p,tag t
    where p.TagId=t.id 
    ),
    intr1(pid1,pid2,tid)AS
    (select distinct i1.pid,i2.pid,i1.tid
    from intr i1,intr i2
    where i1.tname in :taglist and i1.tid=i2.tid and i1.pid<i2.pid
    ),
    numintr(pid1,pid2,count) AS
    (select pid1,pid2,count(pid1)
    from intr1
    group by pid1,pid2
    ),
    numi(pid1,pid2) AS
    (select distinct pid1,pid2
    from numintr
    where count>=:K
    ),
    friends(pid1,pid2)AS
    (select Person1id,Person2id
    from Person_knows_Person
    union 
    select Person2id,Person1id
    from Person_knows_Person
    ),
    notf(pid1,pid2)AS 
    (select distinct *
    from numi except select * from friends
    ),
    recm(pid1,pid3,pid2)AS 
    (select distinct n.pid1,f1.pid2,n.pid2
    from notf n,friends f1,friends f2
    where n.pid1=f1.pid1 and f1.pid2=f2.pid1 and f2.pid2=n.pid2
    ),
    mcr(pid)AS
    (select distinct pid3 from recm
    ),
    cr(pid)AS
    (select distinct pid1 from recm
    ),
    recm1(pid1,pid2,mutualFriendCount)AS
    (select pid1,pid2,count(pid1)
    from recm
    group by pid1,pid2
    ),
    table1(pid,onr,mid)as
    (select l.personid, p.creatorpersonid, p.id
    from post p,person_likes_post l
    where p.id=l.postid and p.creationdate<:lastdate
    ),
    table2(pid,onr,mid)as
    (select l.personid, p.creatorpersonid, p.id
    from comment p,person_likes_comment l
    where p.id=l.commentid and p.length>:commentlength
    ),
    table3(pid1,pid2,onr,mid,tp)as
    (select r.pid1,r.pid2,r.pid3,t.mid,0
    from table1 t,recm r
    where t.pid=r.pid1 and t.onr=r.pid3
    ),
    table4(pid1,pid2,onr,mid,tp)as
    (select r.pid1,r.pid2,r.pid3,t.mid,0
    from table1 t,recm r
    where t.pid=r.pid2 and t.onr=r.pid3
    ),
    table5(pid1,pid2,onr,mid,tp)as
    (select r.pid1,r.pid2,r.pid3,t.mid,1
    from table2 t,recm r
    where t.pid=r.pid1 and t.onr=r.pid3
    ),
    table6(pid1,pid2,onr,mid,tp)as
    (select r.pid1,r.pid2,r.pid3,t.mid,1
    from table2 t,recm r
    where t.pid=r.pid2 and t.onr=r.pid3
    ),
    table7(pid1,pid2,onr,mid,tp)AS
    (select * from table3 INTERSECT select * from table4
    ),
    table8(pid1,pid2,onr,mid,tp)AS
    (select * from table5 intersect select * from table6
    ),
    table9(pid1,pid2,onr,mid,tp)AS
    (select * from table7 union select* from table8
    ),
    table10(pid1,pid2,cnt)AS
    (select pid1,pid2,count(pid1)
    from table9
    group by pid1,pid2
    ),
    table11(pid1,pid2,cnt) AS
    (select distinct * from table10
    where cnt>=:X
    )
select t.pid1 as person1sid,t.pid2 as person2sid,mutualFriendCount 
from table11 t,recm1 r 
where t.pid1<t.pid2 and t.pid1=r.pid1 and t.pid2=r.pid2 
order by person1sid asc,mutualFriendCount desc,person2sid asc;

--2--
with tab0(cid,cname)AS
    (select t1.id,t2.name
    from place t1,place t2
    where t1.type='City' and t1.PartOfPlaceId=t2.id
    ),
    table0(id,birthday)AS
    (select p1.id,p1.birthday
    from person p1,tab0 t1
    where p1.creationDate>:startdate and p1.creationDate<:enddate and p1.LocationCityId=t1.cid and t1.cname=:country_name
    ),
    table1(pid1,pid2) AS 
    (select p1.id,p2.id 
    from table0 p1,table0 p2
    where EXTRACT(MONTH FROM p1.birthday)=EXTRACT(MONTH FROM p2.birthday)
    ),
    table2(id,univ)AS 
    (select p1.id,u.UniversityId
    from table0 p1,Person_studyAt_University u
    where p1.id=u.PersonId
    ),
    table3(pid1,pid2)as 
    (select p1.id,p2.id 
    from table2 p1,table2 p2
    where p1.univ=p2.univ
    ),
    table4(pid1,pid2)AS 
    (select *
    from table1 intersect  select * from table3
    ),
    table5(pid1,pid2)AS
    (select Person1id,Person2id
    from Person_knows_Person
    ),
    table6(pid1,pid2)AS 
    (select *
    from table4  intersect select * from table5
    ),
    table7(pid1,pid2)AS
    (select pid2,pid1
    from table6
    ),
    table8(pid1,pid2)AS  
    (select * 
    from table6 union all select * from table7
    ),
    table9(pid1,pid2,pid3)AS
    (select t1.pid1,t1.pid2,t2.pid2
    from table8 t1,table8 t2,table8 t3
    where t1.pid2=t2.pid1 and t1.pid2!=t2.pid2 and t2.pid2=t3.pid1 and t3.pid2=t1.pid1
    )
select count(pid1)/6 as count 
from table9;

--3--
with temp1(tid) as
(
    (
        select c.TagId
        from comment_hastag_tag c
        where c.creationDate>=:begindate and c.creationDate<=:middate
    )
    union all
    (
        select c.TagId
        from post_hastag_tag c
        where c.creationDate>=:begindate and c.creationDate<=:middate
    )
),
temp2(tid) as
(
    (
        select c.TagId
        from comment_hastag_tag c
        where c.creationDate>=:middate and c.creationDate<=:enddate
    )
    union all
    (
        select c.TagId
        from post_hastag_tag c
        where c.creationDate>=:middate and c.creationDate<=:enddate
    )
),
count1(tid,cmsg) as
(
    select tid,count(*) from temp1 group by tid
),
count2(tid,cmsg) as
(
    select tid,count(*) from temp2 group by tid
),
final(tcname,tid) as
(
    select tc.name,c1.tid from count1 c1,count2 c2,tag t,tagclass tc
    where c1.tid=c2.tid and c1.cmsg>=5*c2.cmsg and t.id=c1.tid and tc.id=t.TypeTagClassId 
)
select tcname as tagclassname,count(*) as count from final group by tcname order by count desc ,tagclassname asc;

--4--
with post1(pid,cpid) as
(
    select p.id,c.id from post p,comment c
    where p.id=c.ParentPostId
),
comment1(pid,cpid) as
(
    select c1.id,c2.id from comment c1,comment c2
    where c1.id=c2.ParentCommentId
),
cmsg(pid,cmsg) as
(
    select pid,count(*) from comment1 group by pid
),
pmsg(pid,cmsg) as
(
    select pid,count(*) from post1 group by pid
),
tcmsg(tid) as
(
    select cht.TagId from comment_hastag_tag cht,cmsg c
    where c.pid=cht.CommentId and c.cmsg>=:X
),
tpmsg(tid) as
(
    select pht.TagId from post_hastag_tag pht,pmsg p
    where p.pid=pht.PostId and p.cmsg>=:X
),
final(tid) as
(
    (select * from tcmsg) union all (select * from  tpmsg)
),
fcount(tid,c) as
(
    select tid,count(*) from final group by tid
)
select t.name as tagname,fc.c as count from fcount fc,tag t
where t.id=fc.tid
order by fc.c desc,t.name asc limit 10;

--5--
with country_forum(fid) as
(
    select distinct f.id from person p1,place p3,place p2,forum f
    where p1.LocationCityId=p2.id and p3.id=p2.PartOfPlaceId and f.ModeratorPersonId=p1.id and p3.name=:country_name
),
post_forum(fid) as
(
    select cf.fid from country_forum cf
    where exists 
    (
        select 1 from post p,post_hastag_tag pht,tag t, tagclass tc 
        where p.ContainerForumId=cf.fid and pht.PostId=p.id and pht.TagId=t.id and t.TypeTagClassId=tc.id and tc.name=:tagclass
    )
),
tag_count(fid,tid,cnt) as
(
    select pf.fid,pht.TagId,count(*) as cnt
    from post_forum pf,post_hastag_tag pht,post p
    where p.ContainerForumId=pf.fid and pht.PostId=p.id
    group by pf.fid,pht.TagId
),
max_tag(fid,cnt) as
(
    select fid,max(cnt)
    from tag_count
    group by fid
)
select tc.fid as forumid,f.title as forumtitle,t.name as mostpopulartagname,tc.cnt as count
from tag_count tc,max_tag mt,tag t,forum f
where tc.fid=mt.fid and tc.cnt=mt.cnt and tc.fid=f.id and t.id=tc.tid
order by count desc,forumid asc,forumtitle asc,mostpopulartagname asc;