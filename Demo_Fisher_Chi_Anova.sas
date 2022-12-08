
proc format; 
	value a
		1='n' 
        2='Mean (SD)' 
		3 ='Sem'
	    4='Median' 
	    5='Q1 ; Q3' 
	    6='Min ; Max';
run; 

libname abc "/home/u57872820/sasuser.v94";

data dummy;
length v1 $ 200;
 v1 = 'Age (Year)';                  ord1=1; grpord=0; output;
 v1 = 'Sex, n (%)';                  ord1=3; grpord=0; output;
 v1 = 'Race, n (%)';                 ord1=4; grpord=0; output;
 v1 = 'Ethnicity, n (%)';            ord1=5; output;
 v1 = 'Religion, n (%)';             ord1=6; output;
 v1 = 'Spirituality Status, n (%)';  ord1=7; output;
 v1 = 'Fellowship Year, n (%)';      ord1=8; grpord=0; output;
 v1 = 'Stressful, n (%)';            ord1=9; grpord=0; output;
 v1 = 'Frequency In Activities To Reduce Stress Levels, n (%)';            ord1=10; grpord=0; output;
 v1 = 'Medical School from Unites States, n (%)'; ord1=11; grpord=0; output;
 v1 = 'Palliative Care Experience category 1, n (%)'; ord1=12; grpord=0; output;
 v1 = 'Palliative Care Experience category 2, n (%)'; ord1=13; grpord=0; output;
 v1 = 'Leave Position, n (%)'; ord1=14; grpord=0; output;
 v1 = 'Cumulative Score Of All Questionnaire Scales'; ord1=15; grpord=0; output;
 v1 = 'Cumulative Score Of Frequency Questionnaire Scales'; ord1=16; grpord=0; output;
 v1 = 'Cumulative Score Of Severity Questionnaire Scales'; ord1=17; grpord=0; output;
run;


proc sort data=abc.adeff nodupkey out=tot; by subject quitf; run;

proc freq data=tot noprint;
	table quitf / out=total(drop=percent rename=(count=headc));
run;

proc sort data=total; by quitf; run;

%macro demofrq (var=, dsout=, ord1=);

proc freq data=tot noprint;
	table &var.*quitf / out=freq_tot(drop=percent);
	where &var ne '';
run;

proc sort data=freq_tot; by quitf; run;

data prefin;
	merge total(in=a) freq_tot(in=b);
	by quitf;
	length countc v1 $100.;
	if count ne . then countc=put(count,4.)||" ("||put((count/headc)*100,4.1)||"%)";
	else countc=put(count,4.);
	ord1=&ord1;
	v1=&var.;
run;

proc sort; by ord1 v1; run;

proc transpose data=prefin out=t_prefin(drop=_name_);
	by ord1 v1;
	id quitf;
	var countc;
run;
proc sort; by ord1; run;

data &dsout.;
 set t_prefin;
 by ord1;
 if first.ord1 then grpord=1;
 else grpord+1;
run;

%mend;

%demofrq (var=sex, dsout=sexfq, ord1=3);
%demofrq (var=race, dsout=racefq, ord1=4);
%demofrq (var=ethinic, dsout=ethifq, ord1=5);
%demofrq (var=religion, dsout=rlgfq, ord1=6);
%demofrq (var=spirit, dsout=spfq, ord1=7);
%demofrq (var=fellowyr, dsout=felfq, ord1=8);
%demofrq (var=stressyn, dsout=stressfq, ord1=9);
%demofrq (var=actfreq, dsout=actfq, ord1=10);
%demofrq (var=medusa, dsout=medusfq, ord1=11);
%demofrq (var=palexp1, dsout=palexfq1, ord1=12);
%demofrq (var=palexp2, dsout=palexfq2, ord1=13);
%demofrq (var=lpos, dsout=lposfq, ord1=14);
*************;

%Macro cont (var=, dsout=, ord1=);

proc sort data=tot; by quitf; run;

proc means data=tot nway noprint;
by quitf;
var &var.;
output out=stat&var. n=n nmiss=nmiss stderr=se mean=mean stderr=stderr median=median q1=q1 q3=q3 min=min max=max std=sd;
run;

data stat&var.; 
set stat&var.; 
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

proc transpose data=stat&var. out=t_stat&var.(drop=_:); 
  by ord1; 
  id quitf; 
  var text1-text6; 
run;

proc sort; by ord1; run;

data t_stat&var.1;
  set t_stat&var.;
  by ord1;
  if first.ord1 then grpord=1;
  else grpord+1;
  length V1 $200; 
  ord=_n_; 
  V1=strip(put(ord,A.)); 	
run;

%mend cont;

%cont(var=age,     ord1=1);
%cont(var=cumsall, ord1=15);
%cont(var=cumsfq,  ord1=16);
%cont(var=cumsdl,  ord1=17);



**********;

ods output chisq=chimedus;
proc freq data = tot;
  tables medusa*quitf / chisq  relrisk;
run;

data meduschi;
 set chimedus;
 where statistic='Chi-Square';
 pvalue=strip(put(prob,6.4))||"^{super d}";
 ord1=11;
 keep ord1 pvalue;
run;

%macro fishext (var=, dsout=, ord1=);

ods output fishersexact=ff;
proc freq data = tot;
  tables &var.*quitf / fisher;
run;


data &dsout.;
 set ff;
 where name1='XP2_FISH';
 pvalue=cvalue1||"^{super b}";
 ord1=&ord1.;
 keep ord1 pvalue;
run;

%mend;

%fishext (var=sex,       dsout=sexfis,     ord1=3);
%fishext (var=race,      dsout=racefis,    ord1=4);
%fishext (var=ethinic,   dsout=ethifis,    ord1=5);
%fishext (var=religion,  dsout=rlgfis,     ord1=6);
%fishext (var=spirit,    dsout=spfis,      ord1=7);
%fishext (var=fellowyr,  dsout=felfis,     ord1=8);
%fishext (var=stressyn,  dsout=stressfis,  ord1=9);
%fishext (var=actfreq,   dsout=actfis,     ord1=10);
%fishext (var=palexp1,   dsout=palexfis1,  ord1=12);
%fishext (var=palexp2,   dsout=palexfis2,  ord1=13);
%fishext (var=lpos,      dsout=lposfis,    ord1=14);

******;
ods output OverallANOVA=anvag;
proc anova data=abc.adeff;			/* one-way analysis of variance*/
   class quitf;
   model age = quitf;
 run;
quit;

data anvag1;
 set anvag;
 where source='Model';
 pvalue=strip(put(probf,6.4))||"^{super a}";
 ord1=1;
 keep ord1 pvalue;
run;

ods output OverallANOVA=ancumal;
proc anova data=abc.adeff;			/* one-way analysis of variance*/
   class quitf;
   model cumsall = quitf;
   means  quitf;
 run;
quit;

data ancumal1;
 set ancumal;
 where source='Model';
 if probf= <.0001 then pvalue=strip('<.0001')||"^{super a}";
 else pvalue=strip(put(probf,6.4))||"^{super a}";
 ord1=15;
 keep ord1 pvalue;
run;

ods output TTests=cumsfqtt;
proc ttest data = abc.adeff;
  class quitf;
  var cumsfq;
run;


data cumsfqtt1;
 set cumsfqtt;
 where method='Pooled';
 if probt= <.0001 then pvalue=strip('<.0001')||"^{super e}";
 else pvalue=strip(put(probt,6.4))||"^{super e}";
 ord1=16;
 keep ord1 pvalue;
run;

ods output TTests=cumsdltt;
proc ttest data = abc.adeff;
  class quitf;
  var cumsdl;
run;

data cumsdltt1;
 set cumsdltt;
 where method='Pooled';
 if probt= <.0001 then pvalue=strip('<.0001')||"^{super e}";
 else pvalue=strip(put(probt,6.4))||"^{super e}";
 ord1=17;
 keep ord1 pvalue;
run;

data all_pvalue;
 set sexfis racefis ethifis rlgfis spfis felfis stressfis actfis meduschi palexfis1
     palexfis2 lposfis anvag1 ancumal1 cumsfqtt1 cumsdltt1;
run;

proc sort data=dummy; by ord1; run;
proc sort data=all_pvalue; by ord1; run;

data dum_pv;
 merge dummy(in=a) all_pvalue;
 by ord1;
run;

data all_Stat;
 set sexfq racefq ethifq rlgfq spfq felfq stressfq actfq medusfq palexfq1 palexfq2 lposfq
     t_statage1 t_statcumsall1 t_statcumsfq1 t_statcumsdl1;
run;

proc sort data=all_stat; by ord1; run;

data final;
 set dum_pv all_stat;
run;

proc sort data=final; by ord1; run;
run;

data final_(rename=(v1_=v1));
 set final;
 if grpord ^=0 then v1_='  '||v1;
 else v1_=v1;
 drop v1;
run;

proc sql noprint;
	  select count(distinct subject) into :n1 from tot where  quitf='Yes';
	  select count(distinct subject) into :n2 from tot where  quitf='No';
quit;

proc sort data=final_; by ord1; run;
 
*************************;
options nonumber nodate papersize = A4 orientation = portrait;
ods escapechar="^";
ods rtf path="/home/u57872820/sasuser.v94" file="Quit vs Continue Fellowship.rtf";
proc report data = final_ split = "|"
style(report)={rules=cols cellspacing=2 cellpadding=2}
style(header)={background=white borderbottomwidth=0.75pt}
style(column)={asis=on};
columns ("Table 1|Demographic and Questionnaire Scores|(In Fellows Who Wants To Quit vs Continue Training)"
 ord1 grpord v1 Yes No pvalue);
 
define ord1 /order order=internal noprint;
define grpord /order order=internal noprint;
define v1 /display style(column)={cellwidth=200pt} "Parameter|Statistic";
define Yes /display center style(column)={cellwidth=100pt} "Quit Fellowship|(N=%cmpres(&n1))";
define No /display center style(column)={cellwidth=100pt} "Continue Fellowship|(N=%cmpres(&n2))";
define pvalue /display center style(column)={cellwidth=70pt} "P-value";
define ord1 /order order=formatted noprint;

compute grpord;
 if grpord = 0 then call define(_row_,"style","style={bordertopwidth=0.75pt}");
 if grpord = 0 then call define(_col_,"style","style={font_weight=bold}");
endcomp;

compute after _page_ /style={bordertopwidth=0.75pt font_size=9.5pt};
 line @1 "n and % are based on non-missing values" ;
 line @1 "Multiple means fellows selected more then one reason" ;
 line @1 "^{super a} One-way analysis of variance for the comparison.";
 line @1 "^{super b} Two-sided Fisher's exact test P-value for the comparison.";
 line @1 "^{super d} Chi-Square P-value for the comparison.";
 line @1 "^{super e} Independent group t-test P-value for the comparison.";
 
endcomp;
run;
ods rtf close;



