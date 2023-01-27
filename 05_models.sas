/* Run ethnicity based models */
libname proj "~\Ethnicity Elective Backlog\Sensitive\v9";

/*Load data*/
  
  
%macro run_models(proc_group);


proc sql;
	create table data_&proc_group. as
	select * 
	from proj.broad_rates7 
	where proc_group = "&proc_group." 
		and ethpop_broad4 ne 'All'
;
quit;


proc sort data = data_&proc_group. out = data_&proc_group.;
	by ethpop_broad4;
run;

proc sql;
	create table popw&proc_group. as 
	select period_year, gender, age_10, observed, population
	from data_&proc_group.
	where ethpop_broad4 = 'White'
;
	create table pop_&proc_group. as 
	select period_year, ethpop_broad4, sum(population) as population
	from data_&proc_group.
	group by period_year, ethpop_broad4
;
quit;

data popr&proc_group.;
	set popw&proc_group.;
	length ethpop_broad4 $ 5;
	ethpop_broad4 = 'All'; output;
	ethpop_broad4 = 'White'; output;
	ethpop_broad4 = 'Asian'; output;
	ethpop_broad4 = 'Black'; output;
	ethpop_broad4 = 'Mixed'; output;
	ethpop_broad4 = 'Other'; output;
run;


proc sort data = popr&proc_group. out = popr&proc_group.;
	by ethpop_broad4;
run;


/*Run the indirect standardisation*/
  /*NB be careful that refdata totals refer to White group*/

proc stdrate data=data_&proc_group. refdata=popr&proc_group.
	method=indirect stat=rate(mult=100000) plots=none ; 
	population event=observed total=population; 
	reference event=observed total=population;
	strata age_10 gender period_year / stats smr;
	by ethpop_broad4 period_year;
	ods output smr=smr_&proc_group.;
run;
proc sql;
	create table smr_&proc_group. as
	select a.*, b.population
	from smr_&proc_group. a
		left join pop_&proc_group. b
			on a.ethpop_broad4 = b.ethpop_broad4 and a.period_year = b.period_year
;
quit;

data smr_&proc_group.;
	set smr_&proc_group.;
	log_exp = log(expectedevents);
	log_pop = log(population / 100000);
	rename observedevents = observed;
run;

proc sql;
	create table yr1&proc_group. as 
	select * 
	from smr_&proc_group.
	where period_year in ('201920', '202021')
;
	create table yr2&proc_group. as 
	select * 
  	from smr_&proc_group.
	where period_year in ('201920', '202122')
;
	create table ys1&proc_group. as 
	select * 
	from data_&proc_group.
	where period_year in ('201920', '202021')
;
	create table ys2&proc_group. as 
	select * 
	from data_&proc_group.
	where period_year in ('201920', '202122')
;
quit;


proc genmod data = yr1&proc_group.;
	class ethpop_broad4 (ref='White') period_year (ref='201920') / param=ref;
	model observed = ethpop_broad4 period_year ethpop_broad4*period_year / dist=poisson link=log offset=log_exp;
	estimate 'White 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 0;
	estimate 'Asian 202021 v 201920' period_year 1 ethpop_broad4*period_year 1 0 0 0;
	estimate 'Black 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 1 0 0;
	estimate 'Mixed 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 1 0;
	estimate 'Other 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 1;
	ods output
	parameterestimates = m21p&proc_group.
	estimates          = m21c&proc_group.;
run;

proc genmod data = yr2&proc_group.;
	class ethpop_broad4 (ref='White') period_year (ref='201920') / param=ref;
	model observed = ethpop_broad4 period_year ethpop_broad4*period_year / dist=poisson link=log offset=log_exp;
	estimate 'White 202122 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 0;
	estimate 'Asian 202122 v 201920' period_year 1 ethpop_broad4*period_year 1 0 0 0;
	estimate 'Black 202122 v 201920' period_year 1 ethpop_broad4*period_year 0 1 0 0;
	estimate 'Mixed 202122 v 201920' period_year 1 ethpop_broad4*period_year 0 0 1 0;
	estimate 'Other 202122 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 1;
	ods output
		parameterestimates = m22p&proc_group.
		estimates          = m22c&proc_group.;
run;


proc genmod data = ys1&proc_group.;
	class ethpop_broad4 (ref='White') period_year (ref='201920')  age_10 (ref = '50to59') gender (ref = 'F') / param=ref;
	model observed = ethpop_broad4 period_year ethpop_broad4*period_year age_10 gender / dist=poisson link=log offset=log_pop;
	estimate 'White 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 0;
	estimate 'Asian 202021 v 201920' period_year 1 ethpop_broad4*period_year 1 0 0 0;
	estimate 'Black 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 1 0 0;
	estimate 'Mixed 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 1 0;
	estimate 'Other 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 1;
	ods output
		parameterestimates = m31p&proc_group.
		estimates          = m31c&proc_group.;
run;

proc genmod data = ys2&proc_group.;
	class ethpop_broad4 (ref='White') period_year (ref='201920')  age_10 (ref = '50to59') gender (ref = 'F') / param=ref;
	model observed = ethpop_broad4 period_year ethpop_broad4*period_year age_10 gender / dist=poisson link=log offset=log_pop;
	estimate 'White 202122 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 0;
	estimate 'Asian 202122 v 201920' period_year 1 ethpop_broad4*period_year 1 0 0 0;
	estimate 'Black 202122 v 201920' period_year 1 ethpop_broad4*period_year 0 1 0 0;
	estimate 'Mixed 202122 v 201920' period_year 1 ethpop_broad4*period_year 0 0 1 0;
	estimate 'Other 202122 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 1;
	ods output
		parameterestimates = m32p&proc_group.
		estimates          = m32c&proc_group.;
run;



data smr_&proc_group.;
	set smr_&proc_group.;
	proc_group = "&proc_group.";
run;

data est21&proc_group.;
	set m21c&proc_group.;
	proc_group = "&proc_group.";
run;

data est22&proc_group.;
	set m22c&proc_group.;
	proc_group = "&proc_group.";
run;

data out21&proc_group.;
	set m21p&proc_group.;
	proc_group = "&proc_group.";
run;

data out22&proc_group.;
	set m22p&proc_group.;
	proc_group = "&proc_group.";
run;

data est31&proc_group.;
	set m31c&proc_group.;
	proc_group = "&proc_group.";
run;

data est32&proc_group.;
	set m32c&proc_group.;
	proc_group = "&proc_group.";
run;

data out31&proc_group.;
	set m31p&proc_group.;
	proc_group = "&proc_group.";
run;

data out32&proc_group.;
	set m32p&proc_group.;
	proc_group = "&proc_group.";
run;


%mend;


%run_models(cardiac_diagnostic);
%run_models(cardiac_therapeutic);
%run_models(cataract);
%run_models(dental);
%run_models(gi_endoscopy_diagnostic);
%run_models(gi_endoscopy_therapeutic);
%run_models(hips_and_knees);
%run_models(other);
%run_models(all);


/*Want the output for all of these models*/
  data proj.ethnos_models_out21;
	length lookup $100;
	length proc_group $24;
	set out21cardiac_diagnostic
	out21cardiac_therapeutic
	out21cataract
	out21dental
	out21gi_endoscopy_diagnostic
	out21gi_endoscopy_therapeutic
	out21hips_and_knees
	out21other
	out21all;
	lookup = catx('', proc_group, parameter, level1);
	value = exp(estimate);
run;

data proj.ethnos_models_out22;
	length lookup $100;
	length proc_group $24;
	set out22cardiac_diagnostic
	out22cardiac_therapeutic
	out22cataract
	out22dental
	out22gi_endoscopy_diagnostic
	out22gi_endoscopy_therapeutic
	out22hips_and_knees
	out22other
	out22all;
	lookup = catx('', proc_group, parameter, level1);
	value = exp(estimate);
run;

data proj.ethnos_models_out31;
	length lookup $100;
	length proc_group $24;
	set out31cardiac_diagnostic
		out31cardiac_therapeutic
		out31cataract
		out31dental
		out31gi_endoscopy_diagnostic
		out31gi_endoscopy_therapeutic
		out31hips_and_knees
		out31other
		out31all;
	lookup = catx('', proc_group, parameter, level1);
	value = exp(estimate);
run;

data proj.ethnos_models_out32;
	length lookup $100;
	length proc_group $24;
	set out32cardiac_diagnostic
		out32cardiac_therapeutic
		out32cataract
		out32dental
		out32gi_endoscopy_diagnostic
		out32gi_endoscopy_therapeutic
		out32hips_and_knees
		out32other
		out32all;
	lookup = catx('', proc_group, parameter, level1);
	value = exp(estimate);
run;

data proj.ethnos_est_out21;
	length proc_group $24;
	set est21cardiac_diagnostic
		est21cardiac_therapeutic
		est21cataract
		est21dental
		est21gi_endoscopy_diagnostic
		est21gi_endoscopy_therapeutic
		est21hips_and_knees
		est21other
		est21all;
run;

data proj.ethnos_est_out22;
length proc_group $24;
set est22cardiac_diagnostic
	est22cardiac_therapeutic
	est22cataract
	est22dental
	est22gi_endoscopy_diagnostic
	est22gi_endoscopy_therapeutic
	est22hips_and_knees
	est22other
	est22all;
run;

data proj.ethnos_est_out31;
length proc_group $24;
set est31cardiac_diagnostic
	est31cardiac_therapeutic
	est31cataract
	est31dental
	est31gi_endoscopy_diagnostic
	est31gi_endoscopy_therapeutic
	est31hips_and_knees
	est31other
	est31all;
run;

data proj.ethnos_est_out32;
length proc_group $24;
set est32cardiac_diagnostic
	est32cardiac_therapeutic
	est32cataract
	est32dental
	est32gi_endoscopy_diagnostic
	est32gi_endoscopy_therapeutic
	est32hips_and_knees
	est32other
	est32all;
run;


data proj.ethnos_rates_out;
length proc_group $24;
set smr_cardiac_diagnostic
	smr_cardiac_therapeutic
	smr_cataract
	smr_dental
	smr_gi_endoscopy_diagnostic
	smr_gi_endoscopy_therapeutic
	smr_hips_and_knees
	smr_other
	smr_all;
run;


PROC IMPORT OUT= proj.ethdeppcent 
            DATAFILE= "~\Ethnicity Elective Backlog\Sensitive\subanalysis_ethdep.xlsm" 
            DBMS=EXCEL REPLACE;
     RANGE="ethdeppcent$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;




proc sql;
	create table ethnos_smr1 as 
	select a.*
  		, b.population
		, (a.observed / b.population) * 100000 as crude_rate

	from proj.ethnos_rates_out a
		left join proj.ethdeppop_total b
			on a.ethpop_broad4 = b.ethpop_broad and 
				a.imd_quintile = b.imd_quintile and
				a.period_year = b.period_year
	order by 
		proc_group, period_year, ethpop_broad4, 
;
	create table ethnos_smr2 as 
	select proc_group, period_year, ethpop_broad4, crude_rate as white_crude_rate
	from ethnos_smr1
	where ethpop_broad4 = 'White'
	order by 
		proc_group, period_year, ethpop_broad4
;
	create table proj.ethnos_smr as 
	select 
		  a.*
		, smr * b.white_crude_rate as isr 
		, smrlcl * b.white_crude_rate as isrlcl
		, smrucl * b.white_crude_rate as isrucl
		, case when a.ethpop_broad4 = 'White' then 1
			when a.ethpop_broad4 = 'Mixed' then 2
			when a.ethpop_broad4 = 'Asian' then 3
			when a.ethpop_broad4 = 'Black' then 4
			when a.ethpop_broad4 = 'Other' then 5
			end as ethpop_order

	from ethnos_smr1 a
		left join ethnos_smr2 b
			on a.proc_group = b.proc_group and 
				a.period_year = b.period_year
	order by 
		a.proc_group, a.period_year, a.ethpop_broad4
;
quit; 
  
  
  
