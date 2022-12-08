proc datasets lib=work
 nolist kill;
quit;
run;

libname analyses '/home/u57872820/sasuser.v94/MDUR/Trust';
/* 1 = Strongly Disagree 2 = Disagree 3 = Slightly disagree 4= Slightly agree 5 = Agree 6 = Strongly Agree*/


data tot_;
 set analyses.pam_trust;
 if age_cat="<65" then age_catn=0;
 else if age_cat=">=65" then age_catn=1;
 else if age_cat="Missing" then age_catn=.;
 if financialstrain="Yes" then fstn=0;
 else if financialstrain="No" then fstn=1;
 if gendern=1 then genn=0;
 else if gendern=0 then genn=1;
run;

proc sort data=tot_ nodupkey out=tot; by idno; run;

proc sql noprint;
 select count(*)
 into :nobs
 from tot;
 quit;


ods output solutionf=soln;
proc mixed data=tot cl covtest;
class age_catn(ref='0') genn(ref='1') educationn(ref='1') racen(ref='1') incomen (ref='1');
model sdm=SOCSUPPORT dialysisyears age_catn genn educationn racen incomen/ solution cl alpha=0.05; 
run;

data pvalm;
 set soln(where=(effect ^='Intercept'));
 length v1 pvalm est cul $ 200;
 if .< probt <= .0001 then pvalm=strip('<.0001');
 else pvalm=strip(put(probt,6.4));
 if estimate eq 0 then est='Reference';
 else if estimate not in (. 0)  then est=strip(put(estimate,11.2));
 if lower ne . and upper ne .  then cul=strip(put(lower,11.2))||', '||strip(put(upper,11.2));
 if effect='age_catn' and age_catn=0  then do;   ord1=1.1; v1='<65'; end;
 else if effect='age_catn' and age_catn=1  then do;   ord1=1.2; v1='65 - 74'; end;
 else if effect='age_catn' and age_catn=2  then do;   ord1=1.3; v1='>=75'; end;
 else if effect='age_catn' and age_catn=3  then do;   ord1=1.4; v1='Missing'; end;
 else if effect='genn' and genn=1          then do;    ord1=2.1; v1='Female'; end;
 else if effect='genn' and genn=0          then do;   ord1=2.2; v1='Male'; end;
 else if effect='racen' and racen=1        then do;    ord1=3.1; v1='White'; end;
 else if effect='racen' and racen=2        then do;   ord1=3.2; v1='Black/African American'; end;
 else if effect='racen'  and racen= 3      then do;    ord1=3.3; v1='Other'; end;
 else if effect='educationn' and  educationn= 1  then do;    ord1=5.1; v1='Greater than High School'; end;
 else if effect='educationn' and educationn=0    then do;    ord1=5.2; v1='High School of Less';end;
 else if effect='incomen' and incomen=1            then do;    ord1=6.1; v1='>20,000'; end;
 else if effect='incomen' and incomen=0             then do;   ord1=6.2;  v1='<=20,000';end;
/*  else if effect='fstn'   and fstn=0                then do;    ord1=8.1; v1='No'; end; */
/*  else if effect='fstn'    and fstn=1              then do;   ord1=8.2; v1='Yes'; end; */
  else if effect='dialysisyears'                    then do;    ord1=8;  end;
/*   else if effect='Trust'                    then do;    ord1=10;  end; */
/*   else if effect='pam_sum'                    then do;    ord1=11;  end; */
   else if effect='socsupport'                    then do;    ord1=12;  end;
 keep v1 ord1 pvalm est cul;
run; 


data dummy;
length v1 $ 200;
 v1 = 'Age Category';              ord1=1; grpord=0; output;
 v1 = 'Gender';                    ord1=2; grpord=0; output;
 v1 = 'Race';                      ord1=3; grpord=0; output;
 v1 = 'Education';                 ord1=5; grpord=0; output;
 v1 = 'Income';                    ord1=6; grpord=0; output;
 v1 = 'Time on Dialysis (Years)';           ord1=8; grpord=0; output;
/*  v1 = 'Trust Score';               ord1=10; grpord=0; output; */
/*  v1 = 'Patient Activation Measure sum score';  ord1=11; grpord=0; output; */
 v1 = 'Social support sum score';  ord1=12; grpord=0; output;
 run;

proc sort data=dummy; by ord1; run;
proc sort data=pvalm; by ord1; run;

data final;
 set dummy pvalm;
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
ods rtf path="/home/u57872820/sasuser.v94/MDUR/Trust" file="Social_MLR.rtf";
proc report data = final1 split = "|"
style(report)={rules=cols cellspacing=2 cellpadding=2}
style(header)={background=white borderbottomwidth=0.75pt}
style(column)={asis=on};
columns ("Table |Social Support Multivariate Linear Regression"
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

compute after _page_ /style={bordertopwidth=0.75pt font_size=9.5pt};
 line @1 "1) Dependent variable SDM score.";
 line @1 "2) Independent variables are Social Support Score, Dialysis years, Age category, Gender, Race, Education, Income";
endcomp;
run;
ods rtf close;



