
proc datasets lib=work
 nolist kill;
quit;
run;

libname analyses '/home/u57872820/sasuser.v94/MDUR/Trust';

proc format; 
	value A
		1='n' 
        2='Mean (SD)' 
		3 ='Sem'
	    4='Median' 
	    5='Q1 ; Q3' 
	    6='Min ; Max';
run; 

data tot_;
 set analyses.pam_trust;
 if age_cat="<65" then age_catn=0;
 else if age_cat="65 - 74" then age_catn=1;
 else if age_cat=">=75" then age_catn=2;
 else if age_cat="Missing" then age_catn=3;
 if financialstrain="Yes" then fstn=0;
 else if financialstrain="No" then fstn=1;
 if gendern=1 then genn=0;
 else if gendern=0 then genn=1;
 if .<sdm<=26 then sdmc="SDM Score <=26";
 else if sdm > 26 then sdmc="SDM Score >26";
run;

proc sort data=tot_ nodupkey out=tot; by idno; run;

proc sql noprint;
 select count(*)
 into :nobs
 from tot;
 quit;

%macro demofrq (var=, dsout=, ord1=);

proc freq data=tot noprint;
	table &var./ out=freq_tot(drop=percent);
	where &var not in ('.' '');
run;

data prefin;
	set freq_tot;
	length v1 col1 $100.;
	if count ne . then col1=put(count,4.)||" ("||put((count/&nobs.)*100,4.1)||"%)";
	else col1=put(count,4.);
	ord1=&ord1;
	v1=&var.;
run;

proc sort; by ord1 v1; run;

data &dsout.;
 set prefin;
 by ord1;
 if first.ord1 then grpord=1;
 else grpord+1;
run;

%mend;

%demofrq (var=age_cat, dsout=agefq,  ord1=1);
%demofrq (var=gender,  dsout=sexfq,  ord1=2);
%demofrq (var=race,    dsout=rcfq,  ord1=2.1);
%demofrq (var=married, dsout=marfq,  ord1=3);
%demofrq (var=education, dsout=edfq, ord1=4);
%demofrq (var=income,  dsout=incfq,   ord1=5);
%demofrq (var=financialstrain, dsout=finfq, ord1=6);

*************;

%Macro cont (var=, dsout=, ord1=);

proc means data=tot nway noprint;
var &var.;
output out=stat n=n nmiss=nmiss stderr=se mean=mean stderr=stderr median=median q1=q1 q3=q3 min=min max=max std=sd;
run;

data stat1; 
set stat; 
length text1 - text6 $200;
ord1= &ord1;
if n^=. then text1=strip(put(n,best.)); 
if mean^=. and sd^=. then text2=strip(put(mean,11.2))||' ('||strip(put(sd,11.3))||')'; 
else if mean^=. and sd=. then text2=strip(put(mean,11.2))||' (NE)'; 
text3=strip(put(round(se,0.001), 11.3));
if median ^=. then text4=strip(put(median,11.)); 
if q1^=. and q3^=. then text5=strip(put(q1,11.))||' ; '||strip(put(q3,11.));
if min^=. and max^=. then text6=strip(put(min,11.0))||' ; '||strip(put(max,11.0));
run; 

proc transpose data=stat1 out=t_stat1(drop=_:); 
  by ord1;
  var text1-text6; 
run;

proc sort; by ord1; run;

data &dsout;
  set t_stat1;
  by ord1;
  if first.ord1 then grpord=1;
  else grpord+1;
  length V1 $200; 
  ord=_n_; 
  V1=strip(put(ord,A.)); 	
run;

%mend cont;

%cont(var=trust,    dsout=mc1,    ord1=7);
%cont(var=pam_sum,  dsout=mc2,    ord1=8);
%cont(var=sdm,      dsout=mc3,    ord1=9);
%cont(var=sdm,      dsout=mc3,    ord1=9);
%cont(var=socsupport,      dsout=mc4,    ord1=10);



data dummy;
length v1 $ 200;
 v1 = 'Age Category, n (%)';                ord1=1;  grpord=0; output;
 v1 = 'Gender, n (%)';                      ord1=2;  grpord=0; output;
 v1 = 'Race, n (%)';                        ord1=2.1;  grpord=0; output;
 v1 = 'Married, n (%)';                     ord1=3;  grpord=0; output;
 v1 = 'Education, n (%)';                   ord1=4;  grpord=0; output;
 v1 = 'Income, n (%)';                      ord1=5;  grpord=0; output;
 v1 = 'Financialstrain, n (%)';             ord1=6;  grpord=0; output;
 v1 = 'Trust score';                        ord1=7;  grpord=0; output;
 v1 = 'Patient Activation Measure score';  ord1=8; grpord=0; output;
 v1 = 'Shared Decision Making score';  ord1=9; grpord=0; output;
 v1 = 'Social Support score';  ord1=10; grpord=0; output;
run;
 

data all_Stat;
 set dummy agefq sexfq rcfq marfq edfq incfq finfq mc:;
run;


proc sort data=all_stat; by ord1; run;

data final_(rename=(v1_=v1));
 set all_stat;
 if grpord ^=0 then v1_='  '||v1;
 else v1_=v1;
 drop v1;
run;

proc sort data=final_; by ord1; run;
  
*************************;
*************************;
options nonumber nodate papersize = A4 orientation = portrait;
ods escapechar="^";
ods rtf path="/home/u57872820/sasuser.v94/MDUR/Trust" file="SDM_Baseline Characteristics.rtf";
proc report data = final_ split = "|"
style(report)={rules=cols cellspacing=2 cellpadding=2}
style(header)={background=white borderbottomwidth=0.75pt}
style(column)={asis=on};
columns ("Table |Baseline Characteristics"
 ord1 grpord v1 col1);
 
define ord1 /order order=internal noprint;
define grpord /order order=internal noprint;
define v1 /display style(column)={cellwidth=250pt} "Parameter|Statistic";
define col1 /display center style(column)={cellwidth=100pt} "N=%cmpres(&nobs)";

compute grpord;
 if grpord = 0 then call define(_row_,"style","style={bordertopwidth=0.75pt}");
 if grpord = 0 then call define(_col_,"style","style={font_weight=bold}");
endcomp;

compute after _page_ /style={bordertopwidth=0.75pt font_size=9.5pt};
endcomp;
run;
ods rtf close;



