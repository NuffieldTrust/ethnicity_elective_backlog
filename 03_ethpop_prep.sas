/* Prepare ETHPOP data */
/* N.B. here we use the untranspose macro available at https://github.com/gerhard1050/Untranspose-a-Wide-File/ */
%include "~\Ethnicity Elective Backlog\Code\sas\v9\untranspose.sas";


proc sql;
	create table proj.region_lookup as
	select distinct 
		case when lad11cd in ('E06000052', 'E06000053') then 'E06000052+E06000053'
			when lad11cd in ('E09000001', 'E09000033') then 'E09000001+E09000033'
			else lad11cd end as lad11cd

		, case when lad11nm = 'Cornwall' then 'Cornwall+Isles of Scilly'
				when lad11nm = 'Westminster' then 'City of London+Westminster'
				else lad11nm end as lad11nm
		, rgn11cd, rgn11nm

	from proj.ip_m11_re
	where 
		lad11cd ne 'E06000053' and lad11cd ne 'E09000001' /* excluding duplicates after relabelling*/
;
quit;






%macro import_raw_ethpop(year, out);

%let prefix = ~\Ethnicity Elective Backlog\Aggregated\ethpop\Population;

%let datafile = &prefix&year._LEEDS2.csv;

PROC IMPORT OUT= &out
            DATAFILE= "&datafile"
            DBMS=CSV REPLACE;
     	GETNAMES=YES;
		DATAROW=2;
RUN;


%mend import_raw_ethpop;



%macro munge_ethpop(year);

	%let in = ethpopraw&year.;
	%let tmp = ethpoop&year.;
	%let out1 = ethpop&year.;
	%let out2 = ethpopten&year.;
	%untranspose(data=&in.
		, out=&tmp.
		, by = var1 lad_name lad_code eth_group
		, id = age
		, var = M F
		, makelong = YES);


	proc sql;
		create table &out1. as 
		select 
			lad_code as lad11cd
			, lad_name as lad11nm
			, b.rgn11cd
			, b.rgn11nm
			, eth_group as ethpop
			, case 
				when eth_group = 'WBI' then 'White'
				when eth_group = 'WHO' then 'White'
				when eth_group = 'MIX' then 'Mixed'
				when eth_group = 'IND' then 'Asian'
				when eth_group = 'PAK' then 'Asian'
				when eth_group = 'BAN' then 'Asian'
				when eth_group = 'OAS' then 'Asian'
				when eth_group = 'BLC' then 'Black'
				when eth_group = 'BLA' then 'Black'
				when eth_group = 'OBL' then 'Black'
				when eth_group = 'CHI' then 'Asian'
				when eth_group = 'OTH' then 'Other'
				end as ethpop_broad
			, _name_ as gender
			, case when age = . then 100 else age end as age
			, case 
				when age ge  0 and age le  9 then '00to09'
				when age ge 10 and age le 19 then '10to19'
				when age ge 20 and age le 29 then '20to29'
				when age ge 30 and age le 39 then '30to39'
				when age ge 40 and age le 49 then '40to49'
				when age ge 50 and age le 59 then '50to59'
				when age ge 60 and age le 69 then '60to69'
				when age ge 70 and age le 79 then '70to79'
				when age ge 80 and age le 89 then '80to89'
				when age ge 90 and age le 100 then '90plus'
				when age = . then '90plus'
				else 'unknown'
				end as age_10
			, &year. as year
			, _value_ as population
		from &tmp. a
			left join proj.region_lookup b
				on a.lad_code = b.lad11cd
			
		order by 
			lad11cd
			, eth_group
			, gender
			, age
	;
		create table &out2. as 
		select 
			rgn11cd
			, rgn11nm
			, ethpop_broad
			, gender
			, age_10
			, year
			, sum(population) as population

		from &out1.
		where rgn11cd like 'E%'
		group by
			rgn11cd
			, rgn11nm
			, ethpop_broad
			, gender
			, age_10
			, year

		order by 
			rgn11cd
			, ethpop_broad
			, gender
			, age_10
	;
	quit;
%mend munge_ethpop;


%import_raw_ethpop(2015, ethpopraw2015);
%import_raw_ethpop(2016, ethpopraw2016);
%import_raw_ethpop(2017, ethpopraw2017);
%import_raw_ethpop(2018, ethpopraw2018);
%import_raw_ethpop(2019, ethpopraw2019);
%import_raw_ethpop(2020, ethpopraw2020);
%import_raw_ethpop(2021, ethpopraw2021);

%munge_ethpop(2015);
%munge_ethpop(2016);
%munge_ethpop(2017);
%munge_ethpop(2018);
%munge_ethpop(2019);
%munge_ethpop(2020);
%munge_ethpop(2021);

data proj.ethpop_region_broad;
	set ethpopten2015
		ethpopten2016
		ethpopten2017
		ethpopten2018
		ethpopten2019
		ethpopten2020
		ethpopten2021;
run;

proc sql;
	create table proj.ethpop_combined as 
	select ethpop_broad, gender, age_10, put((year*100)+(year-1999), 6.) as period_year, sum(population) as population
	from proj.ethpop_region_broad
	group by ethpop_broad, gender, age_10, period_year
;
quit;

proc sql;
	create table proj.ethpop_total as 
	select ethpop_broad, period_year, sum(population) as population
	from proj.ethpop_combined
	group by ethpop_broad, period_year
;
quit;