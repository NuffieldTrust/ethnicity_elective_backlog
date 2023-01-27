/* PRODUCE STANDARDISED RATES  */
data year;
	input period_year $;
	datalines;
201718
201819
201920
202021
202122
;


data sex;
input sex_clean $;
datalines;
F
M
;


data age;
input age_10 $;
datalines;
00to09
10to19
20to29
30to39
40to49
50to59
60to69
70to79
80to89
90plus
;

data ethpop;
input ethpop_broad4 $;
datalines;
White
Mixed
Asian
Black
Other
;

data proc_group;
input proc_group $24.;
datalines;
cardiac_diagnostic
cardiac_therapeutic
cataract
dental
gi_endoscopy_diagnostic
gi_endoscopy_therapeutic
hips_and_knees
other
;

data deprivation;
input imd_decile 12.;
datalines;
1
2
3
4
5
6
7
8
9
10
;

data region;
infile datalines dlm=',';
input rgn11cd $9. rgn11nm $25.;
datalines;
E12000001,North East
E12000002,North West
E12000003,Yorkshire and The Humber
E12000004,East Midlands
E12000005,West Midlands 
E12000006,East of England
E12000007,London
E12000008,South East
E12000009,South West
;
data region;
	set region;
	rgn11nm = substr(rgn11nm, 2);
run;

proc sql;
	create table proj.groups as 
	select year.*, sex.*, age.*, ethpop.*, proc_group.*
	from year, sex, age, ethpop, proc_group
;
quit;

proc sql;
	create table proj.groups_all as 
	select year.*, sex.*, age.*, ethpop.*
	from year, sex, age, ethpop
;
quit;

proc sql;
	create table proj.groups_dep as 
	select year.*, sex.*, age.*, deprivation.*, proc_group.*
	from year, sex, age, deprivation, proc_group
;
quit;

proc sql;
	create table proj.groups_dep_all as 
	select year.*, sex.*, age.*, deprivation.*
	from year, sex, age, deprivation
;
quit;

proc sql;
	create table proj.groups_reg as 
	select year.*, sex.*, age.*, region.*, proc_group.*
	from year, sex, age, region, proc_group

;
quit;

proc sql;
	create table proj.groups_reg_all as 
	select year.*, sex.*, age.*, region.*
	from year, sex, age, region

;
quit;


proc sql;
	create table proj.dep_eng_pop_tot as
	select imd_decile, period_year, sum(population) as population
	from proj.dep_pop
	group by imd_decile, period_year
	order by period_year, imd_decile
;

quit;

proc sql;
	create table proj.reg_eng_pop as
	select *
	from proj.region_pop
	where gor_code like 'E%'
;
	create table proj.reg_eng_pop_tot as
	select gor_name, period_year, sum(population) as population
	from proj.reg_eng_pop
	group by gor_name, period_year
	order by period_year, gor_name
;

quit;



proc sql;
	create table proj.broad_rates1 as 
	select count(*) as episodes, period_year, sex_clean, age_10
		, ethpop_broad4
		, proc_group
	from proj.ip_m11_re 
	where period_year in ('201718', '201819', '201920', '202021', '202122') and 
		lsoa11 like 'E%' and 
		sex_clean in ('F', 'M') and 
		age_10 in ('00to09', '10to19', '20to29', '30to39', '40to49', '50to59', '60to69', '70to79', '80to89', '90plus')

	group by
			period_year, sex_clean, age_10, ethpop_broad4, proc_group
;
quit;


proc sql;
	create table proj.broad_rates2 as 
	select 
		coalesce(b.episodes, 0) as episodes
		, a.period_year
		, a.sex_clean
		, a.age_10
		, a.ethpop_broad4
		, a.proc_group
		, c.population
	from proj.groups a
		left join proj.broad_rates1 b on 
			a.period_year = b.period_year and
			a.sex_clean = b.sex_clean and
			a.age_10 = b.age_10 and
			a.ethpop_broad4 = b.ethpop_broad4 and
			a.proc_group = b.proc_group
		left join proj.ethpop_combined c on 
			a.period_year = c.period_year and
			a.sex_clean = c.gender and
			a.age_10 = c.age_10 and
			a.ethpop_broad4 = c.ethpop_broad
;
quit;


proc sql;
	create table proj.broad_rates3 as 
	select count(*) as episodes, period_year, sex_clean, age_10
		, ethpop_broad4
		, 'all' as proc_group
	from proj.ip_m11_re 
	where period_year in ('201718', '201819', '201920', '202021', '202122') and 
		lsoa11 like 'E%' and 
		sex_clean in ('F', 'M') and 
		age_10 in ('00to09', '10to19', '20to29', '30to39', '40to49', '50to59', '60to69', '70to79', '80to89', '90plus')

	group by
			period_year, sex_clean, age_10, ethpop_broad4
;
quit;


proc sql;
create table proj.broad_rates4 as 
	select 
		coalesce(b.episodes, 0) as episodes
		, a.period_year
		, a.sex_clean
		, a.age_10
		, a.ethpop_broad4
		, b.proc_group
		, c.population
	from proj.groups_all a
		left join proj.broad_rates3 b on 
			a.period_year = b.period_year and
			a.sex_clean = b.sex_clean and
			a.age_10 = b.age_10 and
			a.ethpop_broad4 = b.ethpop_broad4
		left join proj.ethpop_combined c on 
			a.period_year = c.period_year and
			a.sex_clean = c.gender and
			a.age_10 = c.age_10 and
			a.ethpop_broad4 = c.ethpop_broad
;
quit;

proc sql;
create table proj.broad_rates5 as
	select * from proj.broad_rates2 union all
	select * from proj.broad_rates4 
;
quit;


proc sql;
	create table proj.dep_pop2 as
	select *
	from proj.dep_pop
	union all
	select imd_decile, sex, age_10, population, '202122' as period_year
	from proj.dep_pop
	where period_year = '202021'
;
quit;

proc sql;
	create table proj.region_pop2 as 
	select *
	from proj.region_pop
	union all
	select gor_code, gor_name, sex, age_10, population, '202122' as period_year
	from proj.region_pop
	where period_year = '202021'
;
quit;


proc sql;
	create table proj.deprivation1 as
	select count(*) as episodes, period_year, sex_clean, age_10
		, imd_decile
		, proc_group
	from proj.ip_m11_re 
	where period_year in ('201718', '201819', '201920', '202021', '202122') and 
		lsoa11 like 'E%' and 
		sex_clean in ('F', 'M') and 
		age_10 in ('00to09', '10to19', '20to29', '30to39', '40to49', '50to59', '60to69', '70to79', '80to89', '90plus')

	group by
			period_year, sex_clean, age_10, imd_decile, proc_group
;
quit;

proc sql;
	create table proj.deprivation2 as 
	select 
		coalesce(b.episodes, 0) as episodes
		, a.period_year
		, a.sex_clean
		, a.age_10
		, a.imd_decile
		, a.proc_group
		, c.population
	from proj.groups_dep a
		left join proj.deprivation1 b on 
			a.period_year = b.period_year and
			a.sex_clean = b.sex_clean and
			a.age_10 = b.age_10 and
			a.imd_decile = b.imd_decile and
			a.proc_group = b.proc_group
		left join proj.dep_pop2 c on 
			a.period_year = c.period_year and
			a.sex_clean = c.sex and
			a.age_10 = c.age_10 and
			a.imd_decile = c.imd_decile
;
quit;

proc sql;
	create table proj.deprivation3 as
	select count(*) as episodes, period_year, sex_clean, age_10
		, imd_decile
		, 'All' as proc_group
	from proj.ip_m11_re 
	where period_year in ('201718', '201819', '201920', '202021', '202122') and 
		lsoa11 like 'E%' and 
		sex_clean in ('F', 'M') and 
		age_10 in ('00to09', '10to19', '20to29', '30to39', '40to49', '50to59', '60to69', '70to79', '80to89', '90plus')

	group by
			period_year, sex_clean, age_10, imd_decile
;
quit;
proc sql;
create table proj.deprivation4 as 
	select 
		coalesce(b.episodes, 0) as episodes
		, a.period_year
		, a.sex_clean
		, a.age_10
		, a.imd_decile
		, b.proc_group
		, c.population
	from proj.groups_dep_all a
		left join proj.deprivation3 b on 
			a.period_year = b.period_year and
			a.sex_clean = b.sex_clean and
			a.age_10 = b.age_10 and
			a.imd_decile = b.imd_decile
		left join proj.dep_pop2 c on 
			a.period_year = c.period_year and
			a.sex_clean = c.sex and
			a.age_10 = c.age_10 and
			a.imd_decile = c.imd_decile
;
quit;

proc sql;
	create table proj.deprivation5 as
	select * from proj.deprivation2 union all
	select * from proj.deprivation4 
;
quit;


proc sql;
	create table proj.region1 as
	select count(*) as episodes, period_year, sex_clean, age_10
		, rgn11cd, rgn11nm
		, proc_group
	from proj.ip_m11_re 
	where period_year in ('201718', '201819', '201920', '202021', '202122') and 
		lsoa11 like 'E%' and 
		sex_clean in ('F', 'M') and 
		age_10 in ('00to09', '10to19', '20to29', '30to39', '40to49', '50to59', '60to69', '70to79', '80to89', '90plus')

	group by
			period_year, sex_clean, age_10, rgn11cd, rgn11nm, proc_group
;
quit;


proc sql;
	create table proj.region2 as 
	select 
		coalesce(b.episodes, 0) as episodes
		, a.period_year
		, a.sex_clean
		, a.age_10
		, a.rgn11nm as region
		, a.proc_group
		, c.population
	from proj.groups_reg a
		left join proj.region1 b on 
			a.period_year = b.period_year and
			a.sex_clean = b.sex_clean and
			a.age_10 = b.age_10 and
			a.rgn11cd = b.rgn11cd and
			a.proc_group = b.proc_group
		left join proj.region_pop2 c on 
			a.period_year = c.period_year and
			a.sex_clean = c.sex and
			a.age_10 = c.age_10 and
			a.rgn11cd = c.gor_code
;

quit;



proc sql;
	create table proj.region3 as
	select count(*) as episodes, period_year, sex_clean, age_10
		, rgn11cd, rgn11nm
		, 'All' as proc_group
	from proj.ip_m11_re 
	where period_year in ('201718', '201819', '201920', '202021', '202122') and 
		lsoa11 like 'E%' and 
		sex_clean in ('F', 'M') and 
		age_10 in ('00to09', '10to19', '20to29', '30to39', '40to49', '50to59', '60to69', '70to79', '80to89', '90plus')

	group by
			period_year, sex_clean, age_10, rgn11cd, rgn11nm
;
quit;

proc sql;
	create table proj.region4 as 
	select 
		coalesce(b.episodes, 0) as episodes
		, a.period_year
		, a.sex_clean
		, a.age_10
		, a.rgn11nm as region
		, b.proc_group
		, c.population
	from proj.groups_reg_all a
		left join proj.region3 b on 
			a.period_year = b.period_year and
			a.sex_clean = b.sex_clean and
			a.age_10 = b.age_10 and
			a.rgn11cd = b.rgn11cd
		left join proj.region_pop2 c on 
			a.period_year = c.period_year and
			a.sex_clean = c.sex and
			a.age_10 = c.age_10 and
			a.rgn11cd = c.gor_code
;

quit;


proc sql;
	create table proj.region5 as
	select * from proj.region2 union all
	select * from proj.region4 
;
quit;


proc sql;
	create table ethnicity_test as 
	select 'ethnicity1' as table, sum(episodes) as episodes
	from proj.broad_rates1
	union all
	select 'ethnicity2' as table, sum(episodes) as episodes
	from proj.broad_rates2
	union all
	select 'ethnicity3' as table, sum(episodes) as episodes
	from proj.broad_rates3
	union all
	select 'ethnicity4' as table, sum(episodes) as episodes
	from proj.broad_rates4
	union all
	select 'ethnicity5' as table, sum(episodes) as episodes
	from proj.broad_rates5
;
	create table deprivation_test as 
	select 'deprivation1' as table, sum(episodes) as episodes
	from proj.deprivation1
	union all
	select 'deprivation2' as table, sum(episodes) as episodes
	from proj.deprivation2
	union all
	select 'deprivation3' as table, sum(episodes) as episodes
	from proj.deprivation3
	union all
	select 'deprivation4' as table, sum(episodes) as episodes
	from proj.deprivation4
	union all
	select 'deprivation5' as table, sum(episodes) as episodes
	from proj.deprivation5
;
	create table region_test as 
	select 'region1' as table, sum(episodes) as episodes
	from proj.region1
	union all
	select 'region2' as table, sum(episodes) as episodes
	from proj.region2
	union all
	select 'region3' as table, sum(episodes) as episodes
	from proj.region3
	union all
	select 'region4' as table, sum(episodes) as episodes
	from proj.region4
	union all
	select 'region5' as table, sum(episodes) as episodes
	from proj.region5
;
quit;

/*Create the crude rates*/
proc sql;
	create table proj.broad_rates6 as 
	select episodes
		, period_year
		, sex_clean
		, age_10
		, ethpop_broad4
		, proc_group
		, population
		, episodes/population as rate
	from proj.broad_rates5
;
quit;

proc sql;
	create table proj.broad_rates7 as 
	select
		catx('', a.proc_group, a.period_year, a.sex_clean, a.age_10, a.ethpop_broad4) as lookup 
		, a.proc_group
		, a.period_year
		, a.sex_clean as gender
		, a.age_10
		, a.ethpop_broad4
		, a.episodes as observed
		, a.population
		, a.rate
		, b.rate as reference_rate_white
		, b.rate * a.population as expected_white
		, log(b.rate * a.population) as log_exp
		, log(a.population/100000) as log_pop

	from proj.broad_rates6 a
		left join (select * from proj.broad_rates6 where ethpop_broad4 = 'White') b on
			a.period_year = b.period_year and
			a.sex_clean = b.sex_clean and
			a.age_10 = b.age_10 and
			a.proc_group = b.proc_group
	order by proc_group, ethpop_broad4, period_year, gender, age_10
;
quit;


proc sql;
	create table proj.region6 as 
	select episodes
		, period_year
		, sex_clean
		, age_10
		, region
		, proc_group
		, population
		, episodes/population as rate
	from proj.region5
;
	create table proj.region7 as
	select sum(episodes) as episodes
				, period_year
				, sex_clean
				, age_10
				, proc_group
				, sum(population) as population
	from proj.region6
	group by 
				period_year
				, sex_clean
				, age_10
				, proc_group
	;
	create table proj.region8 as 
	select
		catx('', a.proc_group, a.period_year, a.sex_clean, a.age_10, a.region) as lookup  
		, a.proc_group
		, a.period_year
		, a.sex_clean as gender
		, a.age_10
		, a.region	
		, a.episodes as observed
		, a.population
		, a.rate
		, b.episodes as observed_all
		, b.population as population_all
		, b.rate as reference_rate_all
		, b.rate * a.population as expected_all
		, log(b.rate * a.population) as log_exp
		, log(a.population/100000) as log_pop
		

	from proj.region6 a
		left join (
			select *, episodes/population as rate from proj.region7
			) b on
			a.period_year = b.period_year and
			a.sex_clean = b.sex_clean and
			a.age_10 = b.age_10 and
			a.proc_group = b.proc_group
;
quit;


proc sql;
	create table proj.deprivation6 as 
	select episodes
		, period_year
		, sex_clean
		, age_10
		, imd_decile
		, proc_group
		, population
		, episodes/population as rate
	from proj.deprivation5
;
	create table proj.deprivation7 as
	select sum(episodes) as episodes
				, period_year
				, sex_clean
				, age_10
				, proc_group
				, sum(population) as population
	from proj.deprivation6
	group by 
				period_year
				, sex_clean
				, age_10
				, proc_group
	;
	create table proj.deprivation8 as 
	select
		catx('', a.proc_group, a.period_year, a.sex_clean, a.age_10, a.imd_decile) as lookup  
		, a.proc_group
		, a.period_year
		, a.sex_clean as gender
		, a.age_10
		, a.imd_decile	
		, a.episodes as observed
		, a.population
		, a.rate
		, b.episodes as observed_all
		, b.population as population_all
		, b.rate as reference_rate_all
		, b.rate * a.population as expected_all
		, log(b.rate * a.population) as log_exp
		, log(a.population / 100000) as log_pop

	from proj.deprivation6 a
		left join (
			select *, episodes/population as rate from proj.deprivation7
			) b on
			a.period_year = b.period_year and
			a.sex_clean = b.sex_clean and
			a.age_10 = b.age_10 and
			a.proc_group = b.proc_group
;
quit;
