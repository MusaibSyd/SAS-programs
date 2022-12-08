libname abc "/home/u57872820/sasuser.v94";

proc datasets library=WORK kill nolist; run; quit;


data tot_;
 set abc.ad4;
 if group not in ("." "Kobany" " ");
run;



%macro reg (dsout=, var=, var1=, lbl=, ord1=);

proc sort data=tot_ nodupkey out=tot; by idno group; 
where &var1. not in ('.' '');
run;


ods output ParameterEstimates=pecat OddsRatios=orcat;
proc logistic data=tot;
class  &var.  / param=ref;
model caries (event='Yes') = &var1./ selection=stepwise slentry=1 slstay=1;
run;
quit;

data orcat_;
 length variable $ 40.;
 set orcat;
 variable=scan(effect,1,'');
 drop effect;
run;

proc sort data=orcat_ out=orcat2; by variable;  run;
proc sort data=pecat out=pecat2(keep= variable probchisq) ; by variable; 
where variable ^= 'Intercept';
run;

data all;
 merge orcat2(in=a) pecat2(in=b);
 by variable;
run;

proc sort; by variable;  run;

data &dsout.;
 set all;
  length v1-v4  $ 200.;
 if variable="&var1." then do; v1=&lbl.; ord1=&ord1.; grpord=0;end;
 v2=strip(put(oddsratioest,11.2));
 v3=strip(put(lowercl,11.3))||' - '||strip(put(uppercl,11.3));
 if probchisq= <.0001 then v4='<.0001';
 else v4=strip(put(probchisq,11.4));
 keep v: ord1 grpord;
run;

proc sort; by ord1; run;

%mend;

%reg (dsout=bv0, var=%str(group(ref='Afrin')), var1=group, lbl='Caries (Ref=Afrin)', ord1=0);
%reg (dsout=bv1, var=%str(agec_(ref='7 - 10')), var1=agec_, lbl='Age (Ref=7 - 10)', ord1=1);
%reg (dsout=bv2, var=%str(_gen_(ref='Boy')), var1=_gen_, lbl='Gender (Ref=Boy)', ord1=2);
%reg (dsout=bv3, var=%str(ging_(ref='No')), var1=ging_, lbl='Gingival Inflammation(Ref=No)', ord1=3);
%reg (dsout=bv4, var=%str(plqlyn(ref='No')), var1=plqlyn, lbl='Plaque (Ref=No)', ord1=4);
%reg (dsout=bv5, var=%str(tb1(ref='Yes')),   var1=tb1, lbl='Tooth Brush(Ref=Yes)', ord1=5);
%reg (dsout=bv6, var=%str(inf1(ref='No')), var1=inf1, lbl='Infection (Ref=No)', ord1=6);
%reg (dsout=bv7, var=%str(cs_(ref='<= 2 Times a Week')), var1=cs_, lbl='Candies and Sweet (Ref= <= 2 Times a Week)', ord1=7);
%reg (dsout=bv8, var=%str(sds_(ref='<= 2 Times a Week')), var1=sds_, lbl='Sugardrinks and Soda (Ref= <= 2 Times a Week)', ord1=8);
%reg (dsout=bv9, var=%str(sitm1 (ref='No')), var1=sitm1, lbl='Sugar in Tea and Milk (Ref=No)', ord1=9);


data fnl;
 set bv:;
run;

proc sort; by ord1; run;

proc sql noprint;
	  select count(distinct idno) into :n1 from tot;
quit;

**********;

options nonumber nodate papersize = A4 orientation = portrait;
ods escapechar="^";
ods rtf path="/home/u57872820/sasuser.v94" file="Logistic Regression Bivariate Dental_Caries.rtf";
proc report data = fnl split = "|"
style(report)={rules=cols cellspacing=2 cellpadding=2}
style(header)={background=white borderbottomwidth=0.75pt}
style(column)={asis=on};
columns ("Table |Logistic Regression Bivariate, Dental Caries)"
 ord1 grpord v1 v2 v3 v4);
 
define ord1 /order order=internal noprint;
define grpord /order order=internal noprint;
define v1 /display style(column)={cellwidth=340pt} " ";
define v2 /display center style(column)={cellwidth=40pt} "Odds Ratio";
define v3 /display center style(column)={cellwidth=80pt} "Confidence Interval";
define v4 /display center style(column)={cellwidth=60pt} "P-value";

compute grpord;
 if grpord = 0 then call define(_row_,"style","style={bordertopwidth=0.75pt}");
 if grpord = 0 then call define(_col_,"style","style={font_weight=bold}");
endcomp;

compute after _page_ /style={bordertopwidth=0.75pt font_size=9.5pt};
 line @1 "Abbreviation: OR=Odds Ratio, CI=Confidence Interval";
 line @1 "Dental Caries used as dependent variable";
 
endcomp;
run;
ods rtf close;

***End*************;

