libname abc "/home/u57872820/sasuser.v94";

proc datasets library=WORK kill nolist; run; quit;

proc sort data=abc.adbmd nodupkey out=tot_; by subject; run;

data tot;
set tot_;
if age_in_years ne . and sexc='Female';
run;

data tot1;
set tot;
array x {*} bip__hip left_femur rfrn;    
min = min(of x[*]);       /* min value for this observation */
max = max(of x[*]);       /* max value for this observation */
run;

proc sql noprint;
 select count(*)
 into :nobs
 from tot;
 quit;

%macro con (dsout=, var=, ord=);
ods output solutionf=soln;
proc mixed data=tot1 cl covtest;
class cve (ref='No');
model &var=cve/ solution cl alpha=0.05; 
run;

data &dsout.;
 set soln(where=(effect ^='Intercept'));
 length v1 pvalm est cul $ 200;
 if .< probt <= .0001 then pvalm=strip('<.0001');
 else pvalm=strip(put(probt,6.4));
 if estimate eq 0 then est='Reference';
 else if estimate not in (. 0)  then est=strip(put(estimate,11.2));
 if lower ne . and upper ne .  then cul=strip(put(lower,11.2))||', '||strip(put(upper,11.2));
 if effect='cve' and cve='Yes' then do;   ord1=&ord..2; v1='Cardiac Event'; end;
 if effect='cve' and cve='No' then do;    ord1=&ord..1; v1='No Cardiac Event'; end;
  keep v1 ord1 pvalm est cul;
run; 

%mend;
%con (dsout=ds1, var=%str(bmd__hip), ord=1);
%con (dsout=ds2, var=%str(left_femur), ord=2);
%con (dsout=ds3, var=%str(rfrn), ord=3);
%con (dsout=ds4, var=%str(min), ord=4);


data pvalm;
 set ds:;
run;

data dummy;
length v1 $ 200;
 v1 = 'HIP Score';              ord1=1; grpord=0; output;
 v1 = 'Left Femur Score';       ord1=2; grpord=0; output;
 v1 = 'Right Femur Score';      ord1=3; grpord=0; output;
 v1 = 'Combined';               ord1=4; grpord=0; output;
 run;

proc sort data=dummy; by ord1; run;
proc sort data=pvalm; by ord1; run;


data final;
 set dummy(in=a) pvalm;
run;

proc sort data=final; by ord1; run;
run;

data final1(rename=(v1_=v1));
 set final;
  if grpord ^=0 then v1_='  '||v1;
  else v1_=v1;
 drop v1;
run;

proc sort data=final1; by ord1; run;
 
*************************;
*************************;
options nonumber nodate papersize = A4 orientation = portrait;
ods escapechar="^";
ods rtf path="/home/u57872820/sasuser.v94" file="Linear Regression for BMD and ASCVD.rtf";
proc report data = final1 split = "|"
style(report)={rules=cols cellspacing=2 cellpadding=2}
style(header)={background=white borderbottomwidth=0.75pt}
style(column)={asis=on};
columns ("Table |Linear Regression for BMD and ASCVD"
 ord1 grpord v1 est cul pvalm);
 
define ord1 /order order=internal noprint;
define grpord / order=internal noprint;
define v1 /display style(column)={cellwidth=200pt} "Parameter Statistic";
/* define msd /display center style(column)={cellwidth=100pt} "Mean (SD)"; */
define est /display center style(column)={cellwidth=70pt} "Estimate";
define cul /display center style(column)={cellwidth=100pt} "Confidence Interval";
define pvalm /display center style(column)={cellwidth=70pt} "P-value";

compute grpord;
 if grpord = 0 then call define(_row_,"style","style={bordertopwidth=0.75pt}");
 if grpord = 0 then call define(_col_,"style","style={font_weight=bold}");
endcomp;
run;
ods rtf close;
