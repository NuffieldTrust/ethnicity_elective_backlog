/*Create a patient index */
/*Reassign ethnicity according to CHIME tool ruleset*/
/*Attach updated ethnicity to data*/

libname hes "~\HES Datasets\with_token_id";
libname hesm "~\hes data Y2122 M11 - received 20220414\Formatted";
libname proj "~\Ethnicity Elective Backlog\Sensitive\v9";



/*Use main table as base so that we only reassign ethnicity for those we are analysing.*/
/*for now using inpatient data back to 2016*/

proc sql;
	create table proj.patients as 
	select distinct
		token_person_id
	from proj.ip_all_m11
;
quit;

/*Now join back to the original tables to get all of the activity (not just electives)*/
/*proj.patient_index1 = 1 row per episode*/
proc sql;
	create table proj.patient_index1 as 
	select
		a.epikey
		, a.token_person_id
		, case when a.ethnos = '99' then 'X'
				when a.ethnos not in ('A', 'B', 'C','D','E','F','G','H','J','K','L','M','N','P','R','S','Z', '99') then 'U' 
				else a.ethnos 
			end as ethnos
		, a.admidate
	from hesm.ip21m a inner join proj.patients b on a.token_person_id = b.token_person_id
	union all
	select
		a.epikey
		, a.token_person_id
		, case when a.ethnos = '99' then 'X'
				when a.ethnos not in ('A', 'B', 'C','D','E','F','G','H','J','K','L','M','N','P','R','S','Z', '99') then 'U' 
				else a.ethnos 
			end as ethnos
		, a.admidate
	from hes.ip20 a inner join proj.patients b on a.token_person_id = b.token_person_id
	union all
	select
		a.epikey
		, a.token_person_id
		, case when a.ethnos = '99' then 'X'
				when a.ethnos not in ('A', 'B', 'C','D','E','F','G','H','J','K','L','M','N','P','R','S','Z', '99') then 'U' 
				else a.ethnos 
			end as ethnos
		, a.admidate
	from hes.ip19 a inner join proj.patients b on a.token_person_id = b.token_person_id
	union all
	select
		a.epikey
		, a.token_person_id
		, case when a.ethnos = '99' then 'X'
				when a.ethnos not in ('A', 'B', 'C','D','E','F','G','H','J','K','L','M','N','P','R','S','Z', '99') then 'U' 
				else a.ethnos 
			end as ethnos
		, a.admidate
	from hes.ip18 a inner join proj.patients b on a.token_person_id = b.token_person_id
	union all
	select
		a.epikey
		, a.token_person_id
		, case when a.ethnos = '99' then 'X'
				when a.ethnos not in ('A', 'B', 'C','D','E','F','G','H','J','K','L','M','N','P','R','S','Z', '99') then 'U' 
				else a.ethnos 
			end as ethnos
		, a.admidate
	from hes.ip17 a inner join proj.patients b on a.token_person_id = b.token_person_id
	union all
	select
		a.epikey
		, a.token_person_id
		, case when a.ethnos = '99' then 'X'
				when a.ethnos not in ('A', 'B', 'C','D','E','F','G','H','J','K','L','M','N','P','R','S','Z', '99') then 'U' 
				else a.ethnos 
			end as ethnos
		, a.admidate
	from hes.ip16 a inner join proj.patients b on a.token_person_id = b.token_person_id
;
quit;

/*proj.patient_index2 = 1 row per ethnicity record of each person*/
proc sql;
	create table proj.patient_index2 as
	select
		token_person_id
		, ethnos
		, count(*) as ethnos_count_n /* number of instances of each ethnos */
	from proj.patient_index1
	group by
		token_person_id
		, ethnos
;
quit;

/*Ignoring unknowns and not stateds:*/
/*Find the most frequently recorded ethnicity*/
/*In case of ties use the most recent date*/
/*If dates are the same use APC, then AE, then OP (what about ECDS?)*/
/*If there is still a tie, use the ethnicity that occurs more frequently in the population */
/*If the most common group is other (S), then use the 2nd most frequent instead.*/



/*proj.patient_index3 = 1 row per valid ethnicity*/
/*It's proj.patient_index2 without Z's and X/99s*/
/*remove invalid ethnicity records - we might have to go back later to reassign any of those*/
proc sql;
	create table proj.patient_index3 as
	select
		token_person_id
		, ethnos
		, ethnos_count_n
	from proj.patient_index2
	where ethnos in ('A', 'B', 'C','D','E','F','G','H','J','K','L','M','N','P','R','S')
;
quit;

/*oh, but wait, what about those where we need to switch from S*/
/*better to do the counts, add the dates, order by desc count, desc date, assign position 1, 2, 3...*/
/*exchange position 1 = S with position 2*/

/*proj.patient_index5 = 1 row per valid ethnicity */
/*start from 4, add dates from 1*/
proc sql;
	create table proj.patient_index4 as
	select 
		a.token_person_id
		, a.ethnos
		, a.ethnos_count_n
		, max(b.admidate) as admidate_latest format date9.
	from
		proj.patient_index3 a
			left join proj.patient_index1 b on a.token_person_id = b.token_person_id and a.ethnos = b.ethnos
	group by
		a.token_person_id
		, a.ethnos
		, a.ethnos_count_n
	order by
		a.token_person_id
		, a.ethnos_count_n desc
		, admidate_latest desc
;
quit;


/*no longer used but kept for completeness */
/*proc sql;*/
/*	create table proj.patient_index5 as */
/*	select token_person_id*/
/*		, count(*) as ethnos_count_valid*/
/*		, sum(ethnos_count_n) as ethnos_valid_n*/
/*	from proj.patient_index4*/
/*	group by token_person_id*/
/*;*/
/*quit;*/

/* proj.patient_index6 = 1 row per valid ethnicity */
/* add rank to 5*/
data proj.patient_index6;
	set proj.patient_index4;
	by token_person_id descending ethnos_count_n  descending admidate_latest;
	if first.token_person_id then 
		rank = 1;
	else
		rank + 1;
run;

/*count people check*/
proc sql;
	select count(*) as ppl_rank from proj.patient_index6 where rank = 1
;
	select count(*) as ppl_distinct from (select distinct token_person_id from proj.patient_index6)
;
quit;

/*when working with multiple datasets we should check for multiples on the same date, but here we are only using IP so let's move on*/



/*proj.patient_index7 - all possible 2nd ranks */
proc sql;
	create table proj.patient_index7 as 
	select * 
	from proj.patient_index6
	where rank = 2 and ethnos ne 'S'
;
quit;


/*proj.patient_index8 - the replacements when rank 1 = S*/
proc sql;
	create table proj.patient_index8 as
	select a.token_person_id
		, b.ethnos
	from proj.patient_index6 a 
		inner join proj.patient_index7 b on 
			a.token_person_id = b.token_person_id 
	where a.rank = 1 and a.ethnos = 'S'
;
quit;


/*from 6, take top rank, replace with 8 if valid */
proc sql;
	create table proj.patient_index9 as 
	select 
		a.token_person_id
		, coalesce(b.ethnos, a.ethnos) as ethnos
	from proj.patient_index6 a
		left join proj.patient_index8 b on a.token_person_id = b.token_person_id
	where 
		a.rank = 1
;
quit;

/*now add back to main list */
proc sql;
	create table proj.patient_index10 as 
	select
		a.token_person_id
		, b.ethnos 
	from proj.patients a
		left join proj.patient_index9 b on a.token_person_id = b.token_person_id
;
quit;


/*Find those missing an ethnicity who were not stated*/


/*Now we have missing ethnos so let's give each record a random number using population figures from Census 2011*/

data proj.patient_index11;
	call streaminit(31415926); /* random seed - tastes like pie*/
	set proj.patient_index10(where = (ethnos = ' '));
	drop ethnos;
	rand = rand('uniform');
	     if rand le 0.805 then ethnos5 = 'A';
	else if rand le 0.85  then ethnos5 = 'C';
	else if rand le 0.875 then ethnos5 = 'H';
	else if rand le 0.895 then ethnos5 = 'J';
	else if rand le 0.913 then ethnos5 = 'N';
	else if rand le 0.928 then ethnos5 = 'L';
	else if rand le 0.939 then ethnos5 = 'M';
	else if rand le 0.948 then ethnos5 = 'B';
	else if rand le 0.956 then ethnos5 = 'K';
	else if rand le 0.964 then ethnos5 = 'D';
	else if rand le 0.971 then ethnos5 = 'R';
	else if rand le 0.977 then ethnos5 = 'F';
	else if rand le 0.982 then ethnos5 = 'G';
	else if rand le 0.987 then ethnos5 = 'P';
	else if rand le 0.99  then ethnos5 = 'E';
	else if rand le 1     then ethnos5 = 'S';
run;

PROC IMPORT OUT= proj.ethpop_lookup 
            DATAFILE= "~\Ethnicity Elective Backlog\Aggregated\ethpop_lookup.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="ethnos_to_ethpop$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;



/*N.B. episode based*/
proc sql;
	create table reassign_tmp as 
	select 
		a.epikey
		, a.token_person_id
		, a.ethnos
		, d.rand
		, coalesce(b.ethnos, a.ethnos) as ethnos2 /* most common, most recent if tied,  */
		/*if tied, precedence to APC -> AE -> OP*/
		/*if tied, precedence to the most common ethnicity in population (haven't needed to do this)*/
		, coalesce(c.ethnos, a.ethnos) as ethnos3 /* S - Any other ethnic group reallocated */
		, case when a.ethnos = 'Z' and b.ethnos is null then 'Z' else 
			 coalesce(d.ethnos5, c.ethnos, a.ethnos) end as ethnos4 /* redistribute not known but not not stated */
		, coalesce(d.ethnos5, c.ethnos, a.ethnos) as ethnos5 /* redistributed not stated too */


	from proj.ip_all_m11 a
		left join (
			select token_person_id, ethnos
			from proj.patient_index6
			where rank = 1
			) b on a.token_person_id = b.token_person_id
		left join proj.patient_index10 c on a.token_person_id = c.token_person_id
		left join proj.patient_index11 d on a.token_person_id = d.token_person_id

;
	create table proj.reassign_final as 
	select 
		a.epikey
		, a.token_person_id
		, a.rand
		, a.ethnos
		, a.ethnos2
		, a.ethnos3
		, a.ethnos4
		, a.ethnos5
		, b.ethpop
		, c.ethpop as ethpop2
		, d.ethpop as ethpop3
		, e.ethpop as ethpop4
		, f.ethpop as ethpop5
		, b.ethpop_broad
		, c.ethpop_broad as ethpop_broad2
		, d.ethpop_broad as ethpop_broad3
		, e.ethpop_broad as ethpop_broad4
		, f.ethpop_broad as ethpop_broad5
		

	from reassign_tmp a
		left join proj.ethpop_lookup b on a.ethnos  = b.ethnos
		left join proj.ethpop_lookup c on a.ethnos2 = c.ethnos
		left join proj.ethpop_lookup d on a.ethnos3 = d.ethnos
		left join proj.ethpop_lookup e on a.ethnos4 = e.ethnos
		left join proj.ethpop_lookup f on a.ethnos5 = f.ethnos
		
;
quit;



proc sql;
	create table proj.ip_m11_re as
	select a.*
		, b.ethnos2
		, b.ethnos3
		, b.ethnos4
		, b.ethnos5
		, b.ethpop
		, b.ethpop2
		, b.ethpop3
		, b.ethpop4
		, b.ethpop5
		, b.ethpop_broad
		, b.ethpop_broad2
		, b.ethpop_broad3
		, b.ethpop_broad4
		, b.ethpop_broad5

	from proj.ip_all_m11 a
		left join proj.reassign_final b on a.epikey = b.epikey
;
quit;





proc sql;
	create table proj.realloc_ppl as
	select
		count(*) as episodes
		, ethpop_broad
		, 'original' as type
	from proj.reassign_final
	group by ethpop_broad
	union all
	select
		count(*) as episodes
		, ethpop_broad2
		, '2' as type
	from proj.reassign_final
	group by ethpop_broad2
	union all
	select
		count(*) as episodes
		, ethpop_broad3
		, '3' as type
	from proj.reassign_final
	group by ethpop_broad3
	union all
	select
		count(*) as episodes
		, ethpop_broad4
		, '4' as type
	from proj.reassign_final
	group by ethpop_broad4
	union all
	select
		count(*) as episodes
		, ethpop_broad5
		, '5' as type
	from proj.reassign_final
	group by ethpop_broad5
;
quit;

proc sql;
	create table proj.realloc_effects as
	select
		count(*) as episodes
		, ethnos
		, 'original' as type
	from proj.ip_m11_re
	group by ethnos
	union all
	select
		count(*) as episodes
		, ethnos2
		, '2' as type
	from proj.ip_m11_re
	group by ethnos2
	union all
	select
		count(*) as episodes
		, ethnos3
		, '3' as type
	from proj.ip_m11_re
	group by ethnos3
	union all
	select
		count(*) as episodes
		, ethnos4
		, '4' as type
	from proj.ip_m11_re
	group by ethnos4
	union all
	select
		count(*) as episodes
		, ethnos5
		, '5' as type
	from proj.ip_m11_re
	group by ethnos5
;
quit;

proc sql;
	create table proj.realloc_effects_ppl as
	select
		count(distinct token_person_id) as people
		, count(*) as episodes
		, ethpop_broad
		, 'original' as type
	from proj.ip_m11_re
	where period_year = '201920'
	group by ethpop_broad

	union all
	select
		count(distinct token_person_id) as people
		, count(*) as episodes
		, ethpop_broad2
		, '2' as type
	from proj.ip_m11_re
	where period_year = '201920'
	group by ethpop_broad2
	union all
	select
		count(distinct token_person_id) as people
		, count(*) as episodes
		, ethpop_broad3
		, '3' as type
	from proj.ip_m11_re
	where period_year = '201920'
	group by ethpop_broad3
	union all
	select
		count(distinct token_person_id) as people
		, count(*) as episodes
		, ethpop_broad4
		, '4' as type
	from proj.ip_m11_re
	where period_year = '201920'
	group by ethpop_broad4
;
quit;
proc sql;
	create table proj.realloc_effects_ppl_nrw as
	select
		count(distinct token_person_id) as people
		, count(*) as episodes
		, ethnos
		, 'original' as type
	from proj.ip_m11_re
	where period_year = '201920'
	group by ethnos

	union all
	select
		count(distinct token_person_id) as people
		, count(*) as episodes
		, ethnos2
		, '2' as type
	from proj.ip_m11_re
	where period_year = '201920'
	group by ethnos2
	union all
	select
		count(distinct token_person_id) as people
		, count(*) as episodes
		, ethnos3
		, '3' as type
	from proj.ip_m11_re
	where period_year = '201920'
	group by ethnos3
	union all
	select
		count(distinct token_person_id) as people
		, count(*) as episodes
		, ethnos4
		, '4' as type
	from proj.ip_m11_re
	where period_year = '201920'
	group by ethnos4
;
quit;
proc sql;
	create table proj.realloc_effects_broad as
	select
		count(*) as episodes
		, ethpop_broad
		, 'original' as type
	from proj.ip_m11_re
	group by ethpop_broad
	union all
	select
		count(*) as episodes
		, ethpop_broad2
		, '2' as type
	from proj.ip_m11_re
	group by ethpop_broad2
	union all
	select
		count(*) as episodes
		, ethpop_broad3
		, '3' as type
	from proj.ip_m11_re
	group by ethpop_broad3
	union all
	select
		count(*) as episodes
		, ethpop_broad4
		, '4' as type
	from proj.ip_m11_re
	group by ethpop_broad4
	union all
	select
		count(*) as episodes
		, ethpop_broad5
		, '5' as type
	from proj.ip_m11_re
	group by ethpop_broad5
;
quit;


proc sql;
	create table proj.ct_reassign_ethnos as
	select 
		count(*) as episodes
		, b.ethnos
		, b.ethnos2
		, b.ethnos3
		, b.ethnos4

	from proj.ip_m11_re b
	group by 
		b.ethnos
		, b.ethnos2
		, b.ethnos3
		, b.ethnos4

;
quit;

proc sql;
	create table proj.ct_reassign_ethnos_ppl as
	select 
		count(token_person_id) as people
		, b.ethnos
		, b.ethnos2
		, b.ethnos3
		, b.ethnos4

	from proj.ip_m11_re b
	group by 
		b.ethnos
		, b.ethnos2
		, b.ethnos3
		, b.ethnos4

;
quit;


proc sql;
	create table proj.ct_reassign_ethpop as
	select 
		count(*) as episodes
		, b.ethpop
		, b.ethpop2
		, b.ethpop3
		, b.ethpop4

	from proj.ip_m11_re b
	group by 
		  b.ethpop
		, b.ethpop2
		, b.ethpop3
		, b.ethpop4

;
quit;
proc sql;
	create table proj.ct_reassign_ethpop_broad as
	select 
		count(*) as episodes
		, b.ethpop_broad
		, b.ethpop_broad2
		, b.ethpop_broad3
		, b.ethpop_broad4

	from proj.ip_m11_re b
	group by 
	b.ethpop_broad
		, b.ethpop_broad2
		, b.ethpop_broad3
		, b.ethpop_broad4

;
quit;





