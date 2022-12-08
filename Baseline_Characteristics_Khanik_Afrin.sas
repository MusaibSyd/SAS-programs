
proc datasets lib=work
 nolist kill;
quit;
run;

libname abc "/home/u57872820/sasuser.v94/Saif_Dental";

data dummy;
length v1 $ 200;
 v1 = 'Age (Year)';                  ord1=1; grpord=0; output;
 v1 = 'Sex, n (%)';                  ord1=2; grpord=0; output; 
 v1 = 'Infection Present, n (%)';    ord1=3; grpord=0; output;
 v1 = 'Gingiva, n (%)';                     ord1=4; grpord=0; output;
 v1 = 'Plaque Level, n (%)';                ord1=5; grpord=0; output;
 v1 = 'Pain Level, n (%)';                  ord1=6; grpord=0; output;
 v1 = 'Toothbrush, n (%)';                  ord1=7; grpord=0; output;
 v1 = 'Toothbrush Use Frequency, n (%)';    ord1=8; grpord=0; output;
 v1 = 'Candies and Sweet Frequency, n (%)'; ord1=9; grpord=0; output;
 v1 = 'Sugardrinks and Soda, n (%)';        ord1=10; grpord=0; output;
 v1 = 'Sugar in Tea and Milk, n (%)';       ord1=11; grpord=0; output;
 v1 = 'Dentition Status';                   ord1=12; grpord=0; output;
 v1 = 'Dental Procedures Perfomed, n (%)';  ord1=13; grpord=0; output;

run;


data tot_;
 set abc.ad3;
 if group in ('Khanik' 'Afrin');
run;

proc sort data=tot_ out=tot; by group; run;

proc sql noprint;
 select count(*)
 into :nobs
 from tot;
 quit;
 
proc freq data=tot noprint;
	table group / out=total(drop=percent rename=(count=headc));
run;

proc sort data=total; by group; run;

%macro demofrq (var=, dsout=, ord1=);

proc freq data=tot noprint;
	table &var.*group / out=freq_tot(drop=percent);
	where &var not in ('.' '');
run;

proc sort data=freq_tot; by group; run;

data prefin;
	merge total(in=a) freq_tot(in=b);
	by group;
	length countc v1 $100.;
	if count ne . then countc=strip(put(count,4.)||" ("||put((count/headc)*100,4.1)||"%)");
	else countc=strip(put(count,4.));
	ord1=&ord1;
	v1=&var.;
run;

proc sort; by ord1 v1; run;

proc transpose data=prefin out=t_prefin(drop=_name_);
	by ord1 v1;
	id group;
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

%demofrq (var=agec,  dsout=fq1,  ord1=1);
%demofrq (var=gen,   dsout=fq2,  ord1=2);
%demofrq (var=inf,   dsout=fq3,  ord1=3);
%demofrq (var=ging,  dsout=fq4,  ord1=4);
%demofrq (var=plql,  dsout=fq5,  ord1=5);
%demofrq (var=painl, dsout=fq6,  ord1=6);
%demofrq (var=tb,    dsout=fq7,  ord1=7);
%demofrq (var=tbf,   dsout=fq8,  ord1=8);
%demofrq (var=cs,    dsout=fq9,  ord1=9);
%demofrq (var=sds,   dsout=fq10,  ord1=10);
%demofrq (var=sitm,  dsout=fq11,  ord1=11);
%demofrq (var=dst, dsout=fq12,  ord1=12);
%demofrq (var=treat, dsout=fq13,  ord1=13);

*************;

data all_Stat;
 set dummy fq:;
run;


proc sort data=all_stat; by ord1; run;

data final_(rename=(v1_=v1));
 set all_stat;
 if grpord ^=0 then v1_='  '||v1;
 else v1_=v1;
 if grpord ^= 0 then do;
  array nvars {2} khanik afrin;
  do i = 1 to 2;
  if nvars{i} = '' then nvars{i} = '0';
  end;
  end;
 drop v1 i;
run;


proc sql noprint;
	  select count(distinct idno) into :n1 from tot where  group='Khanik';
	  select count(distinct idno) into :n3 from tot where  group='Afrin';
quit; 

proc sort data=final_; by ord1; run;
  
*************************;
*************************;
options nonumber nodate papersize = A4 orientation = portrait;
ods escapechar="^";
ods rtf path="/home/u57872820/sasuser.v94" file="Baseline_Characteristics_Khanik_Afrin.rtf";
proc report data = final_ split = "|"
style(report)={rules=cols cellspacing=2 cellpadding=2}
style(header)={background=white borderbottomwidth=0.75pt}
style(column)={asis=on};
columns ("Table |Baseline Characteristics Khanik and Afrin"
 ord1 grpord v1 khanik afrin);
 
define ord1 /order order=internal noprint;
define grpord /order order=internal noprint;
define v1 /display style(column)={cellwidth=250pt} "Parameter|Statistic";
define khanik /display center style(column)={cellwidth=100pt} "Khanik|(N=%cmpres(&n1))";
define afrin /display center style(column)={cellwidth=100pt} "Afrin|(N=%cmpres(&n3))";

compute grpord;
 if grpord = 0 then call define(_row_,"style","style={bordertopwidth=0.75pt}");
 if grpord = 0 then call define(_col_,"style","style={font_weight=bold}");
endcomp;

compute after _page_ /style={bordertopwidth=0.75pt font_size=9.5pt};
endcomp;
run;
ods rtf close;