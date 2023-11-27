--P1--
--Q1--
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
    recm1(pid1,pid2,mutualFriendCount)AS
    (select pid1,pid2,count(pid1)
    from recm
    group by pid1,pid2
    ),
    table1(pid,onr,mid)as
    (select l.personid, p.creatorpersonid, p.id
    from post p,person_likes_post l
    where p.id=l.postid and p.creationdate<:lastdate
    union all
    select l.personid, p.creatorpersonid, p.id
    from comment p,person_likes_comment l
    where p.id=l.commentid and p.length>:commentlength
    ),
    table3(pid1,pid2,onr,mid,tp)as
    (select r.pid1,r.pid2,r.pid3,t.mid,0
    from table1 t,recm r
    where t.pid=r.pid1 and t.onr=r.pid3
    intersect
    select r.pid1,r.pid2,r.pid3,t.mid,0
    from table1 t,recm r
    where t.pid=r.pid2 and t.onr=r.pid3
    ),
    table10(pid1,pid2,cnt)AS
    (select pid1,pid2,count(pid1)
    from table3
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
--C1--

--P2--
--Q2--
with ta0(cntid)AS
    (select distinct id from place where name=:country_name
    ),
    tab0(cid)AS
    (select id
    from place 
    join ta0 on partofplaceid=cntid
    ),
    table0(id,birthmonth,univ)AS
    (select id,date_part('month',birthday),universityid
    from person p
    join tab0 on p.locationcityid=cid
    join person_studyat_university on p.id=personid
    where p.creationDate>:startdate and p.creationDate<:enddate
    ),
    table1(pid1,pid2) AS 
    (select p1.id,p2.id 
    from table0 p1
    join person_knows_person on p1.id=person1id
    join table0 p2 on p2.id=person2id
    where p1.id<p2.id and p1.univ=p2.univ and p1.birthmonth= p2.birthmonth
    ),
    table7(pid1,pid2)AS
    (select pid2,pid1
    from table1
    ),
    table8(pid1,pid2)AS  
    (select * 
    from table1 union all select * from table7
    ),
    table9(pid1,pid2,pid3)AS
    (select t1.pid1,t1.pid2,t2.pid2
    from table8 t1,table8 t2,table8 t3
    where t1.pid1<t1.pid2 and t1.pid2=t2.pid1 and t1.pid2<t2.pid2 and t2.pid2=t3.pid1 and t3.pid2=t1.pid1
    )
select count(pid1) as count 
from table9;
--C2-

-- P3--
create index idcd on comment_hastag_tag(creationDate);
create index idpd on post_hastag_tag(creationDate);
create index idtagid on tag(id);
--Q3--
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
--C3--
drop index idcd;
drop index idpd;
drop index idtagid;

--P4--
create index id_post on post(id);
create index id_comment on comment(id,ParentCommentId);
create index id_cht on comment_hastag_tag(CommentId,TagId);
create index id_pht on post_hastag_tag(PostId,TagId);
create index id_tid on tag(id);
--Q4--
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
    (select tid from tcmsg) union all (select tid from  tpmsg)
),
fcount(tid,c) as
(
    select tid,count(*) from final group by tid
)
select t.name as tagname,fc.c as count from fcount fc,tag t
where t.id=fc.tid
order by fc.c desc,t.name asc limit 10;
--C4--
drop index id_post;
drop index id_comment;
drop index id_cht;
drop index id_pht;
drop index id_tid;

--P5--
create index idp on place(id,PartOfPlaceId);
create index idp1 on person(id);
create index idp2 on forum(ModeratorPersonId);
--Q5--
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
--C5--
drop index idp ;
drop index idp1 ;
drop index idp2 ;