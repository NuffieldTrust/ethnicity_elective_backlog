/* Subanalysis model code */
/* Note that some data prep was done in Excel */

libname proj "~\Ethnicity Elective Backlog\Sensitive\v9";



/*create data to calculate rates in excel*/
proc sql;
	create view proj.vw_subanalysis as
	select *, case when proc_group like 'cardiac%' then 'cardiac' else proc_group end as proc_group2 
	from proj.ip_m11_re 
	where period_year in ('201718', '201819', '201920', '202021', '202122') and 
		lsoa11 like 'E%' and 
		sex_clean in ('F', 'M') and 
		age_10 in ('00to09', '10to19', '20to29', '30to39', '40to49', '50to59', '60to69', '70to79', '80to89', '90plus')
;
	create table proj.subanalysis2 as 
	select
		count(*) as episodes
		, period_year
		, age_10
		, sex_clean
		, imd_decile
		, rgn11nm
		, ethpop_broad4
		, proc_group2

	from proj.vw_subanalysis
	group by
		period_year
		, age_10
		, sex_clean
		, imd_decile
		, rgn11nm
		, ethpop_broad4
		, proc_group2
;
	create table proj.subanalysis3 as 
	select * from proj.subanalysis2 union all
	select 
		sum(episodes) as episodes
		, period_year
		, age_10
		, sex_clean
		, imd_decile
		, rgn11nm
		, ethpop_broad4
		, 'All' as proc_group2

	from proj.subanalysis2
	group by
		  period_year
		, age_10
		, sex_clean
		, imd_decile
		, rgn11nm
		, ethpop_broad4

;
quit;



/*proc sql;*/
/*	create table proj.subanalysis1 as*/
/*	select *, case when proc_group like 'cardiac%' then 'cardiac' else proc_group end as proc_group2 */
/*	from proj.ip_m11_re */
/*	where period_year in ('201920', '202021') and */
/*		lsoa11 like 'E%' and */
/*		sex_clean in ('F', 'M') and */
/*		age_10 in ('00to09', '10to19', '20to29', '30to39', '40to49', '50to59', '60to69', '70to79', '80to89', '90plus')*/
/*;*/
/*quit;*/

proc sql;
	create table proj.subanalysis2 as 
	select
		count(*) as episodes
		, period_year
		, age_10
		, sex_clean
		, imd_decile
		, rgn11nm
		, ethpop_broad4
		, proc_group2

from proj.subanalysis1
group by
	period_year
		, age_10
		, sex_clean
		, imd_decile
		, rgn11nm
		, ethpop_broad4
		, proc_group2
;
quit;

proc sql;
	create table proj.subanalysis3 as 
	select * from proj.subanalysis2 union all
	select 
		count(*) as episodes
		, period_year
		, age_10
		, sex_clean
		, imd_decile
		, rgn11nm
		, ethpop_broad4
		, 'All' as proc_group2

	from proj.subanalysis1
	group by
		  period_year
		, age_10
		, sex_clean
		, imd_decile
		, rgn11nm
		, ethpop_broad4

;
quit;



/*Load data*/
PROC IMPORT OUT= eth_reg_cat
            DATAFILE= "~\Ethnicity Elective Backlog\Sensitive\subanalysis_v2.xlsm"
            DBMS=EXCEL REPLACE;
     RANGE="ethnos_region_working$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

data eth_reg_cat;
	set eth_reg_cat;
	log_exp = log(expected_all);
	log_pop = log(population/100000); * scale to rate per 100,000;
run;



/*Gender*/

/*create / load gender data*/
/*create rates*/
/*run models*/

PROC IMPORT OUT= eth_gender
            DATAFILE= "~\Ethnicity Elective Backlog\Sensitive\subanalysis_v3.xlsm"
            DBMS=EXCEL REPLACE;
     RANGE="gender_working$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

data eth_gender;
	set eth_gender;
	log_exp = log(expected_all);
	log_pop = log(population/100000); * scale to rate per 100,000;
run;





%macro run_gender_models(proc_group, gender);


proc sql;
	create table d_&gender.&proc_group. as
	select * 
	from eth_gender 
	where 
		proc_group = "&proc_group." and 
		gender = "&gender." and 
		ethpop_broad4 ne 'All'
;
quit;


/* Create the population specific data sets */


/*Continue*/

proc means data = d_&gender.&proc_group.(where = (ethpop_broad4 = 'White')) noprint nway;
   class period_year age_10;
   var observed population;
   output out = po_&gender.&proc_group. (drop = _type_ _freq_) sum= observed population;
run;

data po_&gender.&proc_group.;
   set po_&gender.&proc_group.;
   length ethpop_broad4 $ 5;
   ethpop_broad4 = 'All'; output;
   ethpop_broad4 = 'White'; output;
   ethpop_broad4 = 'Asian'; output;
   ethpop_broad4 = 'Black'; output;
   ethpop_broad4 = 'Mixed'; output;
   ethpop_broad4 = 'Other'; output;
run;


proc sort data = po_&gender.&proc_group. out = po_&gender.&proc_group.;
   by ethpop_broad4;
run;


proc sort data = d_&gender.&proc_group. out = d_&gender.&proc_group.;
   by ethpop_broad4 period_year age_10;
run;


proc sort data = d_&gender.&proc_group. out = d_&gender.&proc_group.;
   by ethpop_broad4 ;
run;

/*Run the indirect standardisation*/
/*NB be careful that refdata totals refer to White group*/

proc stdrate data=d_&gender.&proc_group. refdata=po_&gender.&proc_group.
             method=indirect stat=rate(mult=100000) plots=none ; 
             population event=observed total=population; 
             reference event=observed total=population;
             strata age_10 period_year / stats smr;
			 by ethpop_broad4 period_year;
			 ods output smr=smr_&gender.&proc_group.;
run;


data smr_&gender.&proc_group.;
  set smr_&gender.&proc_group.;
  log_exp = log(expectedevents);
  log_pop = log(population / 100000);
  rename observedevents = observed;
run;

/*Model 2 - using outputs from standardisation - SMR data*/
proc genmod data = smr_&gender.&proc_group.;
   class ethpop_broad4 (ref='White') period_year (ref='201920') / param=ref;
   model observed = ethpop_broad4 period_year ethpop_broad4*period_year / dist=poisson link=log offset=log_exp;
   	estimate 'White 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 0;
	estimate 'Asian 202021 v 201920' period_year 1 ethpop_broad4*period_year 1 0 0 0;
	estimate 'Black 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 1 0 0;
	estimate 'Mixed 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 1 0;
	estimate 'Other 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 1;
   ods output 
		parameterestimates = m2p_&gender.&proc_group.
		estimates          = m2c_&gender.&proc_group.;
run;


data out_&gender.&proc_group.;
	length proc_group $50;
	length gender $2;
	set m2p_&gender.&proc_group.;
	proc_group = "&proc_group.";
	region = "&gender.";
run;

data est_&gender.&proc_group.;
	length proc_group $50;
	length region $2;
	set m2c_&gender.&proc_group.;
	proc_group = "&proc_group.";
	gender = "&gender.";
run;



%mend;


%run_gender_models(cardiac, F);
%run_gender_models(cardiac, M);

%run_gender_models(cataract, F);
%run_gender_models(cataract, M);

%run_gender_models(All, F);
%run_gender_models(All, M);


data proj.ethgender_models_out;
	length lookup $100;
	length proc_group $24;
	length gender $2;
	set out_Fcardiac
		out_Mcardiac
		out_Fcataract
		out_Mcataract
		out_FAll
		out_MAll;
	lookup = catx('', proc_group, gender, parameter, level1);
	value = exp(estimate);
	run;

data proj.ethgender_models_est;
	length lookup $100;
	length proc_group $24;
	length gender $2;
	set est_Fcardiac
		est_Mcardiac
		est_Fcataract
		est_Mcataract
		est_FAll
		est_MAll;
	lookup = catx('', proc_group, gender, label);
	run;



/*Age*/


PROC IMPORT OUT= eth_age
            DATAFILE= "~\Ethnicity Elective Backlog\Sensitive\subanalysis_v3.xlsm"
            DBMS=EXCEL REPLACE;
     RANGE="age_working$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

data eth_age;
	set eth_age;
	log_exp = log(expected_all);
	log_pop = log(population/100000); * scale to rate per 100,000;
run;


%macro run_age_models(proc_group, age);


proc sql;
	create table d_&age.&proc_group. as
	select * 
	from eth_age 
	where 
		proc_group = "&proc_group." and 
		age50 = "&age." and 
		ethpop_broad4 ne 'All'
;
quit;


/* Create the population specific data sets */
proc sql;
	create table pop_&age.&proc_group. as
	select period_year, age50, gender, observed_all as observed, population_all as population
	from d_&age.&proc_group.
;
quit;



/*Continue*/

data pop_&age.&proc_group.;
   set pop_&age.&proc_group.;
   length ethpop_broad4 $ 5;
   ethpop_broad4 = 'All'; output;
   ethpop_broad4 = 'White'; output;
   ethpop_broad4 = 'Asian'; output;
   ethpop_broad4 = 'Black'; output;
   ethpop_broad4 = 'Mixed'; output;
   ethpop_broad4 = 'Other'; output;
run;


proc sort data = po_&gender.&proc_group. out = po_&gender.&proc_group.;
   by ethpop_broad4;
run;


proc sort data = d_&gender.&proc_group. out = d_&gender.&proc_group.;
   by ethpop_broad4 period_year age_10;
run;


proc sort data = d_&gender.&proc_group. out = d_&gender.&proc_group.;
   by ethpop_broad4 ;
run;

/*Run the indirect standardisation*/
/*NB be careful that refdata totals refer to White group*/

proc stdrate data=d_&gender.&proc_group. refdata=po_&gender.&proc_group.
             method=indirect stat=rate(mult=100000) plots=none ; 
             population event=observed total=population; 
             reference event=observed total=population;
             strata age_10 period_year / stats smr;
			 by ethpop_broad4 period_year;
			 ods output smr=smr_&gender.&proc_group.;
run;


data smr_&gender.&proc_group.;
  set smr_&gender.&proc_group.;
  log_exp = log(expectedevents);
  log_pop = log(population / 100000);
  rename observedevents = observed;
run;

/*Model 2 - using outputs from standardisation - SMR data*/
proc genmod data = smr_&gender.&proc_group.;
   class ethpop_broad4 (ref='White') period_year (ref='201920') / param=ref;
   model observed = ethpop_broad4 period_year ethpop_broad4*period_year / dist=poisson link=log offset=log_exp;
   	estimate 'White 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 0;
	estimate 'Asian 202021 v 201920' period_year 1 ethpop_broad4*period_year 1 0 0 0;
	estimate 'Black 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 1 0 0;
	estimate 'Mixed 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 1 0;
	estimate 'Other 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 1;
   ods output 
		parameterestimates = m2p_&gender.&proc_group.
		estimates          = m2c_&gender.&proc_group.;
run;


data out_&gender.&proc_group.;
	length proc_group $50;
	length gender $2;
	set m2p_&gender.&proc_group.;
	proc_group = "&proc_group.";
	region = "&gender.";
run;

data est_&gender.&proc_group.;
	length proc_group $50;
	length region $2;
	set m2c_&gender.&proc_group.;
	proc_group = "&proc_group.";
	gender = "&gender.";
run;



%mend;



/*Region and ethnicity*/

%macro run_sub_models(proc_group, region);


proc sql;
	create table d_&region.&proc_group. as
	select * 
	from eth_reg_cat 
	where 
		proc_group = "&proc_group." and 
	region_tiny = "&region." and 
	ethpop_broad4 ne 'All'
;
quit;


/* Create the population specific data sets */

/*Continue*/

proc means data = d_&region.&proc_group.(where = (ethpop_broad4 = 'White')) noprint nway;
   class period_year age_10 gender;
   var observed population;
   output out = po_&region.&proc_group. (drop = _type_ _freq_) sum= observed population;
run;

data po_&region.&proc_group.;
   set po_&region.&proc_group.;
   length ethpop_broad4 $ 5;
   ethpop_broad4 = 'All'; output;
   ethpop_broad4 = 'White'; output;
   ethpop_broad4 = 'Asian'; output;
   ethpop_broad4 = 'Black'; output;
   ethpop_broad4 = 'Mixed'; output;
   ethpop_broad4 = 'Other'; output;
run;


proc sort data = po_&region.&proc_group. out = po_&region.&proc_group.;
   by ethpop_broad4;
run;


proc sort data = d_&region.&proc_group. out = d_&region.&proc_group.;
   by ethpop_broad4 period_year age_10 gender;
run;


proc sort data = d_&region.&proc_group. out = d_&region.&proc_group.;
   by ethpop_broad4 ;
run;

/*Run the indirect standardisation*/
/*NB be careful that refdata totals refer to White group*/

proc stdrate data=d_&region.&proc_group. refdata=po_&region.&proc_group.
             method=indirect stat=rate(mult=100000) plots=none ; 
             population event=observed total=population; 
             reference event=observed total=population;
             strata age_10 gender period_year / stats smr;
			 by ethpop_broad4 period_year;
			 ods output smr=smr_&region.&proc_group.;
run;

data smr_&region.&proc_group.;
  set smr_&region.&proc_group.;
  log_exp = log(expectedevents);
  log_pop = log(population / 100000);
  rename observedevents = observed;
run;

/*Model 2 - using outputs from standardisation - SMR data*/
proc genmod data = smr_&region.&proc_group.;
   class ethpop_broad4 (ref='White') period_year (ref='201920') / param=ref;
   model observed = ethpop_broad4 period_year ethpop_broad4*period_year / dist=poisson link=log offset=log_exp;
   	estimate 'White 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 0;
	estimate 'Asian 202021 v 201920' period_year 1 ethpop_broad4*period_year 1 0 0 0;
	estimate 'Black 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 1 0 0;
	estimate 'Mixed 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 1 0;
	estimate 'Other 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 1;
   ods output 
		parameterestimates = m2p_&region.&proc_group.
		estimates          = m2c_&region.&proc_group.;
run;


data out_&region.&proc_group.;
	length proc_group $50;
	length region $2;
	set m2p_&region.&proc_group.;
	proc_group = "&proc_group.";
	region = "&region.";
run;

data est_&region.&proc_group.;
	length proc_group $50;
	length region $2;
	set m2c_&region.&proc_group.;
	proc_group = "&proc_group.";
	region = "&region.";
run;



%mend;


%run_sub_models(cardiac, ne);
%run_sub_models(cardiac, nw);
%run_sub_models(cardiac, y);
%run_sub_models(cardiac, em);
%run_sub_models(cardiac, wm);
%run_sub_models(cardiac, e);
%run_sub_models(cardiac, l);
%run_sub_models(cardiac, se);
%run_sub_models(cardiac, sw);

%run_sub_models(cataract, ne);
%run_sub_models(cataract, nw);
%run_sub_models(cataract, y);
%run_sub_models(cataract, em);
%run_sub_models(cataract, wm);
%run_sub_models(cataract, e);
%run_sub_models(cataract, l);
%run_sub_models(cataract, se);
%run_sub_models(cataract, sw);

%run_sub_models(All, ne);
%run_sub_models(All, nw);
%run_sub_models(All, y);
%run_sub_models(All, em);
%run_sub_models(All, wm);
%run_sub_models(All, e);
%run_sub_models(All, l);
%run_sub_models(All, se);
%run_sub_models(All, sw);

/*Want the output for all of these models*/
data proj.ethreg_models_out;
	length lookup $100;
	length proc_group $24;
	length region $2;
	set out_necardiac
		out_nwcardiac
		out_ycardiac
		out_emcardiac
		out_wmcardiac
		out_ecardiac
		out_lcardiac
		out_secardiac
		out_swcardiac
		out_necataract
		out_nwcataract
		out_ycataract
		out_emcataract
		out_wmcataract
		out_ecataract
		out_lcataract
		out_secataract
		out_swcataract
		out_neAll
		out_nwAll
		out_yAll
		out_emAll
		out_wmAll
		out_eAll
		out_lAll
		out_seAll
		out_swAll;
	lookup = catx('', proc_group, region, parameter, level1);
	value = exp(estimate);
	run;

data proj.ethreg_models_est;
	length lookup $100;
	length proc_group $24;
	length region $2;
	set est_necardiac
		est_nwcardiac
		est_ycardiac
		est_emcardiac
		est_wmcardiac
		est_ecardiac
		est_lcardiac
		est_secardiac
		est_swcardiac
		est_necataract
		est_nwcataract
		est_ycataract
		est_emcataract
		est_wmcataract
		est_ecataract
		est_lcataract
		est_secataract
		est_swcataract
		est_neAll
		est_nwAll
		est_yAll
		est_emAll
		est_wmAll
		est_eAll
		est_lAll
		est_seAll
		est_swAll;
	lookup = catx('', proc_group, region, label);
	run;



/*Load data*/
PROC IMPORT OUT= eth_dep
            DATAFILE= "~\Ethnicity Elective Backlog\Sensitive\subanalysis_ethdep.xlsm"
            DBMS=EXCEL REPLACE;
     RANGE="isr_quintile_working$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

data eth_dep;
	set eth_dep;
	log_exp = log(expected_white + 1);
	log_pop = log(population/100000); * scale to rate per 100,000;
run;



%macro dep_sub_models(proc_group, imd);


proc sql;
	create table d_&imd.&proc_group. as
	select * 
	from eth_dep 
	where 
		proc_group = "&proc_group." and 
	imd_quintile = "&imd." and 
	ethpop_broad4 ne 'All'
;
quit;


/* Create the population specific data sets */


/*Continue*/

proc means data = d_&imd.&proc_group.(where = (ethpop_broad4 = 'White')) noprint nway;
   class period_year age_10 gender;
   var observed population;
   output out = po_&imd.&proc_group. (drop = _type_ _freq_) sum= observed population;
run;

data po_&imd.&proc_group.;
   set po_&imd.&proc_group.;
   length ethpop_broad4 $ 5;
   ethpop_broad4 = 'All'; output;
   ethpop_broad4 = 'White'; output;
   ethpop_broad4 = 'Asian'; output;
   ethpop_broad4 = 'Black'; output;
   ethpop_broad4 = 'Mixed'; output;
   ethpop_broad4 = 'Other'; output;
run;


proc sort data = po_&imd.&proc_group. out = po_&imd.&proc_group.;
   by ethpop_broad4;
run;


proc sort data = d_&imd.&proc_group. out = d_&imd.&proc_group.;
   by ethpop_broad4 period_year age_10 gender;
run;


proc sort data = d_&imd.&proc_group. out = d_&imd.&proc_group.;
   by ethpop_broad4 ;
run;

/*Run the indirect standardisation*/
/*NB be careful that refdata totals refer to White group*/

proc stdrate data=d_&imd.&proc_group. refdata=po_&imd.&proc_group.
             method=indirect stat=rate(mult=100000) plots=none ; 
             population event=observed total=population; 
             reference event=observed total=population;
             strata age_10 gender period_year / stats smr;
			 by ethpop_broad4 period_year;
			 ods output smr=smr_&imd.&proc_group.;
run;

data smr_&imd.&proc_group.;
	length proc_group $50;
  set smr_&imd.&proc_group.;
  log_exp = log(expectedevents);
  log_pop = log(population / 100000);
  rename observedevents = observed;
  imd_quintile = "&imd.";
  proc_group = "&proc_group.";
run;

/*Model 2 - using outputs from standardisation - SMR data*/
proc genmod data = smr_&imd.&proc_group.;
   class ethpop_broad4 (ref='White') period_year (ref='201920') / param=ref;
   model observed = ethpop_broad4 period_year ethpop_broad4*period_year / dist=poisson link=log offset=log_exp;
   	estimate 'White 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 0;
	estimate 'Asian 202021 v 201920' period_year 1 ethpop_broad4*period_year 1 0 0 0;
	estimate 'Black 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 1 0 0;
	estimate 'Mixed 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 1 0;
	estimate 'Other 202021 v 201920' period_year 1 ethpop_broad4*period_year 0 0 0 1;
   ods output 
		parameterestimates = m2p_&imd.&proc_group.
		estimates          = m2c_&imd.&proc_group.;
run;


data out_&imd.&proc_group.;
	length proc_group $50;
	length imd_quintile $2;
	set m2p_&imd.&proc_group.;
	proc_group = "&proc_group.";
	imd_quintile = "&imd.";
run;

data est_&imd.&proc_group.;
	length proc_group $50;
	length imd_quintile $2;
	set m2c_&imd.&proc_group.;
	proc_group = "&proc_group.";
	imd_quintile = "&imd.";
run;



%mend;

%dep_sub_models(All, Q1);
%dep_sub_models(All, Q2);
%dep_sub_models(All, Q3);
%dep_sub_models(All, Q4);
%dep_sub_models(All, Q5);

%dep_sub_models(cataract, Q1);
%dep_sub_models(cataract, Q2);
%dep_sub_models(cataract, Q3);
%dep_sub_models(cataract, Q4);
%dep_sub_models(cataract, Q5);

%dep_sub_models(cardiac, Q1);
%dep_sub_models(cardiac, Q2);
%dep_sub_models(cardiac, Q3);
%dep_sub_models(cardiac, Q4);
%dep_sub_models(cardiac, Q5);

%dep_sub_models(dental, Q1);
%dep_sub_models(dental, Q2);
%dep_sub_models(dental, Q3);
%dep_sub_models(dental, Q4);
%dep_sub_models(dental, Q5);

%dep_sub_models(gi_endoscopy_diagnostic, Q1);
%dep_sub_models(gi_endoscopy_diagnostic, Q2);
%dep_sub_models(gi_endoscopy_diagnostic, Q3);
%dep_sub_models(gi_endoscopy_diagnostic, Q4);
%dep_sub_models(gi_endoscopy_diagnostic, Q5);

%dep_sub_models(gi_endoscopy_therapeutic, Q1);
%dep_sub_models(gi_endoscopy_therapeutic, Q2);
%dep_sub_models(gi_endoscopy_therapeutic, Q3);
%dep_sub_models(gi_endoscopy_therapeutic, Q4);
%dep_sub_models(gi_endoscopy_therapeutic, Q5);

%dep_sub_models(hips_and_knees, Q1);
%dep_sub_models(hips_and_knees, Q2);
%dep_sub_models(hips_and_knees, Q3);
%dep_sub_models(hips_and_knees, Q4);
%dep_sub_models(hips_and_knees, Q5);

%dep_sub_models(other, Q1);
%dep_sub_models(other, Q2);
%dep_sub_models(other, Q3);
%dep_sub_models(other, Q4);
%dep_sub_models(other, Q5);



/*Want the output for all of these models*/
data proj.ethdep_models_out;
	length lookup $100;
	length proc_group $24;
	length region $2;
	set 
		out_Q1All
		out_Q2All
		out_Q3All
		out_Q4All
		out_Q5All
		out_Q1cardiac
		out_Q2cardiac
		out_Q3cardiac
		out_Q4cardiac
		out_Q5cardiac
		out_Q1cataract
		out_Q2cataract
		out_Q3cataract
		out_Q4cataract
		out_Q5cataract
		out_Q1dental
		out_Q2dental
		out_Q3dental
		out_Q4dental
		out_Q5dental
		out_Q1gi_endoscopy_diagnostic
		out_Q2gi_endoscopy_diagnostic
		out_Q3gi_endoscopy_diagnostic
		out_Q4gi_endoscopy_diagnostic
		out_Q5gi_endoscopy_diagnostic
		out_Q1gi_endoscopy_therapeutic
		out_Q2gi_endoscopy_therapeutic
		out_Q3gi_endoscopy_therapeutic
		out_Q4gi_endoscopy_therapeutic
		out_Q5gi_endoscopy_therapeutic
		out_Q1hips_and_knees
		out_Q2hips_and_knees
		out_Q3hips_and_knees
		out_Q4hips_and_knees
		out_Q5hips_and_knees
		out_Q1other
		out_Q2other
		out_Q3other
		out_Q4other
		out_Q5other
;
	lookup = catx('', proc_group, imd_quintile, parameter, level1);
	value = exp(estimate);
	run;

data proj.ethdep_models_est;
	length lookup $100;
	length proc_group $24;
	length region $2;
	set 
		est_Q1All
		est_Q2All
		est_Q3All
		est_Q4All
		est_Q5All
		est_Q1cardiac
		est_Q2cardiac
		est_Q3cardiac
		est_Q4cardiac
		est_Q5cardiac
		est_Q1cataract
		est_Q2cataract
		est_Q3cataract
		est_Q4cataract
		est_Q5cataract
		est_Q1dental
		est_Q2dental
		est_Q3dental
		est_Q4dental
		est_Q5dental
		est_Q1gi_endoscopy_diagnostic
		est_Q2gi_endoscopy_diagnostic
		est_Q3gi_endoscopy_diagnostic
		est_Q4gi_endoscopy_diagnostic
		est_Q5gi_endoscopy_diagnostic
		est_Q1gi_endoscopy_therapeutic
		est_Q2gi_endoscopy_therapeutic
		est_Q3gi_endoscopy_therapeutic
		est_Q4gi_endoscopy_therapeutic
		est_Q5gi_endoscopy_therapeutic
		est_Q1hips_and_knees
		est_Q2hips_and_knees
		est_Q3hips_and_knees
		est_Q4hips_and_knees
		est_Q5hips_and_knees
		est_Q1other
		est_Q2other
		est_Q3other
		est_Q4other
		est_Q5other
;
	lookup = catx('', proc_group, imd_quintile, label);
	run;

data proj.ethdep_smr_out;
	length lookup $100;
	length proc_group $24;
	length imd_quintile $2;
	set 
		smr_Q1All
		smr_Q2All
		smr_Q3All
		smr_Q4All
		smr_Q5All
		smr_Q1cardiac
		smr_Q2cardiac
		smr_Q3cardiac
		smr_Q4cardiac
		smr_Q5cardiac
		smr_Q1cataract
		smr_Q2cataract
		smr_Q3cataract
		smr_Q4cataract
		smr_Q5cataract
		smr_Q1dental
		smr_Q2dental
		smr_Q3dental
		smr_Q4dental
		smr_Q5dental
		smr_Q1gi_endoscopy_diagnostic
		smr_Q2gi_endoscopy_diagnostic
		smr_Q3gi_endoscopy_diagnostic
		smr_Q4gi_endoscopy_diagnostic
		smr_Q5gi_endoscopy_diagnostic
		smr_Q1gi_endoscopy_therapeutic
		smr_Q2gi_endoscopy_therapeutic
		smr_Q3gi_endoscopy_therapeutic
		smr_Q4gi_endoscopy_therapeutic
		smr_Q5gi_endoscopy_therapeutic
		smr_Q1hips_and_knees
		smr_Q2hips_and_knees
		smr_Q3hips_and_knees
		smr_Q4hips_and_knees
		smr_Q5hips_and_knees
		smr_Q1other
		smr_Q2other
		smr_Q3other
		smr_Q4other
		smr_Q5other
;
	lookup = catx('', proc_group, imd_quintile, ethpop_broad4, period_year);
	run;


/*Check doing ethnicity analysis with proportion data*/
PROC IMPORT OUT= eth_recalc
            DATAFILE= "~\Ethnicity Elective Backlog\Sensitive\subanalysis_ethdep.xlsm"
            DBMS=EXCEL REPLACE;
     RANGE="recalc_eth_working$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

data eth_recalc;
	set eth_recalc;
	period_year = put(period_year, 6.);
	log_exp = log(expected_white + 1);
	log_pop = log(population/100000); * scale to rate per 100,000;
run;

proc sql;
	create table eth_recalc as
	select * from eth_recalc 
	where period_year ne .
;
quit;



%macro do_eth_recalc(proc_group);


proc sql;
	create table data_&proc_group. as
	select * 
	from eth_recalc 
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


proc sort data = data_&proc_group. out = data_&proc_group.;
	by ethpop_broad4 period_year age_10 gender;
run;

proc sort data = popr&proc_group. out = popr&proc_group.;
	by ethpop_broad4 period_year age_10 gender;
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
	where period_year in (201920, 202021)
;
	create table yr2&proc_group. as 
	select * 
  	from smr_&proc_group.
	where period_year in (201920, 202122)
;
	create table ys1&proc_group. as 
	select * 
	from data_&proc_group.
	where period_year in (201920, 202021)
;
	create table ys2&proc_group. as 
	select * 
	from data_&proc_group.
	where period_year in (201920, 202122)
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



%do_eth_recalc(cardiac);
%do_eth_recalc(cataract);
%do_eth_recalc(dental);
%do_eth_recalc(gi_endoscopy_diagnostic);
%do_eth_recalc(gi_endoscopy_therapeutic);
%do_eth_recalc(hips_and_knees);
%do_eth_recalc(other);
%do_eth_recalc(All);


 
data proj.ethnos_recalc_out21;
	length proc_group $24;
	set est21cardiac
		est21cataract
		est21dental
		est21gi_endoscopy_diagnostic
		est21gi_endoscopy_therapeutic
		est21hips_and_knees
		est21other
		est21all;
run;

data proj.ethnos_rates_outrc;
length proc_group $24;
set smr_cardiac
	smr_cataract
	smr_dental
	smr_gi_endoscopy_diagnostic
	smr_gi_endoscopy_therapeutic
	smr_hips_and_knees
	smr_other
	smr_all;
run;

  
PROC IMPORT OUT= proj.ethdeppcent 
            DATAFILE= "~\Ethnicity Elective Backlog\Sensi
tive\subanalysis_ethdep.xlsm" 
            DBMS=EXCEL REPLACE;
     RANGE="ethdeppcent$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

proc sql;
	create table ethdep_smr1 as 
	select a.*
  		, b.population
		, (a.observed / b.population) * 100000 as crude_rate

	from proj.ethnos_rates_outrc a
		left join proj.ethpop_total b
			on a.ethpop_broad4 = b.ethpop_broad and 
				a.period_year = b.period_year
		left join proj.ethdeppcent c
			on a.ethpop_broad4 = c.ethpop_broad4 and
				b.period_year = c.period_year
	order by 
		proc_group, period_year, ethpop_broad4, imd_quintile
;

quit;

	create table ethdep_smr2 as 
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
  
  
