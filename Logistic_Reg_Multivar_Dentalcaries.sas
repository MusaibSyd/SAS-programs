libname abc "/home/u57872820/sasuser.v94";

proc datasets library=WORK kill nolist; run; quit;

data tot_;
 set abc.ad4;
 if group in ('Khanik' 'Afrin');
run;

proc sort data=tot_ out=tot; by group; 
where group ne '.' and _gen_ not in ('.' '') and agec_ not in ('.' '');
run;


ods output ParameterEstimates=pe01 OddsRatios=or01;
proc logistic data=tot;
class _gen_(ref='Boy') agec_(ref='7 - 10') group(ref='Afrin') cs_(ref='<= 2 Times a Week')
tb1(ref='Yes') plqlyn(ref='No') ging_(ref='No') inf1(ref='No') sitm1 (ref='No') sds_(ref='<= 2 Times a Week')/ param=ref;
model caries(event='Yes') = group _gen_ agec_ plqlyn tb1 ging_ cs_ sds_ sitm1/*group*_gen_*agec_*plqlyn*//selection=stepwise slentry=1 slstay=1;
run;
quit;

data or02;
set or01;
length cat $200;
variable=strip(scan(effect,1,''));
drop effect;
run;

proc sort data=or02; by variable; run;

proc sort data=pe01 out=pe02(keep= variable probchisq classval0 rename=(classval0=cat)) ; by variable; 
where variable ^= 'Intercept';
run;

data all;
 merge or02(in=a) pe02(in=b);
 by variable;
 if a and b;
 length var $200;
 var=variable;
run;

proc sort; by var;  run;

%macro mml (var=, dsout=, num=, lbl=);

data &dsout.;
 length v1-v4 $ 200.;
 set all;
 if upcase(var)="&var" then do;
 v2=strip(put(oddsratioest,11.2));
 v3=strip(put(lowercl,11.3))||' - '||strip(put(uppercl,11.3));
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


%mml (var=AGEC_,  dsout=fq1, num=1.2, lbl="11 - 16");
%mml (var=_GEN_,    dsout=fq2, num=2.2, lbl="Girl");
%mml (var=GROUP,  dsout=fq3, num=3.2, lbl="Khanik");
%mml (var=GING_,  dsout=fq4, num=4.2, lbl="Yes");
%mml (var=PLQLYN,  dsout=fq5, num=5.2, lbl="Yes");
%mml (var=TB1,  dsout=fq6, num=6.2, lbl="No");
%mml (var=CS_,  dsout=fq7, num=7.2, lbl="Yes");
%mml (var=SDS_,  dsout=fq8, num=8.2, lbl="Yes");



data dummy;
length v1 $ 200;
 v1 = 'Age (Year)';                  ord1=1; grpord=0; output;
 v1 = 'Sex, n (%)';                  ord1=2; grpord=0; output; 
 v1 = 'Location, n (%)';                  ord1=3; grpord=0; output; 
 v1 = 'Gingiva Inflammation, n (%)';    ord1=4; grpord=0; output;
 v1 = 'Plaque, n (%)';                ord1=5; grpord=0; output;
 v1 = 'Toothbrush, n (%)';                  ord1=6; grpord=0; output;
 v1 = 'Candies and Sweet Frequency, n (%)'; ord1=7; grpord=0; output;
 v1 = 'Sugardrinks and Soda, n (%)';        ord1=8; grpord=0; output;

run;
Data dumm2;
length v1 $ 200;
v1='7 - 10'; v2='Reference'; ord1=1.1; output;
v1='Boy'; v2='Reference'; ord1=2.1; output;
v1='Afrin'; v2='Reference'; ord1=3.1; output;
v1='No'; v2='Reference'; ord1=4.1; output;
v1='No'; v2='Reference'; ord1=5.1; output;
v1='Yes'; v2='Reference'; ord1=6.1; output;
v1='No'; v2='Reference'; ord1=7.1; output;
v1='No'; v2='Reference'; ord1=8.1; output;
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

proc sql noprint;
	  select count(distinct idno) into :n1 from tot;
quit;

**********;

options nonumber nodate papersize = A4 orientation = portrait;
ods escapechar="^";
ods rtf path="/home/u57872820/sasuser.v94" file="Multivariable Logistic Regression Model for Dental Caries in Campus.rtf";
proc report data = final1 split = "|"
style(report)={rules=cols cellspacing=2 cellpadding=2}
style(header)={background=white borderbottomwidth=0.75pt}
style(column)={asis=on};
columns ("Table |Multivariate Logistic Regression Model for Dental Caries in Campus"
ord1 grpord v1 v2 v3 v4);
 
define ord1 /order order=internal noprint;
define grpord / order=internal noprint;
define v1 /display style(column)={cellwidth=340pt} "Parameter";
define v2 /display center style(column)={cellwidth=40pt} "Odds Ratio";
define v3 /display center style(column)={cellwidth=80pt} "Confidence Interval";
define v4 /display center style(column)={cellwidth=60pt} "P-value";

compute grpord;
 if grpord = 0 then call define(_row_,"style","style={bordertopwidth=0.75pt}");
 if grpord = 0 then call define(_col_,"style","style={font_weight=bold}");
endcomp;

compute after _page_ /style={bordertopwidth=0.75pt font_size=9.5pt};
 line @1 "Abbreviation: OR=Odds Ratio, CI=Confidence Interval";
 
endcomp;
run;
ods rtf close;

***End*************;