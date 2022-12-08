proc datasets lib=work
 nolist kill;
quit;
run;

libname analyses '/home/u57872820/sasuser.v94/MDUR/Trust';
/* 1 = Strongly Disagree 2 = Disagree 3 = Slightly disagree 4= Slightly agree 5 = Agree 6 = Strongly Agree*/


data tot_;
 set analyses.pam_trust;
 if age_cat="<65" then age_catn=0;
 else if age_cat="65 - 74" then age_catn=1;
 else if age_cat=">=75" then age_catn=2;
 else if age_cat="Missing" then age_catn=.;
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


ods output ParameterEstimates=pe01 OddsRatios=or01;
proc logistic data=tot;
class age_catn(ref='0') genn(ref='1') educationn(ref='1') racen(ref='1') incomen (ref='1') fstn (ref='1')/ param=ref;
model sdmc (event='SDM Score >26') = trust socsupport pam_sum age_catn genn educationn racen incomen fstn/selection=stepwise slentry=1 slstay=1;
run;
quit;


data or02;
set or01;
length cat $200;
variable=strip(scan(effect,1,''));
cat=strip(scan(effect,2,''));
drop effect;
run;

proc sort data=or02; by variable; run;

proc sort data=pe01 out=pe02(keep= variable probchisq classval0 rename=(classval0=cat)) ; by variable; 
where variable ^= 'Intercept';
run;

data all;
 merge or02(in=a) pe02(in=b);
 by variable cat;
 if a and b;
 length var $200;
 if variable='age_catn' and cat='1' then var='age1';
 else if variable='age_catn' and cat='2' then var='age2';
 else if variable='educationn' and cat='0' then var='edu0';
 else if variable='fstn' and cat='0' then var='fst0';
 else if variable='genn' and cat='0' then var='gen0';
 else if variable='incomen' and cat='0' then var='inc0';
 else if variable='racen' and cat='2' then var='race2';
 else if variable='racen' and cat='3' then var='race3';
 else var=variable;
run;

proc sort; by var;  run;

%macro mml (var=, dsout=, num=, lbl=);

data &dsout.;
 length v1-v4 $ 200.;
 set all;
 if upcase(var)="&var" then do;
 v2=strip(put(oddsratioest,11.2));
 v3=strip(put(lowercl,11.3))||'-'||strip(put(uppercl,11.3));
 if .< probchisq <= .0001 then v4=strip('<.0001');
 else v4=strip(put(probchisq,6.4));
 num=&num.;
 ord1 = &num.;
 v1=&lbl.;
 end;
 if ord1 ne .;
 keep v: ord1;
run;

%mend;

%mml (var=%str(AGE1),    dsout=fq1, num=1.2, lbl="65 - 74");
%mml (var=%str(AGE2),  dsout=fq2, num=1.3, lbl=">=75");
%mml (var=%str(GEN0),  dsout=fq3, num=2.1, lbl="Female");
%mml (var=%str(RACE2),  dsout=fq4, num=3.2, lbl="Black/African American");
%mml (var=%str(RACE3),  dsout=fq5, num=3.3, lbl="Other");
%mml (var=%str(EDU0),  dsout=fq6, num=4.2, lbl="High School of Less");
%mml (var=%str(INC0),  dsout=fq7, num=5.2, lbl="<=20,000");
%mml (var=%str(FST0),  dsout=fq8, num=6.2, lbl="Yes");
%mml (var=%str(TRUST),  dsout=fq9, num=7.2, lbl="Trust Score");
%mml (var=%str(PAM_SUM),  dsout=fq10, num=8.2, lbl="PAM Score");
%mml (var=%str(SOCSUPPORT),  dsout=fq11, num=9.2, lbl="Social Support Score");


data dummy;
length v1 $ 200;
 v1 = 'Age Category';              ord1=1; grpord=0; output;
 v1 = 'Gender';                    ord1=2; grpord=0; output;
 v1 = 'Race';                      ord1=3; grpord=0; output;
 v1 = 'Education';                 ord1=4; grpord=0; output;
 v1 = 'Income';                    ord1=5; grpord=0; output;
 v1 = 'Financialstrain';           ord1=6; grpord=0; output;
 v1 = 'Trust Score';               ord1=7; grpord=0; output;
 v1 = 'Patient Activation Measure sum score';  ord1=8; grpord=0; output;
 v1 = 'Social support sum score';  ord1=9; grpord=0; output; 
 run;

Data dumm2;
length V1 $ 200;
v1='<65'; v2='Reference'; ord1=1.1; output;
v1='Male'; v2='Reference'; ord1=2.1; output;
v1='White'; v2='Reference'; ord1=3.1; output;
v1='Greater than High School'; v2='Reference'; ord1=4.1; output;
v1='>20,000'; v2='Reference'; ord1=5.1; output;
v1='No'; v2='Reference'; ord1=6.1; output;
run;
 
data fqfnl;
 set fq:;
run;

data final;
 set dummy dumm2 fqfnl;
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

**********;

options nonumber nodate papersize = A4 orientation = portrait;
ods escapechar="^";
ods rtf path="/home/u57872820/sasuser.v94" file="Logistic Regression for SDM using median value.rtf";
proc report data = final1 split = "|"
style(report)={rules=cols cellspacing=2 cellpadding=2}
style(header)={background=white borderbottomwidth=0.75pt}
style(column)={asis=on};
columns ("Table |Logistic Regression Model for SDM Using Medain Value"
ord1 grpord v1 v2 v3 v4);
 
define ord1 /order order=internal noprint;
define grpord / order=internal noprint;
define v1 /display style(column)={cellwidth=340pt} "Parameter";
define v2 /display center style(column)={cellwidth=50pt} "OR";
define v3 /display center style(column)={cellwidth=70pt} "CI";
define v4 /display center style(column)={cellwidth=60pt} "P-value";

compute grpord;
 if grpord = 0 then call define(_row_,"style","style={bordertopwidth=0.75pt}");
 if grpord = 0 then call define(_col_,"style","style={font_weight=bold}");
endcomp;

compute after _page_ /style={bordertopwidth=0.75pt font_size=9.5pt};
 line @1 "Abbreviation: OR=Odds Ratio, CI=Confidence Interval";
 line @1 "Only non missing value were included";
 line @1 "Dependent variable, SDM scores (event='SDM Score >26')";
endcomp;
run;
ods rtf close;

***End*************;