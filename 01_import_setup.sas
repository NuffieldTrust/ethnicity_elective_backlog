/* Let's go */
libname hes "~\HES Datasets\with_token_id";
libname hesm "~\hes data Y2122 M11 - received 20220414\Formatted";
libname proj "~\Ethnicity Elective Backlog\Sensitive\v9";



%macro create_hes_vw(year);


%if &year lt 21 %then %do;
	%let heslib = hes;
	%let fyear = &year;
	%let susspellid = susspellid;
	%let classpat = classpat;
	%let rururb_ind = rururb_ind;
%end;
%else %do;
	%let heslib = hesm;
	%let fyear = 21m;
	%let susspellid = put(susspellid, 32.) as susspellid;
	%let classpat = put(classpat, 3.);
	%let rururb_ind = put(rururb_ind, 3.) as rururb_ind;
%end;



proc sql;
	create view proj.vw_ip&fyear. as
	select
		epikey
		, xhesid
		, token_person_id
		, &susspellid.
		, procode3
		, substr(put(admidate, yymmdd10.), 1, 7) as admiyearmon
		, catx(''
			, case when month(admidate) lt 3 then year(admidate) - 1
				else year(admidate) end
			, (case when month(admidate) lt 3 then year(admidate)
				else year(admidate) + 1 end - 2000)
			) as period_year
		, case 
				when month(admidate) ge 3 and month(admidate) le 9 then 'MarchToSept'
				when month(admidate) ge 10 or month(admidate) le 2 then 'OctoberToFeb'
				else 'Unknown' end as period_partyear
		, catx(''
			, case when month(admidate) lt 3 then year(admidate) - 1
				else year(admidate) end
			, (case when month(admidate) lt 3 then year(admidate)
				else year(admidate) + 1 end - 2000)
			, case 
				when month(admidate) ge 3 and month(admidate) le 9 then 'MarchToSept'
				when month(admidate) ge 10 or month(admidate) le 2 then 'OctoberToFeb'
				else 'Unknown' end) as period
		, admidate
		, admimeth
		, &classpat. as classpat
		, mainspef
		, tretspef
		, diag_01
		, opertn_01
		, case 
			when opertn_01 like 'W37%' then 'hips_and_knees'
			when opertn_01 like 'W38%' then 'hips_and_knees'
			when opertn_01 like 'W39%' then 'hips_and_knees'
			when opertn_01 like 'W40%' then 'hips_and_knees'
			when opertn_01 like 'W41%' then 'hips_and_knees'
			when opertn_01 like 'W42%' then 'hips_and_knees'
			when opertn_01 like 'F09%' then 'dental'
			when opertn_01 like 'F10%' then 'dental'
			when opertn_01 like 'F11%' then 'dental'
			when opertn_01 like 'F12%' then 'dental'
			when opertn_01 like 'F13%' then 'dental'
			when opertn_01 like 'F14%' then 'dental'
			when opertn_01 like 'F15%' then 'dental'
			when opertn_01 like 'F16%' then 'dental'
			when opertn_01 like 'F17%' then 'dental'
			when opertn_01 like 'C71%' then 'cataract'
			when opertn_01 like 'C72%' then 'cataract'
			when opertn_01 like 'C73%' then 'cataract'
			when opertn_01 like 'C74%' then 'cataract'
			when opertn_01 like 'C75%' then 'cataract'
			when opertn_01 like 'C79%' then 'cataract'
			when opertn_01 like 'G45%' then 'gi_endoscopy_diagnostic'
			when opertn_01 like 'H22%' then 'gi_endoscopy_diagnostic'
			when opertn_01 like 'H25%' then 'gi_endoscopy_diagnostic'
			when opertn_01 like 'G43%' then 'gi_endoscopy_therapeutic'
			when opertn_01 like 'G44%' then 'gi_endoscopy_therapeutic'
			when opertn_01 like 'H20%' then 'gi_endoscopy_therapeutic'
			when opertn_01 like 'H23%' then 'gi_endoscopy_therapeutic'
			when opertn_01 like 'K63%' then 'cardiac_diagnostic'
			when opertn_01 like 'K60%' then 'cardiac_therapeutic'
			when opertn_01 like 'K61%' then 'cardiac_therapeutic'
			when opertn_01 like 'K75%' then 'cardiac_therapeutic'
			when opertn_01 like 'K62%' then 'cardiac_therapeutic'
			when opertn_01 like 'K57%' then 'cardiac_therapeutic'
			when opertn_01 like 'K59%' then 'cardiac_therapeutic'
			when opertn_01 like 'K26%' then 'cardiac_therapeutic'
			when opertn_01 like 'K45%' then 'cardiac_therapeutic'
			when opertn_01 = ' ' then 'none'
			when opertn_01 = '-' then 'none'
			when opertn_01 = '&' then 'none'
			else 'other'
			end as proc_group
		, sex
		, case when sex = 1 then 'M' 
					when sex = 2 then 'F'
					else 'U'
					end as sex_clean
		, case when ethnos = '99' then 'X'
				when ethnos not in ('A', 'B', 'C','D','E','F','G','H','J','K','L','M','N','P','R','S','Z', '99') then 'U' 
				else ethnos 
			end as ethnos
		, case 
			when ethnos = 'A' or ethnos = 'B' then 'WBI'
			when ethnos = 'C' then 'WHO'
			when ethnos = 'D' or ethnos = 'E' or ethnos = 'F' or ethnos = 'G' then 'MIX'
			when ethnos = 'H' then 'IND'
			when ethnos = 'J' then 'PAK'
			when ethnos = 'K' then 'BAN'
			when ethnos = 'L' then 'OAS'
			when ethnos = 'M' then 'BLC'
			when ethnos = 'N' then 'BLA'
			when ethnos = 'P' then 'OBL'
			when ethnos = 'R' then 'CHI'
			when ethnos = 'S' then 'OTH'
			when ethnos = 'X' or ethnos = '99' then 'X'
			when ethnos = 'Z' then 'Z'
			else 'U'
			end as ethnos_ethpop
		, startage
		, case 
			when startage < 120 then startage 
			when startage > 7000 then 0
			else .
			end as startage_clean
		, case 
			when startage ge 0 and startage le 17 then '0to17'
			when startage ge 18 and startage le 64 then '18to64'
			when startage ge 65 and startage le 120 then '65plus'
			when startage ge 7001 and startage le 7007 then '0to17'
			else 'unknown'
			end as age_broad
		, case 
			when startage ge  0 and startage le  9 then '00to09'
			when startage ge 10 and startage le 19 then '10to19'
			when startage ge 20 and startage le 29 then '20to29'
			when startage ge 30 and startage le 39 then '30to39'
			when startage ge 40 and startage le 49 then '40to49'
			when startage ge 50 and startage le 59 then '50to59'
			when startage ge 60 and startage le 69 then '60to69'
			when startage ge 70 and startage le 79 then '70to79'
			when startage ge 80 and startage le 89 then '80to89'
			when startage ge 90 and startage le 120 then '90plus'
			when startage ge 7001 and startage le 7007 then '00to09'
			else 'unknown'
			end as age_10			
		, case 
			when imd04rk >= 1     and imd04rk <= 3248  then 1
			when imd04rk >= 3249  and imd04rk <= 6496  then 2
			when imd04rk >= 6497  and imd04rk <= 9745  then 3
			when imd04rk >= 9746  and imd04rk <= 12993 then 4
			when imd04rk >= 12994 and imd04rk <= 16241 then 5
			when imd04rk >= 16242 and imd04rk <= 19489 then 6
			when imd04rk >= 19490 and imd04rk <= 22737 then 7
			when imd04rk >= 22738 and imd04rk <= 25986 then 8
			when imd04rk >= 25987 and imd04rk <= 29234 then 9
			when imd04rk >= 29235 and imd04rk <= 32482 then 10
			else .
			end as imd_decile
		, lsoa11
		, msoa11
		, procodet
		, resgor
		, resgor_ons
		, resladst
		, resladst_ons
		, &rururb_ind.
		, sitetret
		, spelbgin
		, speldur
		, spelend
		, waitdays
		, elecdur
		, elecdate
		, epiorder
		, disdate
		, (case when elecdur in (9998, 9999) then . else elecdur end) / 7 as elecdur_weeks
		, (waitdays / 7) as waitweeks
		, case
			when opertn_01 like 'X40%' then 1
			when opertn_01 like 'X71%' then 1
			when opertn_01 like 'X70%' then 1
			when opertn_01 like 'X65%' then 1
			when opertn_01 like 'X36%' then 1
			when opertn_01 like 'X72%' then 1
			when opertn_01 like 'X29%' then 1
			when opertn_01 like 'L91%' then 1
			when opertn_01 like 'X92%' then 1
			when opertn_01 like 'X33%' then 1
			when opertn_01 like 'X96%' then 1
			when opertn_01 like 'X38%' then 1
			when opertn_01 like 'X89%' then 1
			when opertn_01 like 'X90%' then 1
			when opertn_01 like 'X67%' then 1
			when opertn_01 like 'M49%' then 1
			when opertn_01 like 'W36%' then 1
			when opertn_01 like 'S12%' then 1
			when opertn_01 like 'S57%' then 1
			when opertn_01 like 'X37%' then 1
			when opertn_01 like 'R37%' then 1
			else 0
			end as excludeproc



	from &heslib..ip&fyear.
	where 
		admimeth like '1%'
		and admidate ge "01Mar17"d
		and lsoa11 like 'E%'
		and &classpat. ne '3' and &classpat. ne '4'
		
;
quit;
%mend create_hes_vw;

%create_hes_vw(16);
%create_hes_vw(17);
%create_hes_vw(18);
%create_hes_vw(19);
%create_hes_vw(20);
%create_hes_vw(21);


proc sql;
	create table volcheck as
	select count(*) as episodes, 16 as year from proj.vw_ip16 union all
	select count(*) as episodes, 17 as year from proj.vw_ip17 union all
	select count(*) as episodes, 18 as year from proj.vw_ip18 union all
	select count(*) as episodes, 19 as year from proj.vw_ip19 union all
	select count(*) as episodes, 20 as year from proj.vw_ip20 union all
	select count(*) as episodes, 21 as year from proj.vw_ip21m 
;
quit;


/* Views of HES by episodes*/
proc sql;
	create view proj.vw_all as
	select * from proj.vw_ip16 union all
	select * from proj.vw_ip17 union all
	select * from proj.vw_ip18 union all
	select * from proj.vw_ip19 union all
	select * from proj.vw_ip20 union all
	select * from proj.vw_ip21m
;
quit;


/*Create a working table to use*/

PROC IMPORT OUT= proj.lsoa_region_lookup 
            DATAFILE= "~\Ethnicity Elective Backlog\Aggregated\la_region\lsoa_11_region.xlsx"
            DBMS=EXCEL REPLACE;
     RANGE="LSOA11_LA11_RGN11$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

/*deprivation and region data*/
/* From ONS */
PROC IMPORT OUT= dep_pop_tmp 
            DATAFILE= "~\512107 - Elective backlog an
d ethnicity\Data\ONS\deprivation\deprivation_pop_tidy.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="out$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
PROC IMPORT OUT= region_pop_tmp 
            DATAFILE= "~\512107 - Elective backlog an
d ethnicity\Data\ONS\region\region_pop_tidy.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="out$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

proc sql;
	create table proj.dep_pop as
	select imd_decile, sex, age_10, population, catx('', put(year, 4.), put(year-1999, 2.)) as period_year
	from dep_pop_tmp
;
quit;
proc sql;
	create table proj.region_pop as
	select gor_code, gor_name, sex, age_10, population, catx('', put(year, 4.), put(year-1999, 2.)) as period_year
	from region_pop_tmp
;
quit;

proc sql; 

	create table proj.ip_all_m11 as 
	select a.*, b.lad11cd, b.lad11nm, b.rgn11cd, b.rgn11nm
		, case 
				when rgn11cd = 'E09000001' or rgn11cd = 'E09000033' then 'E09000001+E09000033'
				when rgn11cd = 'E06000052' or rgn11cd = 'E06000053' then 'E06000052+E06000053'
				else rgn11cd
				end as lad_ethpop
	from proj.vw_all a
		left join proj.lsoa_region_lookup b
			on a.lsoa11 = b.lsoa11cd
	where proc_group ne 'none' and excludeproc = 0
;
	create table proj.ip_first_m11 as 
	select *
	from proj.ip_all_m11 
	where epiorder = 1
;
quit;


%macro totobs(data);
	%let dataid=%sysfunc(OPEN(&data.,IN));
	%let nobs=%sysfunc(ATTRN(&dataid,NOBS));
	%let RC=%sysfunc(CLOSE(&dataid));
	&nobs
%mend;

%put %totobs(proj.ip_all_m11); 

