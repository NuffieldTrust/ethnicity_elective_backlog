/* Run additional models by region or by deprivation */
libname proj "~\Ethnicity Elective Backlog\Sensitive\v8";
/*Models by region and deprivation*/
%macro region_models(proc_group);

proc sql;
	create table dt_reg_&proc_group. as
	select * from proj.region8 where proc_group = "&proc_group." 
	
;
quit;


/* Create the population data sets */

proc sql;
	create table pop_reg_&proc_group. as
	select period_year, age_10, gender, observed_all as observed, population_all as population, region
	from dt_reg_&proc_group.
;
quit;



proc sql;
	create table cr_reg_&proc_group. as 
	select region, period_year, sum(observed) as observed, sum(population) as population, sum(observed)/sum(population) * 100000 as reference_crude_rate
	from pop_reg_&proc_group.
	group by region, period_year
;
quit;


/*Sort data for standardisation*/
proc sort data = pop_reg_&proc_group. out = pop_reg_&proc_group.;
   by region;
run;


proc sort data = dt_reg_&proc_group. out = dt_reg_&proc_group.;
   by region period_year age_10 gender;
run;


/*Run the indirect standardisation*/
/*NB be careful that refdata totals refer to White group*/

proc stdrate data=dt_reg_&proc_group. refdata=pop_reg_&proc_group.
             method=indirect stat=rate(mult=100000) plots=none ; 
             population event=observed total=population; 
             reference event=observed total=population;
             strata age_10 gender period_year / stats smr;
			 by region period_year;
			 ods output smr=smr_reg_&proc_group.;
run;

proc sql;
	create table smr_reg_&proc_group. as
	select a.*, b.population
	from smr_reg_&proc_group. a
		left join (
			select sum(population) as population, region, period_year
			from pop_reg_&proc_group.
			group by region, period_year ) b on a.region = b.region and a.period_year = b.period_year
;
quit;

data smr_reg_&proc_group.;
  set smr_reg_&proc_group.;
	log_exp = log(expectedevents);
	log_pop = log(population / 100000);
  rename observedevents = observed;
run;


proc sql;
	create table rr1&proc_group. as
	select * 
	from smr_reg_&proc_group. 
	where period_year in ('201920', '202021')
	
;
	create table rr2&proc_group. as
	select * 
	from smr_reg_&proc_group. 
	where period_year in ('201920', '202122')
;
	create table rs1&proc_group. as
	select * 
	from dt_reg_&proc_group. 
	where period_year in ('201920', '202021')
	
;
	create table rs2&proc_group. as
	select * 
	from dt_reg_&proc_group. 
	where period_year in ('201920', '202122')
;

quit;


proc genmod data = rr1&proc_group.;
	class region (ref='East Midlands') period_year (ref='201920') / param=ref;
	model observed = region period_year region*period_year / dist=poisson link=log offset=log_exp;
	estimate 'E Mids 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 0;
	estimate 'East 2020/21 vs 2019/20'  period_year 1 region*period_year 1 0 0 0 0 0 0 0;
	estimate 'London 2020/21 vs 2019/20'  period_year 1 region*period_year 0 1 0 0 0 0 0 0;
	estimate 'N East 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 1 0 0 0 0 0;
	estimate 'N West 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 1 0 0 0 0;
	estimate 'S East 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 1 0 0 0;
	estimate 'S West 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 1 0 0;
	estimate 'W Mids 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 1 0;
	estimate 'Yorks 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = rr1p&proc_group.
		estimates          = rr1c&proc_group.;

run;

proc genmod data = rr2&proc_group.;
	class region (ref='East Midlands') period_year (ref='201920') / param=ref;
	model observed = region period_year region*period_year / dist=poisson link=log offset=log_exp;
	estimate 'E Mids 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 0;
	estimate 'East 2021/22 vs 2019/20'  period_year 1 region*period_year 1 0 0 0 0 0 0 0;
	estimate 'London 2021/22 vs 2019/20'  period_year 1 region*period_year 0 1 0 0 0 0 0 0;
	estimate 'N East 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 1 0 0 0 0 0;
	estimate 'N West 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 1 0 0 0 0;
	estimate 'S East 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 1 0 0 0;
	estimate 'S West 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 1 0 0;
	estimate 'W Mids 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 1 0;
	estimate 'Yorks 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = rr2p&proc_group.
		estimates          = rr2c&proc_group.;

run;

proc genmod data = rs1&proc_group.;
	class region (ref='East Midlands') period_year (ref='201920') age_10 (ref = '50to59') gender (ref = 'F')/ param=ref;
	model observed = region period_year region*period_year age_10 gender/ dist=poisson link=log offset=log_pop;
	estimate 'E Mids 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 0;
	estimate 'East 2020/21 vs 2019/20'  period_year 1 region*period_year 1 0 0 0 0 0 0 0;
	estimate 'London 2020/21 vs 2019/20'  period_year 1 region*period_year 0 1 0 0 0 0 0 0;
	estimate 'N East 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 1 0 0 0 0 0;
	estimate 'N West 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 1 0 0 0 0;
	estimate 'S East 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 1 0 0 0;
	estimate 'S West 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 1 0 0;
	estimate 'W Mids 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 1 0;
	estimate 'Yorks 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = rs1p&proc_group.
		estimates          = rs1c&proc_group.;

run;

proc genmod data = rs2&proc_group.;
	class region (ref='East Midlands') period_year (ref='201920') age_10 (ref = '50to59') gender (ref = 'F')/ param=ref;
	model observed = region period_year region*period_year age_10 gender/ dist=poisson link=log offset=log_pop;
	estimate 'E Mids 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 0;
	estimate 'East 2021/22 vs 2019/20'  period_year 1 region*period_year 1 0 0 0 0 0 0 0;
	estimate 'London 2021/22 vs 2019/20'  period_year 1 region*period_year 0 1 0 0 0 0 0 0;
	estimate 'N East 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 1 0 0 0 0 0;
	estimate 'N West 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 1 0 0 0 0;
	estimate 'S East 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 1 0 0 0;
	estimate 'S West 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 1 0 0;
	estimate 'W Mids 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 1 0;
	estimate 'Yorks 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = rs2p&proc_group.
		estimates          = rs2c&proc_group.;

run;

proc genmod data = rs1&proc_group.;
	class region (ref='East Midlands') period_year (ref='201920') / param=ref;
	model observed = region period_year region*period_year / dist=poisson link=log offset=log_pop;
	estimate 'E Mids 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 0;
	estimate 'East 2020/21 vs 2019/20'  period_year 1 region*period_year 1 0 0 0 0 0 0 0;
	estimate 'London 2020/21 vs 2019/20'  period_year 1 region*period_year 0 1 0 0 0 0 0 0;
	estimate 'N East 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 1 0 0 0 0 0;
	estimate 'N West 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 1 0 0 0 0;
	estimate 'S East 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 1 0 0 0;
	estimate 'S West 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 1 0 0;
	estimate 'W Mids 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 1 0;
	estimate 'Yorks 2020/21 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = rt1p&proc_group.
		estimates          = rt1c&proc_group.;

run;

proc genmod data = rs2&proc_group.;
	class region (ref='East Midlands') period_year (ref='201920') / param=ref;
	model observed = region period_year region*period_year / dist=poisson link=log offset=log_pop;
	estimate 'E Mids 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 0;
	estimate 'East 2021/22 vs 2019/20'  period_year 1 region*period_year 1 0 0 0 0 0 0 0;
	estimate 'London 2021/22 vs 2019/20'  period_year 1 region*period_year 0 1 0 0 0 0 0 0;
	estimate 'N East 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 1 0 0 0 0 0;
	estimate 'N West 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 1 0 0 0 0;
	estimate 'S East 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 1 0 0 0;
	estimate 'S West 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 1 0 0;
	estimate 'W Mids 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 1 0;
	estimate 'Yorks 2021/22 vs 2019/20'  period_year 1 region*period_year 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = rt2p&proc_group.
		estimates          = rt2c&proc_group.;

run;



data smr_reg_&proc_group.;
	set smr_reg_&proc_group.;
	proc_group = "&proc_group.";
run;

data rr1p&proc_group.;
	set rr1p&proc_group.;
	proc_group = "&proc_group.";
run;

data rr2p&proc_group.;
	set rr2p&proc_group.;
	proc_group = "&proc_group.";
run;

data rs1p&proc_group.;
	set rs1p&proc_group.;
	proc_group = "&proc_group.";
run;

data rs2p&proc_group.;
	set rs2p&proc_group.;
	proc_group = "&proc_group.";
run;

data rt1p&proc_group.;
	set rt1p&proc_group.;
	proc_group = "&proc_group.";
run;

data rt2p&proc_group.;
	set rt2p&proc_group.;
	proc_group = "&proc_group.";
run;


data rr1c&proc_group.;
	set rr1c&proc_group.;
	proc_group = "&proc_group.";
run;

data rr2c&proc_group.;
	set rr2c&proc_group.;
	proc_group = "&proc_group.";
run;

data rs1c&proc_group.;
	set rs1c&proc_group.;
	proc_group = "&proc_group.";
run;

data rs2c&proc_group.;
	set rs2c&proc_group.;
	proc_group = "&proc_group.";
run;

data rt1c&proc_group.;
	set rt1c&proc_group.;
	proc_group = "&proc_group.";
run;

data rt2c&proc_group.;
	set rt2c&proc_group.;
	proc_group = "&proc_group.";
run;

%mend;

%region_models(cardiac_diagnostic);
%region_models(cardiac_therapeutic);
%region_models(cataract);
%region_models(dental);
%region_models(gi_endoscopy_diagnostic);
%region_models(gi_endoscopy_therapeutic);
%region_models(hips_and_knees);
%region_models(other);
%region_models(All);

data proj.reg_models_ry1;
	length proc_group $24;
	set rr1ccardiac_diagnostic
		rr1ccardiac_therapeutic
		rr1ccataract
		rr1cdental
		rr1cgi_endoscopy_diagnostic
		rr1cgi_endoscopy_therapeutic
		rr1chips_and_knees
		rr1cother
		rr1call;
run;

data proj.reg_models_ry2;
	length proc_group $24;
	set rr2ccardiac_diagnostic
		rr2ccardiac_therapeutic
		rr2ccataract
		rr2cdental
		rr2cgi_endoscopy_diagnostic
		rr2cgi_endoscopy_therapeutic
		rr2chips_and_knees
		rr2cother
		rr2call;
run;

data proj.reg_models_sy1;
	length proc_group $24;
	set rs1ccardiac_diagnostic
		rs1ccardiac_therapeutic
		rs1ccataract
		rs1cdental
		rs1cgi_endoscopy_diagnostic
		rs1cgi_endoscopy_therapeutic
		rs1chips_and_knees
		rs1cother
		rs1call;
run;

data proj.reg_models_sy2;
	length proc_group $24;
	set rs2ccardiac_diagnostic
		rs2ccardiac_therapeutic
		rs2ccataract
		rs2cdental
		rs2cgi_endoscopy_diagnostic
		rs2cgi_endoscopy_therapeutic
		rs2chips_and_knees
		rs2cother
		rs2call;
run;

data proj.reg_models_ty1;
	length proc_group $24;
	set rt1ccardiac_diagnostic
		rt1ccardiac_therapeutic
		rt1ccataract
		rt1cdental
		rt1cgi_endoscopy_diagnostic
		rt1cgi_endoscopy_therapeutic
		rt1chips_and_knees
		rt1cother
		rt1call;
run;

data proj.reg_models_ty2;
	length proc_group $24;
	set rt2ccardiac_diagnostic
		rt2ccardiac_therapeutic
		rt2ccataract
		rt2cdental
		rt2cgi_endoscopy_diagnostic
		rt2cgi_endoscopy_therapeutic
		rt2chips_and_knees
		rt2cother
		rt2call;
run;


%macro deprivation_models(proc_group);

proc sql;
	create table dt_dep_&proc_group. as
	select * 
	from proj.deprivation8 
	where proc_group = "&proc_group." 
	
;
quit;


/* Create the population data sets */

proc sql;
	create table pop_dep_&proc_group. as
	select period_year, age_10, gender, observed_all as observed, population_all as population, imd_decile
	from dt_dep_&proc_group.
;
quit;



proc sql;
	create table cr_dep_&proc_group. as 
	select imd_decile, period_year, sum(observed) as observed, sum(population) as population, sum(observed)/sum(population) * 100000 as reference_crude_rate
	from pop_dep_&proc_group.
	group by imd_decile, period_year
;
quit;


/*Sort data for standardisation*/
proc sort data = pop_dep_&proc_group. out = pop_dep_&proc_group.;
   by imd_decile;
run;


proc sort data = dt_dep_&proc_group. out = dt_dep_&proc_group.;
   by imd_decile period_year age_10 gender;
run;


/*Run the indirect standardisation*/
/*NB be careful that refdata totals refer to All group*/

proc stdrate data=dt_dep_&proc_group. refdata=pop_dep_&proc_group.
             method=indirect stat=rate(mult=100000) plots=none ; 
             population event=observed total=population; 
             reference event=observed total=population;
             strata age_10 gender period_year / stats smr;
			 by imd_decile period_year;
			 ods output smr=smr_dep_&proc_group.;
run;

proc sql;
	create table smr_dep_&proc_group. as
	select a.*, b.population
	from smr_dep_&proc_group. a
		left join (
			select sum(population) as population, imd_decile, period_year
			from pop_dep_&proc_group.
			group by imd_decile, period_year ) b on a.imd_decile = b.imd_decile and a.period_year = b.period_year
;
quit;

data smr_dep_&proc_group.;
  set smr_dep_&proc_group.;
	log_exp = log(expectedevents);
	log_pop = log(population / 100000);
  rename observedevents = observed;
run;


proc sql;
	create table dr1&proc_group. as
	select * 
	from smr_dep_&proc_group. 
	where period_year in ('201920', '202021')
	
;
	create table dr2&proc_group. as
	select * 
	from smr_dep_&proc_group. 
	where period_year in ('201920', '202122')
;
	create table ds1&proc_group. as
	select * 
	from dt_dep_&proc_group. 
	where period_year in ('201920', '202021')
	
;
	create table ds2&proc_group. as
	select * 
	from dt_dep_&proc_group. 
	where period_year in ('201920', '202122')
;

quit;


proc genmod data = dr1&proc_group.;
	class imd_decile (ref='1') period_year (ref='201920') / param=ref;
	model observed = imd_decile period_year imd_decile*period_year / dist=poisson link=log offset=log_exp;
	estimate 'Decile 1 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 0;
	estimate 'Decile 2 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 1 0 0 0 0 0 0 0 0;
	estimate 'Decile 3 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 1 0 0 0 0 0 0 0;
	estimate 'Decile 4 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 1 0 0 0 0 0 0;
	estimate 'Decile 5 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 1 0 0 0 0 0;
	estimate 'Decile 6 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 1 0 0 0 0;
	estimate 'Decile 7 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 1 0 0 0;
	estimate 'Decile 8 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 1 0 0;
	estimate 'Decile 9 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 1 0;
	estimate 'Decile 10 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 1;
	
	ods output
		parameterestimates = dr1p&proc_group.
		estimates          = dr1c&proc_group.;

run;

proc genmod data = dr2&proc_group.;
	class imd_decile (ref='1') period_year (ref='201920') / param=ref;
	model observed = imd_decile period_year imd_decile*period_year / dist=poisson link=log offset=log_exp;
	estimate 'Decile 1 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 0;
	estimate 'Decile 2 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 1 0 0 0 0 0 0 0 0;
	estimate 'Decile 3 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 1 0 0 0 0 0 0 0;
	estimate 'Decile 4 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 1 0 0 0 0 0 0;
	estimate 'Decile 5 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 1 0 0 0 0 0;
	estimate 'Decile 6 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 1 0 0 0 0;
	estimate 'Decile 7 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 1 0 0 0;
	estimate 'Decile 8 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 1 0 0;
	estimate 'Decile 9 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 1 0;
	estimate 'Decile 10 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = dr2p&proc_group.
		estimates          = dr2c&proc_group.;

run;

proc genmod data = ds1&proc_group.;
	class imd_decile (ref='1') period_year (ref='201920') age_10 (ref = '50to59') gender (ref = 'F')/ param=ref;
	model observed = imd_decile period_year imd_decile*period_year age_10 gender/ dist=poisson link=log offset=log_pop;
	estimate 'Decile 1 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 0;
	estimate 'Decile 2 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 1 0 0 0 0 0 0 0 0;
	estimate 'Decile 3 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 1 0 0 0 0 0 0 0;
	estimate 'Decile 4 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 1 0 0 0 0 0 0;
	estimate 'Decile 5 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 1 0 0 0 0 0;
	estimate 'Decile 6 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 1 0 0 0 0;
	estimate 'Decile 7 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 1 0 0 0;
	estimate 'Decile 8 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 1 0 0;
	estimate 'Decile 9 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 1 0;
	estimate 'Decile 10 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = ds1p&proc_group.
		estimates          = ds1c&proc_group.;

run;

proc genmod data = ds2&proc_group.;
	class imd_decile (ref='1') period_year (ref='201920') age_10 (ref = '50to59') gender (ref = 'F')/ param=ref;
	model observed = imd_decile period_year imd_decile*period_year age_10 gender/ dist=poisson link=log offset=log_pop;
	estimate 'Decile 1 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 0;
	estimate 'Decile 2 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 1 0 0 0 0 0 0 0 0;
	estimate 'Decile 3 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 1 0 0 0 0 0 0 0;
	estimate 'Decile 4 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 1 0 0 0 0 0 0;
	estimate 'Decile 5 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 1 0 0 0 0 0;
	estimate 'Decile 6 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 1 0 0 0 0;
	estimate 'Decile 7 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 1 0 0 0;
	estimate 'Decile 8 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 1 0 0;
	estimate 'Decile 9 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 1 0;
	estimate 'Decile 10 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = ds2p&proc_group.
		estimates          = ds2c&proc_group.;

run;

proc genmod data = ds1&proc_group.;
	class imd_decile (ref='1') period_year (ref='201920') / param=ref;
	model observed = imd_decile period_year imd_decile*period_year / dist=poisson link=log offset=log_pop;
	estimate 'Decile 1 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 0;
	estimate 'Decile 2 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 1 0 0 0 0 0 0 0 0;
	estimate 'Decile 3 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 1 0 0 0 0 0 0 0;
	estimate 'Decile 4 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 1 0 0 0 0 0 0;
	estimate 'Decile 5 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 1 0 0 0 0 0;
	estimate 'Decile 6 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 1 0 0 0 0;
	estimate 'Decile 7 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 1 0 0 0;
	estimate 'Decile 8 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 1 0 0;
	estimate 'Decile 9 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 1 0;
	estimate 'Decile 10 - 2020/21 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = dt1p&proc_group.
		estimates          = dt1c&proc_group.;

run;

proc genmod data = ds2&proc_group.;
	class imd_decile (ref='1') period_year (ref='201920') / param=ref;
	model observed = imd_decile period_year imd_decile*period_year / dist=poisson link=log offset=log_pop;
	estimate 'Decile 1 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 0;
	estimate 'Decile 2 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 1 0 0 0 0 0 0 0 0;
	estimate 'Decile 3 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 1 0 0 0 0 0 0 0;
	estimate 'Decile 4 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 1 0 0 0 0 0 0;
	estimate 'Decile 5 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 1 0 0 0 0 0;
	estimate 'Decile 6 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 1 0 0 0 0;
	estimate 'Decile 7 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 1 0 0 0;
	estimate 'Decile 8 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 1 0 0;
	estimate 'Decile 9 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 1 0;
	estimate 'Decile 10 - 2021/22 vs 2019/20'  period_year 1 imd_decile*period_year 0 0 0 0 0 0 0 0 1;
	ods output
		parameterestimates = dt2p&proc_group.
		estimates          = dt2c&proc_group.;

run;



data smr_dep_&proc_group.;
	set smr_dep_&proc_group.;
	proc_group = "&proc_group.";
run;

data dr1p&proc_group.;
	set dr1p&proc_group.;
	proc_group = "&proc_group.";
run;

data dr2p&proc_group.;
	set dr2p&proc_group.;
	proc_group = "&proc_group.";
run;

data ds1p&proc_group.;
	set ds1p&proc_group.;
	proc_group = "&proc_group.";
run;

data ds2p&proc_group.;
	set ds2p&proc_group.;
	proc_group = "&proc_group.";
run;

data dt1p&proc_group.;
	set dt1p&proc_group.;
	proc_group = "&proc_group.";
run;

data dt2p&proc_group.;
	set dt2p&proc_group.;
	proc_group = "&proc_group.";
run;


data dr1c&proc_group.;
	set dr1c&proc_group.;
	proc_group = "&proc_group.";
run;

data dr2c&proc_group.;
	set dr2c&proc_group.;
	proc_group = "&proc_group.";
run;

data ds1c&proc_group.;
	set ds1c&proc_group.;
	proc_group = "&proc_group.";
run;

data ds2c&proc_group.;
	set ds2c&proc_group.;
	proc_group = "&proc_group.";
run;

data dt1c&proc_group.;
	set dt1c&proc_group.;
	proc_group = "&proc_group.";
run;

data rt2c&proc_group.;
	set rt2c&proc_group.;
	proc_group = "&proc_group.";
run;

%mend;

%deprivation_models(cardiac_diagnostic);
%deprivation_models(cardiac_therapeutic);
%deprivation_models(cataract);
%deprivation_models(dental);
%deprivation_models(gi_endoscopy_diagnostic);
%deprivation_models(gi_endoscopy_therapeutic);
%deprivation_models(hips_and_knees);
%deprivation_models(other);
%deprivation_models(All);

data proj.dep_models_ry1;
	length proc_group $24;
	set dr1ccardiac_diagnostic
		dr1ccardiac_therapeutic
		dr1ccataract
		dr1cdental
		dr1cgi_endoscopy_diagnostic
		dr1cgi_endoscopy_therapeutic
		dr1chips_and_knees
		dr1cother
		dr1call;
run;

data proj.dep_models_ry2;
	length proc_group $24;
	set dr2ccardiac_diagnostic
		dr2ccardiac_therapeutic
		dr2ccataract
		dr2cdental
		dr2cgi_endoscopy_diagnostic
		dr2cgi_endoscopy_therapeutic
		dr2chips_and_knees
		dr2cother
		dr2call;
run;

data proj.dep_models_sy1;
	length proc_group $24;
	set ds1ccardiac_diagnostic
		ds1ccardiac_therapeutic
		ds1ccataract
		ds1cdental
		ds1cgi_endoscopy_diagnostic
		ds1cgi_endoscopy_therapeutic
		ds1chips_and_knees
		ds1cother
		ds1call;
run;

data proj.dep_models_sy2;
	length proc_group $24;
	set ds2ccardiac_diagnostic
		ds2ccardiac_therapeutic
		ds2ccataract
		ds2cdental
		ds2cgi_endoscopy_diagnostic
		ds2cgi_endoscopy_therapeutic
		ds2chips_and_knees
		ds2cother
		ds2call;
run;

data proj.dep_models_ty1;
	length proc_group $24;
	set dt1ccardiac_diagnostic
		dt1ccardiac_therapeutic
		dt1ccataract
		dt1cdental
		dt1cgi_endoscopy_diagnostic
		dt1cgi_endoscopy_therapeutic
		dt1chips_and_knees
		dt1cother
		dt1call;
run;

data proj.dep_models_ty2;
	length proc_group $24;
	set dt2ccardiac_diagnostic
		dt2ccardiac_therapeutic
		dt2ccataract
		dt2cdental
		dt2cgi_endoscopy_diagnostic
		dt2cgi_endoscopy_therapeutic
		dt2chips_and_knees
		dt2cother
		dt2call;
run;

