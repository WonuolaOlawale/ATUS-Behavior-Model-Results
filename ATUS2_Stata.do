* Begin 4-task econometric and behavioral analysis on 2003-18 multiyear ATUS data files 
* Author: Opeoluwa Wonuola Olawale
* Start date: January 29, 2021
* Notes: Consider categories, categorical variables in predictive models, standardize variables, normative ordering using beta standardized coefficients, random forest models, and LASSO regression.
* Set directory and open log file
cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSrestart.log, append


* Import ATUS ACT file
import delimited "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusact_0318.dat"
* Run atusact_0318.do to implement label description
* Save original as act_0318.dta
save act_0318.dta, replace
* Keep variables of interest and save as actdata.dta
keep tucaseid tuactivity_n tuactdur24 tustarttim tustoptime trcodep trtier1p trtier2p tucumdur24 tewhere tudurstop
save actdata.dta, replace

clear
* Import ATUS CPS file
import delimited "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atuscps_0318.dat"
* keep only respondents above age 15 with TULINENO = 1 as they are the respondents with ATUS
keep if tulineno==1
keep if prtage>=15
keep tucaseid tulineno gediv gereg gestfips gtcbsa gtco hefaminc hehousut hetelhhd hetenure hrhtype hubus hufaminc pecyc prcitshp prcowpg tubwgt
save cpsdata.dta, replace

sysuse cpsdata, clear
* Run label description from atuscps_0318.do file
save cpsdata.dta, replace

clear
* Import ATUS SUMM file
import delimited "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atussum_0318.dat"
save sum_0318.dta
* Run line 463 to 469, tesex, teage, and telfs from the atussum_0318.do file to create labels
* Keep intended variables and save as summdata.dta
keep tucaseid gemetsta gtmetsta peeduca pehspnon ptdtrace teage telfs tesex
save summdata, replace

* Import ATUS RESP file
import delimited "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusresp_0318.dat", clear
save resp_0318.dta
* Run label description from atusres_0318.do file 
* Keep intended variables and save as respdata.dta
keep tucaseid teern teernhro teernhry tehruslt teio1cow teio1icd teschenr trchildnum trdpftpt trhhchild trnumhou trtalone tryhhchild tudiarydate tudiaryday tumonth tuyear trholiday tufnwgtp 
save respdata, replace

*Merge data on activity data using tucaseid
* Merge actdata with cpsdata
merge m:m tucaseid using "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cpsdata.dta"
    Result                           # of obs.
    -----------------------------------------
    not matched                       212,154
        from master                         0  (_merge==1)
        from using                    212,154  (_merge==2)

    matched                         3,938,303  (_merge==3)
    -----------------------------------------

* Assess merged data
distinct tucaseid

---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |   4150457     413305
---------------------------------
drop if missing(trcodep)
(212,154 observations deleted)

---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |   3938303     201151
---------------------------------

* Save merged actcps Merge2
save actcps, replace
drop _merge 

*Now merge 2 with respdata Merge3
merge m:m tucaseid using "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\respdata.dta"
drop _merge
save actcpsresp, replace

*Now merge 2 with summdata
merge m:m tucaseid using "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\summdata.dta"
drop _merge
save newdata, replace

* Use Blank -1, Don't know -2, and Refused -3 to generate missing values
mvdecode tucaseid tuactivity_n tuactdur24 tustarttim tustoptime trcodep trtier1p trtier2p tucumdur24 tewhere tudurstop tulineno gediv gereg gestfips gtcbsa gtco hefaminc hehousut hetelhhd hetenure hrhtype hubus hufaminc pecyc prcitshp prcowpg tubwgt trhhchild trnumhou trtalone tuyear teern teernhro teernhry teio1cow teio1icd tumonth tudiarydate trchildnum tudiaryday trholiday trdpftpt tufnwgtp teschenr tehruslt tryhhchild gemetsta gtmetsta peeduca pehspnon ptdtrace teage telfs tesex, mv(-1 -2 -3 -4)
  
  tustarttim: string variable ignored
  tustoptime: string variable ignored
     tewhere: 723464 missing values generated
   tudurstop: 2686168 missing values generated
       gediv: 2909415 missing values generated
      gtcbsa: 579085 missing values generated
        gtco: 579085 missing values generated
    hefaminc: 2040989 missing values generated
    hetenure: 3691 missing values generated
       hubus: 3765 missing values generated
    hufaminc: 2161342 missing values generated
       pecyc: 2866422 missing values generated
     prcowpg: 1567714 missing values generated
      tubwgt: 383997 missing values generated
       teern: 3787844 missing values generated
    teernhro: 3121261 missing values generated
    teernhry: 1753088 missing values generated
    teio1cow: 1474580 missing values generated
    teio1icd: 1474580 missing values generated
    trdpftpt: 1474623 missing values generated
    teschenr: 1668103 missing values generated
    tehruslt: 1474623 missing values generated
  tryhhchild: 2026982 missing values generated
    gemetsta: 3359218 missing values generated
    gtmetsta: 579085 missing values generated

* Generate income from hufaminc and hefaminc
gen income = hufaminc if hefaminc==.
replace income = hefaminc if hufaminc==.
tab income, missing
distinct tucaseid if income==.
// 6.7% of the 3,938,303 observations or 6.8% of the 201501 respondents are missing income values

label variable income "Annual family income"
label values income labelhufaminc

* Generate metropolitan status from gtmetsta and gemetsta
gen metsta = gtmetsta if gemetsta==.
replace metsta = gemetsta if gtmetsta==.
tab metsta, missing
distinct tucaseid if metsta==.
// No more missing values

label define labelgemetsta -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Metropolitan" 2 "Non-metropolitan" 3 "Not identified"
label variable metsta "Metropolitan status"
label values metsta   labelgemetsta
distinct tucaseid if metsta==3

---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     27478       1411
---------------------------------
recode metsta 1=1 2=0 3=0
label define labelmetsta 0 "Non-metropolitan" 1 "Metropolitan" 
label values metsta   labelmetsta

save newdata2, replace

* Drop variables that do not add to the dataset
drop tulineno hefaminc hufaminc tubwgt pecyctudiarydate
label variable tubwgt "ATUS base weight" 
label variable pecyc "Edited: how many years of college credit have you completed?" 

* Preprocessing variable labels
label define labelgestfips 1 "AL" 2 "AK" 4 "AZ" 5 "AR" 6 "CA" 8 "CO" 9 "CT" 10 "DE" 11 "DC" 12 "FL" 13 "GA" 15 "HI" 16 "ID" 17 "IL" 18 "IN" 19 "IA" 20 "KS" 21 "KY" 22 "LA" 23 "ME" 24 "MD" 25 "MA" 26 "MI" 27 "MN" 28 "MS" 29 "MO" 30 "MT" 31 "NE" 32 "NV" 33 "NH" 34 "NJ" 35 "NM" 36 "NY" 37 "NC" 38 "ND" 39 "OH" 40 "OK" 41 "OR" 42 "PA" 44 "RI" 45 "SC" 46 "SD" 47 "TN" 48 "TX" 49 "UT" 50 "VT" 51 "VA" 53 "WA" 54 "WV" 55 "WI" 56 "WY" 
label values gestfips labelgestfips

* Reoder the variables listing
order tucaseid tufnwgtp tuactdur24 choice trcodep trtier1p trtier2p tewhere tustarttim tustoptime tuactivity_n tucumdur24 tesex teage telfs peeduca income pehspnon ptdtrace prcitshp, first

* Check summary statistics, determine variables to drop and variables to be used as grouping variables, reflect changes made and save as finaldata


* Curiosity on the effect of dropping missing values or using a subset
sysuse newdata2, clear
ssc install benford, replace
benford tufnwgtp
benford tufnwgtp if income<.
benford tufnwgtp if income<. & gtco<.
* the weighting data without the missing values show less than 0.8% deviation from that of the whole dataset
benford tuactdur24 
benford tuactdur24 if income<.
benford tuactdur24 if income<. & gtco<.
* Similar Benfordness across the variables despite dropping missing values

* Try weighted average of some variables
tabulate income, summarize(income)
	Total |    10.76733   3.9899869   3,674,275

tabulate income [aweight = tufnwgtp], summarize(income)
	income |        Mean   Std. Dev.       Freq.        Obs.
	 Total |   11.095063   3.8897035   2.592e+13   3,674,275

tabulate income [aweight = tufnwgtp] if income<., summarize(income)
	 Total |   11.095063   3.8897035   2.592e+13   3,674,275

tabulate teage, summarize(teage)
      Total |   47.118978   17.467758   3,938,303

tabulate teage if income<., summarize(teage)
      Total |   46.900124    17.37999   3,674,275

tabulate teage if income<. & gtco<., summarize(teage)
      Total |   47.195915   17.464546   3,165,368

tabulate teage [aweight = tufnwgtp], summarize(teage)
      Total |   44.831212   18.224467   2.764e+13   3,938,303
	  
tabulate teage [aweight = tufnwgtp] if income<., summarize(teage)
      Total |   44.629222   18.138369   2.592e+13   3,674,275
	  
tabulate teage [aweight = tufnwgtp] if income<. & gtco<., summarize(teage)
	  Total |   44.780604   18.199436   2.366e+13   3,165,368
	  
tabulate tuactdur24 [aweight = tufnwgtp] if trtier1p==1, summarize(tuactdur24)
tabulate tuactdur24 [aweight = tufnwgtp] if trtier1p==1 & income<., summarize(tuactdur24)
tabulate tuactdur24 [aweight = tufnwgtp] if trtier1p==1 & income<. & gtco<., summarize(tuactdur24)

      Total |    731,775      100.00
      Total |    681,936      100.00
	  Total |    590,323      100.00
	  
distinct tucaseid
distinct tucaseid if income<.
distinct tucaseid if income<. & gtco<.


          |     total   distinct
----------+----------------------
 tucaseid |   3938303     201151
---------------------------------
 tucaseid |   3674275     187453
---------------------------------
 tucaseid |   3165368     162097
---------------------------------

* Define weekday, season, choice, categories redefined and timing of activity
recode tudiaryday 1=1 2/6=0 7=1, gen(weekend)
* Recall 1 - Sunday, 2/6 - Monday to Friday, and 7 - Saturday
label define labelweekend 0 "weekday" 1 "weekend"
label values weekend labelweekend
label variable weekend "Weekend or weekday"

* https://www.eia.gov/todayinenergy/detail.php?id=4190
* Seasons interpretation to months
* I'm considering using similar season classification as used in ResStock modeling: shoulder, winter, and summer but noticed it was done using outdoor temperature cutoffs (the QOI document). I was trying to do this approximately by using months such that shoulder season would be roughly March to April and September-October while winter will be November - February and summer will be May to August.  I'm a bit hesitant because most of my searches take me to flight-related or natural gas seasons and may not exactly reflect electricity stance. The EIA article from 2011 was kind of helpful.
recode tumonth 1/2=1 11/12=1 3/4=2 9/10=2 5/8=3, gen(season)
label define labelseason 1 "winter" 2 "shoulder" 3 "summer"
label values season labelseason
label variable season "Season of the year"

label variable teernhry "Hourly/non-hourly status"
label variable teio1cow "Individual class of worker code (main job)"
label variable teio1icd "Industry code (main job)"
label variable teschenr "Are you enrolled in high school, college, or university?"
label variable tehruslt "Total hours usually worked per week (sum of TEHRUSL1 and TEHRUSL2)"
label variable teern "Total weekly overtime earnings (2 implied decimals)"
label variable teernhro "How many hours do you usually work per week at this rate?"
label variable hehousut "Type of housing unit"
label variable hetelhhd "Is there a telephone in this house/apartment?"
label variable hetenure "Are your living quarters owned, rented for cash, or occupied without pay"
label variable pehspnon "Are you Spanish, Hispanic, or Latino?"
label variable peeduca "Highest level of school you have completed or highest degree received?"
label variable tewhere "Where were you during the activity?"
label variable tesex "Gender"
label variable teage "Age"
label variable telfs "Labor force status"
label define labeltelfs -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Employed - at work" 2 "Employed - absent" 3 "Unemployed - on layoff" 4 "Unemployed - looking" 5 "Not in labor force"
label values telfs labeltelfs
label define labelpeeduca -1 "Blank" -2 "Don't Know" -3 "Refused" 31 "Less than 1st grade" 32 "1st, 2nd, 3rd, or 4th grade" 33 "5th or 6th grade" 34 "7th or 8th grade" 35 "9th grade" 36 "10th grade" 37 "11th grade" 38 "12th grade - no diploma" 39 "High school graduate - diploma or equivalent (GED)" 40 "Some college but no degree" 41 "Associate degree - occupational/vocational" 42 "Associate degree - academic program" 43 "Bachelor's degree (BA, AB, BS, etc.)" 44 "Master's degree (MA, MS, MEng, MEd, MSW, etc.)" 45 "Professional school degree (MD, DDS, DVM, etc.)" 46 "Doctoral degree (PhD, EdD, etc.)"
label values peeduca labelpeeduca
label define labeltesex 1 "Male" 2 "Female"
recode tesex 1=0 2=1
label define labeltesex 0 "Male" 1 "Female", replace
label values tesex labeltesex
label define labelprcitshp -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Native, born in United States" 2 "Native, born in Puerto Rico or U.S. Outlying Area" 3 "Native, born abroad of American parent or parents" 4 "Foreign born, U.S. citizen by naturalization" 5 "Foreign born, not a U.S. citizen"  
label values prcitshp labelprcitshp

label define labelgediv -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "New England" 2 "Middle Atlantic" 3 "East North Central" 4 "West North Central" 5 "South Atlantic" 6 "East South Central" 7 "West South Central" 8 "Mountain" 9 "Pacific"
label variable gediv "Division" 
label values gediv labelgediv

label values pehspnon labelpehspnon
label define labelpehspnon -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Hispanic" 2 "Non-Hispanic"   
recode pehspnon 1=1 2=0
label define labelpehspnon 1 "Hispanic" 0 "Non-Hispanic", replace

label values ptdtrace   labelptdtrace
label define labelptdtrace -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "White only" 2 "Black only" 3 "American Indian, Alaskan Native only" 4 "Asian only" 5 "Hawaiian/Pacific Islander only" 6 "White-Black" 7 "White-American Indian" 8 "White-Asian" 9 "White-Hawaiian" 10 "Black-American Indian" 11 "Black-Asian" 12 "Black-Hawaiian" 13 "American Indian-Asian" 14 "Asian-Hawaiian or American Indian-Hawaiian (beginning 5/2012)" 15 "White-Black-American Indian or Asian-Hawaiian (beginning 5/2012)" 16 "White-Black-Asian or White-Black-American Indian (beginning 5/2012)" 17 "White-American Indian-Asian or White-Black-Asian (beginning 5/2012)" 18 "White-Asian-Hawaiian or White-Black-Hawaiian (beginning 5/2012)" 19 "White-Black-American Indian-Asian or White-American Indian-Asian (beginning 5/2012)" 20 "2 or 3 races or White-American Indian-Hawaiian (beginning 5/2012)" 21 "4 or 5 races or White-Asian-Hawaiian (beginning 5/2012)" 22 "Black-American Indian-Asian (beginning 5/2012)" 23 "White-Black-American Indian-Asian (beginning 5/2012)" 24 "White-American Indian-Asian-Hawaiian (beginning 5/2012)" 25 "Other 3 race combinations (beginning 5/2012)" 26 "Other 4 and 5 race combinations (beginning 5/2012)" 
* https://www.bls.gov/opub/reports/race-and-ethnicity/2018/home.htm
recode ptdtrace 1=1 2=2 3=4 4=3 5=5 6/26=6
label define labelptdtrace 1 "White" 2 "Black or African American" 3 "Asian" 4 "American Indian and Alaska Native" 5 "Native Hawaiian and Other Pacific Islander" 6 "Two or More Races", replace

label define labeltudurstop -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Activity duration was entered" 2 "Activity stop time was entered"   
label values tudurstop labeltudurstop
recode tudurstop 1=0 2=1
label define labeltudurstop 0 "Activity duration was entered" 1 "Activity stop time was entered", replace

label define labelhetelhhd -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Yes" 2 "No"  
label values hetelhhd labelhetelhhd
recode hetelhhd 1=1 2=0
label define labelhetelhhd 1 "Yes" 0 "No telephone", replace  

label define labelhubus -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Yes" 2 "No"   
label variable hubus "Does anyone in this household have a business or a farm?" 
label values hubus labelhubus
recode hubus 1=1 2=0
label define labelhubus 1 "Yes" 0 "No business or farm", replace  

label define labelprcowpg -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Private" 2 "Government" 
label variable prcowpg "Class of worker - private or government" 
label values prcowpg labelprcowpg
recode prcowpg 1=1 2=0
label define labelprcowpg 1 "Private" 0 "Government", replace 

label define labeltrhhchild -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Yes" 2 "No"  
label variable trhhchild "Presence of household children < 18"
label values trhhchild labeltrhhchild
recode trhhchild 1=1 2=0
label define labeltrhhchild 1 "Yes" 0 "No HH children < 18", replace  

label values teernhry labelteernhry
label define labelteernhry -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Paid hourly" 2 "Not paid hourly"  
recode teernhry 1=1 2=0
label define labelteernhry 1 "Paid hourly" 0 "Not paid hourly", replace

label variable trdpftpt "Full time or part time employment status of respondent"
label values trdpftpt labeltrdpftpt
label define labeltrdpftpt -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Full time" 2 "Part time" 
recode trdpftpt 1=1 2=0
label define labeltrdpftpt 1 "Full time" 0 "Part time", replace

label define labelteschenr -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Yes" 2 "No" 
label variable teschenr "Edited: are you enrolled in high school, college, or university?"
label variable teschenr "Enrolled in high school, college, or university?"
recode teschenr 1=1 2=0
label define labelteschenr 1 "Student" 0 "Not student", replace 

recode peeduca 31/38=1 39=2 40=3 41/43=4 44/46=5
label define labelpeeduca 1 "< High school" 2 "High school" 3 "Some college - no degree" 4 "College or associate degree" 5 "Post graduate", replace


* https://www.payingforseniorcare.com/federal-poverty-level
* Using the average number of people in the household as approximately 3
recode income 1/7=1 8/13=2 14/16=3, gen(income2)
label define Income2 1 "Low income <$25,000" 2 "Mid-income $25,000 to $74,999" 3 "High income >$75,000"
label variable income2 "Assumed family income levels"
label values income2 Income2

* Taking the hard route
label define labelhufaminc -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Less than $5,000" 2 "$5,000 to $7,499" 3 "$7,500 to $9,999" 4 "$10,000 to $12,499" 5 "$12,500 to $14,999" 6 "$15,000 to $19,999" 7 "$20,000 to $24,999" 8 "$25,000 to $29,999" 9 "$30,000 to $34,999" 10 "$35,000 to $39,999" 11 "$40,000 to $49,999" 12 "$50,000 to $59,999" 13 "$60,000 to $74,999" 14 "$75,000 to $99,999" 15 "$100,000 to $149,999" 16 "$150,000 and over"  
label variable trnumhou "Number of people living in respondent's household"

recode income 1=4999 2=7499 3=9999 4=12499 5=14999 6=19999 7=24999 8=29999 9=34999 10=39999 11=49999 12=59999 13=74999 14=99999 15=149999 16=150000, gen(proxinc) 
* Use Table A-4 in https://www.census.gov/content/dam/Census/library/publications/2020/demo/p60-270.pdf to generate upper bound for level 16
recode proxinc 150000=214753 if tuyear==2003
recode proxinc 150000=213217 if tuyear==2004
recode proxinc 150000=217842 if tuyear==2005
recode proxinc 150000=221187 if tuyear==2006
recode proxinc 150000=218780 if tuyear==2007
recode proxinc 150000=214259 if tuyear==2008
recode proxinc 150000=215008 if tuyear==2009
recode proxinc 150000=212087 if tuyear==2010
recode proxinc 150000=211888 if tuyear==2011
recode proxinc 150000=213245 if tuyear==2012
recode proxinc 150000=215457 if tuyear==2013
recode proxinc 150000=223293 if tuyear==2014
recode proxinc 150000=231427 if tuyear==2015
recode proxinc 150000=239975 if tuyear==2016
recode proxinc 150000=254568 if tuyear==2017
recode proxinc 150000=253234 if tuyear==2018


label variable trnumhou "Number of people living in respondent's household"

gen povlevel =  proxinc/trnumhou
summarize povlevel

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    povlevel |  3,674,275    29251.77    24589.61      499.9     150000

* at 100% poverty level meaning low income
gen incomelevl = 1  if povlevel<=12760 & trnumhou==1
replace incomelevl = 1  if povlevel<=8620 & trnumhou==2
replace incomelevl = 1  if povlevel<=7240 & trnumhou==3
replace incomelevl = 1  if povlevel<=6550 & trnumhou==4
replace incomelevl = 1  if povlevel<=6136 & trnumhou==5
replace incomelevl = 1  if povlevel<=5860 & trnumhou==6
replace incomelevl = 1  if povlevel<=5662 & trnumhou==7
replace incomelevl = 1  if povlevel<=5515 & trnumhou==8
replace incomelevl = 1  if povlevel<=4480 & trnumhou>8
* at 300% poverty level meaning high income
replace incomelevl = 3  if povlevel>=38280 & trnumhou==1
replace incomelevl = 3  if povlevel>=25860 & trnumhou==2
replace incomelevl = 3  if povlevel>=21720 & trnumhou==3
replace incomelevl = 3  if povlevel>=19650 & trnumhou==4
replace incomelevl = 3  if povlevel>=18408 & trnumhou==5
replace incomelevl = 3  if povlevel>=17580 & trnumhou==6
replace incomelevl = 3  if povlevel>=16989 & trnumhou==7
replace incomelevl = 3  if povlevel>=16545 & trnumhou==8
replace incomelevl = 3  if povlevel>=15200 & trnumhou>8
* in between 100% and 300% poverty level meaning mid income
replace incomelevl = 2  if povlevel>12760 & povlevel<38280 & trnumhou==1
replace incomelevl = 2  if povlevel>8620 & povlevel<25860 & trnumhou==2
replace incomelevl = 2  if povlevel>7240 & povlevel<21720 & trnumhou==3
replace incomelevl = 2  if povlevel>6550 & povlevel<19650 & trnumhou==4
replace incomelevl = 2  if povlevel>6136 & povlevel<18408 & trnumhou==5
replace incomelevl = 2  if povlevel>5860 & povlevel<17580 & trnumhou==6
replace incomelevl = 2  if povlevel>5662 & povlevel<16989 & trnumhou==7
replace incomelevl = 2  if povlevel>5515 & povlevel<16545 & trnumhou==8
replace incomelevl = 2  if povlevel>4480 & povlevel<15200 & trnumhou>8
replace incomelevl=.  if povlevel==.

*income label
label define labincomelevel 1 "Low income" 2 "Mid-income" 3 "High income", replace
label variable incomelevl "Family income level according to 2020 poverty guidelines"
label values incomelevl labincomelevel
* sanity checks
summarize income income2 incomelevl
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      income |  3,674,275    10.76733    3.989987          1         16
     income2 |  3,674,275    2.098181      .73382          1          3
  incomelevl |  3,938,303    2.356721    .7097747          1          3

tab povlevel, missing
replace incomelevl=.  if povlevel==.
summarize income income2 incomelevl
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      income |  3,674,275    10.76733    3.989987          1         16
     income2 |  3,674,275    2.098181      .73382          1          3
  incomelevl |  3,674,275    2.310496    .7128174          1          3

summarize income income2 incomelevl [aweight = tufnwgtp]

    Variable |     Obs      Weight        Mean   Std. Dev.       Min        Max
-------------+-----------------------------------------------------------------
      income | 3674275  2.5918e+13    11.09506   3.889703          1         16
     income2 | 3674275  2.5918e+13    2.152138   .7235276          1          3
  incomelevl | 3674275  2.5918e+13    2.329033   .7081581          1          3

// gen incomelevl = 1  if income<5 & trnumhou<=1
// replace incomelevl = 1  if income<6 & trnumhou==2
// replace incomelevl = 1  if income<=7 & trnumhou==3
// replace incomelevl = 1  if income<=8 & trnumhou==4
// replace incomelevl = 1  if income<=9 & trnumhou==5
// replace incomelevl = 1  if income<=10 & trnumhou==6
// replace incomelevl = 1  if income<=11 & trnumhou==7
// replace incomelevl = 1  if income<=12 & trnumhou==8
// replace incomelevl = 1  if income<6 & trnumhou>8

label define labelhehousut -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "House, apartment, flat" 2 "Housing unit in nontransient hotel, motel, etc." 3 "Housing unit permanent in transient hotel, motel" 4 "Housing unit in rooming house" 5 "Mobile home or trailer with no permanent room added" 6 "Mobile home or trailer with 1 or more rooms added" 7 "Housing unit not specified above" 8 "Quarters not housing unit in rooming/boarding house" 9 "Unit not permanent in transient hotel/motel" 10 "Unoccupied tent site or trailer site" 11 "Student quarters in college dorm" 12 "Other unit not specified above"  
label variable hehousut "Edited: type of housing unit" 
label values hehousut labelhehousut
recode hehousut 1=1 2/4=2 5/6=3 7/10=4 11=5 12=6
label define labelhehousut 1 "House, apartment, flat" 2 "Multi-tenant housing unit" 3 "Mobile home" 4 "Unpopular housing unit" 5 "Student quarters in college dorm" 6 "Other unit not specified", replace

label define labelhrhtype -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Husband/wife primary family (neither Armed Forces)" 2 "Husband/wife primary family (either/both Armed Forces)" 3 "Unmarried civilian male - primary family householder" 4 "Unmarried civilian female - primary family householder" 5 "Primary family householder - respondent in Armed Forces, unmarried" 6 "Civilian male primary individual" 7 "Civilian female primary individual" 8 "Primary individual householder - respondent in Armed Forces" 9 "Group quarters with family" 10 "Group quarters without family" 
label variable hrhtype "Household type" 
label values hrhtype labelhrhtype
* can't think of a better recategorization

label variable teio1cow "Edited: individual class of worker code (main job)"
label values teio1cow labelteio1cow
label define labelteio1cow -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Government, federal" 2 "Government, state" 3 "Government, local" 4 "Private, for profit" 5 "Private, nonprofit" 6 "Self-employed, incorporated" 7 "Self-employed, unincorporated" 8 "Without pay"  
recode teio1cow 1/3=1 4/5=2 6/7=3 8=4, gen(teio1cow2)
label define labelteio1cow2 1 "Government" 2 "Private" 3 "Self-employed" 4 "Without pay" 
label value teio1cow2 labelteio1cow2
label variable teio1cow2 "Type of worker (main job)"

* Comparing with labor force status
label variable telfs "Edited: labor force status"
label define labeltelfs -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Employed - at work" 2 "Employed - absent" 3 "Unemployed - on layoff" 4 "Unemployed - looking" 5 "Not in labor force"  

* Save current work now
save newdata2, replace

* location generation*
label define labeltewhere -1 "Blank" -2 "Don't Know" -3 "Refused" 1 "Respondent's home or yard" 2 "Respondent's workplace" 3 "Someone else's home" 4 "Restaurant or bar" 5 "Place of worship" 6 "Grocery store" 7 "Other store/mall" 8 "School" 9 "Outdoors away from home" 10 "Library" 11 "Other place" 12 "Car, truck, or motorcycle (driver)" 13 "Car, truck, or motorcycle (passenger)" 14 "Walking" 15 "Bus" 16 "Subway/train" 17 "Bicycle" 18 "Boat/ferry" 19 "Taxi/limousine service" 20 "Airplane" 21 "Other mode of transportation" 30 "Bank" 31 "Gym/health club" 32 "Post Office" 89 "Unspecified place" 99 "Unspecified mode of transportation"  

recode tewhere 1=1 3=1 2=2 4/21=3 30/32=3 89=3 99=3, gen(location)
label define labellocation 1 "Home" 2 "Workplace" 3 "Not home"
label values location labellocation
label variable location "DF Location"
* checks
distinct tucaseid if location==1

* choice generation
* Sleeping as an activity show that no one specified their location
distinct tucaseid if trtier2p==101

---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |    440776     200934
---------------------------------

distinct tucaseid if trtier2p==101 & tewhere==.

---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |    440776     200934
---------------------------------

distinct tucaseid if trtier2p==101 & tewhere<.
note: no distinct values satisfy specification

* cleaning (6)
distinct tucaseid if location==1 & trcodep==10201 |  trcodep==10299 | trcodep==20101 | trcodep==20399 | trcodep==20401 | trcodep==90101
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     73322      57086
---------------------------------
distinct tucaseid if location==1 & trcodep==10201 | location==1 & trcodep==10299 | location==1 & trcodep==20101 | location==1 & trcodep==20399 | location==1 & trcodep==20401 | location==1 & trcodep==90101

---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     72077      56362
---------------------------------

recode trcodep 10201=1 10299=1 20101=1 20399=1 20401=1 90101=1, gen(cleaning)
distinct tucaseid if location==1 & cleaning==1
distinct tucaseid if location==. & cleaning==1
distinct tucaseid if cleaning==1
distinct tucaseid if location>1 & cleaning==1

* location known for cleaning activities
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     72077      56362
---------------------------------

* missing location values for cleaning
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |    267192     156653
---------------------------------
* location at work or away
distinct tucaseid if location==2 & cleaning==1 | location==3 & cleaning==1

---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |      1121       1037
---------------------------------

* total observations for cleaning
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |    340390     170159
---------------------------------
* Include missing location values for cleaning

* laundry (3)
recode trcodep 20102=1, gen(laundry)
	(52520 differences between trcodep and laundry)
distinct tucaseid if location==1 & laundry==1
distinct tucaseid if location==. & laundry==1
distinct tucaseid if laundry==1
* No missing values for the location of laundry, therefore specify home location
* Expect
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     51367      36359
---------------------------------

* dishwashing (4)
recode trcodep 20203=1, gen(dishwashing)
	(59944 differences between trcodep and dishwashing)
distinct tucaseid if location==1 & dishwashing==1
distinct tucaseid if location==. & dishwashing==1
distinct tucaseid if location>1 & dishwashing==1
distinct tucaseid if dishwashing==1
* No missing location values and some reported being away or at work, therefore specify home location
* Expect
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     59552      46798
---------------------------------

* cooking (5)
recode trcodep 20201=1 20202=1 20299=1 90102=1 150201=1 40501=1, gen(cooking)
	(185067 differences between trcodep and cooking)
distinct tucaseid if location==1 & cooking==1
distinct tucaseid if location==. & cooking==1
distinct tucaseid if location>1 & cooking==1
distinct tucaseid if cooking==1
* No missing location values as well, specify location as well
* Expect
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |    181208     107883
---------------------------------

* yard work (7)
recode trcodep 020501=1 20599=1 90401=1 90402=1 90499=1, gen(yardwork)
	(25620 differences between trcodep and yardwork)
distinct tucaseid if location==1 & yardwork==1
distinct tucaseid if location==. & yardwork==1
distinct tucaseid if location>1 & yardwork==1
distinct tucaseid if yardwork==1
* No missing location value, specify home location
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     25185      20083
---------------------------------

* sport and exercise at home (8)
recode trtier1p 13=1 1/12=0 .=. 14/max=0, gen(exercise)
	(49817 differences between trtier1p and exercise)
distinct tucaseid if location==1 & exercise==1
distinct tucaseid if location==. & exercise==1
distinct tucaseid if location>1 & exercise==1
distinct tucaseid if exercise==1
* only one observation has missing location value, specify home location
* Expect
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     13108      10964
---------------------------------

* Noticed a problem, other trcodep numbers were prevalent
recode cleaning 1=1 .=. 2/max=0
recode laundry 1=1 .=. 2/max=0
recode dishwashing 1=1 .=. 2/max=0
recode cooking 1=1 .=. 2/max=0
recode yardwork 1=1 .=. 2/max=0
* Check if 0 prefix with the number causes issues
list tucaseid location yardwork trcodep in 1/10000 if yardwork==1 & trcodep==20501


* Pool pump use (9)
recode trcodep 020502=1, gen(pooluse)
	(810 differences between trcodep and pooluse)
recode pooluse 1=1 .=. 2/max=0
distinct tucaseid if location==1 & pooluse==1
distinct tucaseid if location==. & pooluse==1
distinct tucaseid if location>1 & pooluse==1
distinct tucaseid if pooluse==1
* No missing location value, specify home location
* Expect
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |       795        704
---------------------------------

* Television/gaming (10)
recode trcodep 120303=1 120304=1 120307=1 , gen(TVgaming)
	(330295 differences between trcodep and TVgaming)
replace TVgaming=1 if trtier2p==1302
	(2,797 real changes made)
recode TVgaming 1=1 .=. 2/max=0
distinct tucaseid if location==1 & TVgaming==1
distinct tucaseid if location==. & TVgaming==1
distinct tucaseid if location>1 & TVgaming==1
distinct tucaseid if TVgaming==1
* only one observation has missing location value, specify home location
* Expect
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |    325110     162477
---------------------------------

* Computer use (11)
recode trcodep 150101=1 120308=1, gen(computeruse) 
	(29358 differences between trcodep and computeruse)
recode computeruse 1=1 .=. 2/max=0
distinct tucaseid if location==1 & computeruse==1
distinct tucaseid if location==. & computeruse==1
distinct tucaseid if location>1 & computeruse==1
distinct tucaseid if computeruse==1
* No missing location value, specify home location
* Expect
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     27823      21596
---------------------------------

* Sleeping (2)
recode trtier2p 101=1, gen(sleeping)
recode sleeping 1=1 .=. 2/max=0
	(440776 differences between trtier2p and sleeping)
distinct tucaseid if location==. & sleeping==1
*All locations are assumed to be at home as none contains location value
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |    440776     200934
---------------------------------

* Travelling (12)
recode trtier1p 18=1 1/17=0 .=. 19/max=0, gen(travelling)
distinct tucaseid if location==1 & travelling==1
distinct tucaseid if location==. & travelling==1
distinct tucaseid if location>1 & travelling==1
distinct tucaseid if travelling==1
* It is expected that you can't be home and travelling. This is a sanity check
* Surprising, it appears that there are some spurious reports of being home and traveling perhaps during their waiting time
* Also, no missising value location for any of the travelling observations
* These are those at home and travelling
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     11123       9409
---------------------------------
* These are travelling and not home
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |    775526     170015
---------------------------------

* Away at work (13)
* Take note to distinguish work location and travelling incidences
distinct tucaseid if location==2
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |    194908      58895
---------------------------------

* Away (14)
distinct tucaseid if location==3

* just home (1)
use location==1 and then override with other activities

* concerns about demographic missing values
distinct tucaseid if location<.
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |   3214839     201151
---------------------------------
distinct tucaseid if location<. & income<.
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |   3000010     187453
---------------------------------
distinct tucaseid if location<. & income<. & gtco<.
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |   2581679     162097
---------------------------------

* Choice outcome variable
gen choice=1 if location==1
replace choice=2 if sleeping==1
replace choice=3 if location==1 & laundry==1
replace choice=4 if location==1 & dishwashing==1
replace choice=5 if location==1 & cooking==1
replace choice=6 if location==1 & cleaning==1
replace choice=6 if location==. & cleaning==1
replace choice=7 if location==1 & yardwork==1
replace choice=8 if location==1 & exercise==1
replace choice=9 if location==1 & pooluse==1
replace choice=10 if location==1 & TVgaming==1
replace choice=11 if location==1 & computeruse==1
replace choice=13 if location==2
replace choice=14 if location==3
replace choice=12 if location>1 & traveling==1
* ? No use as no missing activity values
* replace choice=. if trcodep==.
* check if I couldn't book some activities
distinct tucaseid if choice==.
distinct trcodep if choice==.
* 15,496 observations with not study-relevant choice excluded 
* 11 six-digit activity coded activities as listed below are thus missing
tab trcodep if choice==.
* Good thing I checked. This way I know what was weeded out
     Pooled |
  six-digit |
   activity |
       code |      Freq.     Percent        Cum.
------------+-----------------------------------
      10401 |      2,081       13.43       13.43	No location (Personal activities)
      10499 |         24        0.15       13.58	""	Personal activities
      20902 |          1        0.01       13.59	""	Organization and planning
     110101 |          1        0.01       13.60	""	Eating and drinking
     120301 |          5        0.03       13.63	""	Relaxing, thinking
     120303 |          1        0.01       13.64	""	Television and movie
     130124 |          1        0.01       13.64	""	Running
     140102 |          1        0.01       13.65	""	Religious practice
     500101 |          1        0.01       13.66	Insufficient detail
     500105 |        771        4.98       18.63	Refused
     500106 |     12,609       81.37      100.00	Gap/Can't remember
------------+-----------------------------------
      Total |     15,496      100.00


label variable choice "Activity Choice"
label define labelchoice 1 "Just_home" 2 "Sleeping" 3 "Laundry" 4 "Dishwashing" 5 "Cooking" 6 "Cleaning" 7 "Garden_yard_work" 8 "Exercise" 9 "Pool_pump_use" 10 "TV_Game_use" 11 "Computer_use" 12 "Traveling_commuting" 13 "Away_for_work" 14 "Away", replace
label values choice labelchoice

* create activities column for the remaining activities
recode choice 1=1 2/14=0, gen(justhome)
recode choice 14=1 1/13=0, gen(away)
recode choice 13=1 1/12=0 14=0, gen(awayatwork)

* https://www.canstarblue.com.au/electricity/peak-off-peak-electricity-times/
* https://www.eia.gov/todayinenergy/detail.php?id=42915

* Action period description variable
* Off peak periods on weekends and weekdays between 12 midnight and 7 am
* Critical peak periods between 2 pm and 7 pm
* Create readable time variables
gen double tustarttim2 = clock(tustarttim, "hms")
format tustarttim2 %tcHH:MM:SS_AM
gen double tustoptime2 = clock(tustoptime, "hms")
format tustoptime2 %tcHH:MM:SS_AM
* testing
tab choice if tustarttim2<tc(14:00)
tab choice if weekend==0 & tustarttim2 >= tc(00:00:00) & tustoptime2 <= tc(07:00:00)
tab choice if weekend==0 & tustarttim2 >= tc(07:00:00) & tustoptime2 <= tc(14:00:00)
tab choice if weekend==0 & tustarttim2 >= tc(14:00:00) & tustoptime2 <= tc(19:00:00)
tab choice if weekend==0 & tustarttim2 >= tc(19:00:00) & tustoptime2 <= tc(23:59:59)

gen action=1 if weekend==1
replace action=6 if weekend==0
replace action=2 if weekend==0 & tustarttim2 >= tc(00:00:00) & tustoptime2 <= tc(07:00:00)
replace action=3 if weekend==0 & tustarttim2 >= tc(07:00:00) & tustoptime2 <= tc(14:00:00)
replace action=4 if weekend==0 & tustarttim2 >= tc(14:00:00) & tustoptime2 <= tc(19:00:00)
replace action=5 if weekend==0 & tustarttim2 >= tc(19:00:00) & tustoptime2 <= tc(23:59:59)
label variable action "Period of the day"
label define labelaction 1 "weekend" 2 "off peak" 3 "day peak" 4 "critical peak" 5 "evening peak" 6 "cross peak", replace
label values action labelaction

*Task A: Multiyear time use analysis
table choice, contents(N tucaseid mean tuactdur24 sd tuactdur24 mean income mean teage)
by season, sort :table choice, contents(N tucaseid mean tuactdur24 sd tuactdur24 mean incomelevl mean teage) 
by season action, sort :table choice, contents(N tucaseid mean tuactdur24 sd tuactdur24 mean incomelevl mean teage)
table choice [aweight = tufnwgtp], contents(N tucaseid mean tuactdur24 sd tuactdur24 mean incomelevl mean teage)
by season, sort :table choice [aweight = tufnwgtp], contents(N tucaseid mean tuactdur24 sd tuactdur24 mean incomelevl mean teage) 
by action, sort :table choice [aweight = tufnwgtp], contents(N tucaseid mean tuactdur24 sd tuactdur24 mean incomelevl mean teage) 
by season action, sort :table choice [aweight = tufnwgtp], contents(N tucaseid mean tuactdur24 sd tuactdur24 mean incomelevl mean teage)
// table choice if season==1, contents(N tucaseid mean tuactdur24 sd tuactdur24 mean income sd income mean teage sd teage)
// table choice if season==2, contents(N tucaseid mean tuactdur24 sd tuactdur24 mean income sd income mean teage sd teage)
// table choice if season==3, contents(N tucaseid mean tuactdur24 sd tuactdur24 mean income sd income mean teage sd teage)
* Tried graphing in Stata
graph box tuactdur24 [pweight = tufnwgtp], over(choice) over(action) nofill ytitle(Duration (in minutes)) name(duration)


* Task B and D: Multivariate prediction models and use case?
describe
list gtco gediv if choice!=. & income==.
* fatal mistake as the list is so long and gediv is mostly missing
tab gtco gediv if choice!=. & income==.
* no observations

* New log file on February 15, 2021
cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSmodels.log, append
sysuse newdata2, clear

* Remove all missing choice observations
drop if choice==.
	(15,496 observations deleted)
save mydata, replace

* see vl list and summary
vl set, list(min max obs) nonotes
vl list, user min max obs

* Noticed I omitted some variables. I list all the variables and then modify the variable lists
ds

* variables of possible interest
tesex teage telfs teern peeduca hehousut teio1cow teio1cow2 hetelhhd teio1icd proxinc income income2 incomelevl pehspnon hetenure ptdtrace prcitshp hrhtype hubus trchildnum prcowpg trhhchild trnumhou trdpftpt teernhro teernhry metsta tryhhchild trtalone teschenr tehruslt 

* variables with missing or incomplete observations out of 3,922,807 in descending order of severity
----------------------------------------------------------------------------------
   Variable | Macro           Values         Levels       Min       Max        Obs
------------+---------------------------------------------------------------------
   hetenure | $vlcategorical  integers >=0        3         1         3  3,919,129
      hubus | $vlcategorical  0 and 1             2         0         1  3,919,051
     income | $vluncertain    integers >=0       16         1        16  3,660,071
    proxinc | $vluncertain    integers >=0       31      4999    254568  3,660,071
   povlevel | $vlcontinuous   noninteger                499.9    254568  3,660,071
    income2 | $vlcategorical  integers >=0        3         1         3  3,660,071
 incomelevl | $vlcategorical  integers >=0        3         1         3  3,660,071 
     gtcbsa | $vlcontinuous   integers >=0     >100         0     79600  3,346,258
       gtco | $vlcontinuous   integers >=0     >100         0       810  3,346,258
    tewhere | $vluncertain    integers >=0       26         1        99  3,214,839
   location | $vlcategorical  integers >=0        3         1         3  3,214,839
  teio1cow2 | $vlcategorical  integers >=0        4         1         4  2,455,788
   teio1cow | $vlcategorical  integers >=0        8         1         8  2,455,788
   teio1icd | $vlcontinuous   integers >=0     >100       170      9590  2,455,788
   trdpftpt | $vlcategorical  0 and 1             2         0         1  2,455,745
   tehruslt | $vlcontinuous   integers >=0     >100         0       160  2,321,304
    prcowpg | $vlcategorical  0 and 1             2         0         1  2,362,904
   teschenr | $vlcategorical  0 and 1             2         0         1  2,263,157
   teernhry | $vlcategorical  0 and 1             2         0         1  2,178,273
 tryhhchild | $vluncertain    integers >=0       18         0        17  1,905,187
  tudurstop | $vlcategorical  0 and 1             2         0         1  1,247,114
      gediv | $vlcategorical  integers >=0        9         1         9  1,024,576
   teernhro | $vluncertain    integers >=0       86         1        99    814,387  
      teern | $vlcontinuous   integers >=0     >100         0    278861    150,013
----------------------------------------------------------------------------------

// Further categorize the variables into continuous, ordinal, binary, or categorical 
// Variables with complete list of observations
* binary
tesex pehspnon hetelhhd trhhchild metsta

* categorical
telfs peeduca ptdtrace prcitshp gereg hehousut hetenure hrhtype 

* ordinal


* continuous
teage trnumhou trtalone trchildnum 

* control (i.control)
gestfips tumonth tudiaryday trholiday weekend season tuyear

// variables with missing observations (use with caution)
* binary
hubus trdpftpt prcowpg teschenr teernhry 

* categorical
income hetenure teio1cow2 teio1icd

* ordinal
income2 incomelevl

* continuous
proxinc tehruslt tryhhchild teernhro teern 

* control
tudurstop

* location
gediv gtcbsa gtco

// Different category with variables with missing values in inverted comma*
* outcome variables
tuactdur24
choice

* activities
computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry

* location
gestfips gereg "gtcbsa" "gtco" "gediv"   

* timing and periods
tumonth tudiarydate tudiaryday trholiday weekend season tuyear "tudurstop"

* definition variables not used directly in the models 
tucaseid tufnwgtp trcodep tuactivity_n	trtier1p trtier2p tucumdur24 tewhere tustarttim tustoptime tustarttim2 tustoptime2 action location  

* Reoder the variables listing
order tucaseid tufnwgtp tuactdur24 choice action ttdur trcodep tustarttim tustoptime tewhere location trtier1p trtier2p  tesex teage telfs peeduca income pehspnon ptdtrace prcitshp hetelhhd trhhchild metsta trnumhou trtalone trchildnum gereg  hehousut hrhtype income2 incomelevl proxinc hubus hetenure computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork , first            

* use vl to create and manage the variable lists while taking note of variables with categories and 
* intial testing 
// vl create binary = (tesex pehspnon tudurstop hetelhhd hubus prcowpg trhhchild teernhry trdpftpt teschenr)
// vl create categorical = (telfs prcitshp ptdtrace peeduca incomelevl proxinc hehousut gereg hetenure teio1cow2 hrhtype)
// vl create control = (weekend season gestfips tuyear tumonth tudiaryday)
// Bad call. Had to start over because I ommitted the vl command
* drop $binary $categorical $control
vl drop $binary $categorical $control

vl create binary = (tesex pehspnon hetelhhd trhhchild metsta)
vl create binary2 = (hubus)
vl create binary3 = (trdpftpt prcowpg teschenr teernhry)

vl create continuous = (teage trnumhou trtalone trchildnum)
vl create continuous2 = (income2 incomelevl proxinc)
vl create continuous3 = (tehruslt tryhhchild teernhro teern)

vl create categorical = (gereg telfs peeduca ptdtrace prcitshp hehousut  hrhtype)
vl create categorical2 = (hetenure income)
vl create categorical3 = (teio1cow2)

// vl create categorical = (gereg_enum* telfs_enum* peeduca_enum* ptdtrace_enum* prcitshp_enum* hehousut_enum* hrhtype_enum*)
// vl create categorical2 = (hetenure_enum* income_enum*)
// vl create categorical3 = (teio1cow2_enum* "teio1icd_enum")

vl create control = ("gestfips" tumonth tudiaryday trholiday "weekend" "season" tuyear)
vl create control2 = (gediv)
vl create control3 = (gtcbsa gtco tudurstop)

vl substitute categ = i.categorical
vl substitute categ2 = i.categorical2
vl substitute categ3 = i.categorical3
vl substitute ctrl = i.control
vl substitute ctrl2 = i.control2
vl substitute ctrl3 = i.control3
vl substitute binry = i.binary
vl substitute binry2 = i.binary2
vl substitute binry3 = i.binary3

display "$categ"
display "$ctrl"
display "$categorical"
display "$categorical2"
display "$categorical3"
display "$control2"
display "$control3"

// vl modify control = control - (weekend)
// vl modify control = control - (season)
// vl modify control = control - (gestfips)
// vl modify continuous2 = continuous2 - (tehruslt tryhhchild teernhro teern)
// vl modify categorical2 = categorical2 - (hetenure teio1cow2 teio1icd)
// vl modify categorical2 = categorical2 + (hetenure)
// vl modify categorical3 = categorical3 - (hetenure)
// vl modify categorical = categorical - (hetenure)
// vl modify binary2 = binary2 - (trdpftpt prcowpg teschenr teernhry)
// vl modify control2 = control2 - (tudurstop)
// vl modify control2 = control2 - (gtcbsa gtco)
// vl modify control3 = control3 + (gtcbsa gtco)

// vl drop categ categ2 categ3 categorical categorical2 categorical3  

vl rebuild

Rebuilding vl macros ...


-------------------------------------------------------------------------------
                  |                      Macro's contents
                  |------------------------------------------------------------
Macro             |  # Vars   Description
------------------+------------------------------------------------------------
User              |
  $binary         |       5   variables
  $binary2        |       1   variable
  $continuous     |       4   variables
  $continuous2    |       3   variables
  $control        |       4   variables
  $control2       |       1   variable
  $continuous3    |       4   variables
  $binary3        |       4   variables
  $control3       |       3   variables
  $categorical    |      41   variables
  $categorical2   |      19   variables
  $categorical3   |       4   variables
  $ctrl           |           factor-variable list
  $ctrl2          |           factor-variable list
  $ctrl3          |           factor-variable list
  $binry          |           factor-variable list
  $binry2         |           factor-variable list
  $binry3         |           factor-variable list
-------------------------------------------------------------------------------

$binary $binary2 $continuous $continuous2 $categorical $categorical2 $control $control2 $continuous3 $categorical3 $binary3 $control3 $categ $categ2 $ctrl $ctrl2 $categ3 $ctrl3

$binary $binary2 $continuous $continuous2 $control $control2 $continuous3 $binary3 $control3 $categorical $categorical2 $categorical3 $ctrl $ctrl2 $ctrl3 $binry $binry2 $binry3

$continuous $continuous2 $continuous3 $binry $binry2 $binry3 $categ $categ2 $categ3 $ctrl $ctrl2 $ctrl3 

// 39 variables in total
* Level 1 (16 variables and 4 control variables)
binary = (tesex pehspnon hetelhhd trhhchild metsta)
continuous = (teage trnumhou trtalone trchildnum)
categorical = (gereg telfs peeduca ptdtrace prcitshp hehousut hrhtype)
control = (tumonth tudiaryday trholiday tuyear)
* Level 2 (6 variables and 1 control variables) < 10% data missing
binary2 = (hubus)
continuous2 = (income2 incomelevl proxinc)
categorical2 = (income hetenure)
control2 = (gediv)
* Level 3 (9 variables and 3 control variable) > 10% missing observations
binary3 = (trdpftpt prcowpg teschenr teernhry)
continuous3 = (tehruslt tryhhchild teernhro teern)
categorical3 = (teio1cow2)
control3 = (gtcbsa gtco tudurstop)

* Note Ben's suggestion to make minimum amount of categoricals


* concerns about missing values affecting regression observations
// regress tuactdur24 $binary, beta
// regress tuactdur24 $binary $binary2, beta
// regress tuactdur24 $binary [pweight = tufnwgtp] , beta
// regress tuactdur24 $binary $binary2 [pweight = tufnwgtp], beta

* First dry run wondering if the levels are omitting observations
// Noticed an issue with the i.variables omitting the first labels

regress tuactdur24 $binary $continuous $categ $ctrl [pweight = tufnwgtp], beta
regress tuactdur24 $binary $binary2 $continuous $continuous2 $categ $categ2 $ctrl $ctrl2 [pweight = tufnwgtp], beta
regress tuactdur24 $binary $binary2 $continuous $continuous2 $continuous3 $binary3 $categ $categ2 $ctrl $ctrl2 $categ3 $ctrl3 [pweight = tufnwgtp],  beta

* Level 1
note: 50.gestfips omitted because of collinearity
note: 55.gestfips omitted because of collinearity
note: 56.gestfips omitted because of collinearity
note: 2.season omitted because of collinearity
note: 3.season omitted because of collinearity

Linear regression                               Number of obs     =  3,919,129
                                                F(125, 3919003)   =     199.57
                                                Prob > F          =     0.0000
                                                R-squared         =     0.0107
                                                Root MSE          =     100.78

* Level 2
note: 16.income 50.gestfips 55.gestfips 56.gestfips 2.season 3.season 2.gediv 3.gediv 4.gediv 5.gediv 6.gediv 7.gediv 8.gediv 9.gediv 83.gtco 115.gtco 121.gtco 137.gtco 145.gtco 161.gtco 181.gtco 191.gtco 215.gtco 309.gtco 329.gtco 423.gtco 441.gtco 479.gtco 485.gtco omitted because of collinearity

Linear regression                               Number of obs     =  1,023,532
                                                F(552, 1022979)   =      12.94
                                                Prob > F          =     0.0000
                                                R-squared         =     0.0113
                                                Root MSE          =     102.02

* Level 3
* Several collinearity issues and extremely few number of observations
note: trhhchild teernhry 16.income 50.gestfips 53.gestfips 55.gestfips 2.season 3.season 2.gediv 3.gediv 4.gediv 5.gediv 6.gediv 7.gediv 8.gediv 9.gediv 22020.gtcbsa 29820.gtcbsa 30340.gtcbsa 46520.gtcbsa 77200.gtcbsa 1.gtco 11.gtco 25.gtco 27.gtco 49.gtco 51.gtco 73.gtco 77.gtco 83.gtco 97.gtco 109.gtco 113.gtco 115.gtco 121.gtco 133.gtco 145.gtco 161.gtco 181.gtco 309.gtco 441.gtco 479.gtco 485.gtco 1170.teio1icd 1270.teio1icd 1280.teio1icd 3680.teio1icd 3780.teio1icd 4880.teio1icd 7470.teio1icd 7980.teio1icd 8570.teio1icd 9090.teio1icd omitted because of collinearity 

Linear regression                               Number of obs     =     11,852
                                                F(482, 11369)     =      11.03
                                                Prob > F          =     0.0000
                                                R-squared         =     0.4968
                                                Root MSE          =     75.455

// Noticed an issue with the i.variables omitting the first labels
* Will therefore generate their categories manually

tab teio1cow2, gen (teio1cow2_enum)
// tab teio1icd, gen (teio1icd_enum)
tab hetenure, gen (hetenure_enum)
tab income, gen (income_enum)
tab gereg, gen (gereg_enum)
tab telfs, gen (telfs_enum)
tab peeduca, gen (peeduca_enum)
tab ptdtrace, gen (ptdtrace_enum)
tab prcitshp, gen (prcitshp_enum)
tab hehousut, gen (hehousut_enum)
tab hrhtype, gen (hrhtype_enum)

// Previous variable list by levels
$binary $continuous $categ $ctrl 

$binary $binary2 $continuous $continuous2 $categ $categ2 $ctrl $ctrl2 

$binary $binary2 $continuous $continuous2 $continuous3 $binary3 $categ $categ2 $ctrl $ctrl2 $categ3 $ctrl3

// New list
$binry $continuous $categorical $ctrl 

$binry $binry2 $continuous $continuous2 $categorical $categorical2 $ctrl $ctrl2 

$binry $binry2 $binry3 $continuous $continuous2 $continuous3 $categorical $categorical2 $categorical3 $ctrl $ctrl2 $ctrl3   

* Remember to use sampling weight

* Second-pass model algorithm testing with variable listing
regress tuactdur24 $binry $continuous $categorical $ctrl [pweight = tufnwgtp], beta
regress tuactdur24 $binry $binry2 $continuous $continuous2 $categorical $categorical2 $ctrl $ctrl2 [pweight = tufnwgtp], beta
regress tuactdur24 $binry $binry2 $binry3 $continuous $continuous2 $continuous3 $categorical $categorical2 $categorical3 $ctrl $ctrl2 $ctrl3 [pweight = tufnwgtp], beta

save "thisdata.dta", replace

*Start here tomorrow*
e.g. students

* Model selection and prediction
* https://www.stata.com/new-in-stata/lasso-model-selection-prediction/
* The random forest algorithm for statistical learning by Matthias Schonlau, and Rosie Yuyan Zou https://journals.sagepub.com/doi/abs/10.1177/1536867X20909688?journalCode=stja

* Duration

* Double-select LASSO regression using adaptive lasso
* Random forest
* Linear regression, beta

* Avoiding double counting in a question scenario where the total duration spent on an activity during a time period
egen ttdur=total(tuactdur24), by(tucaseid action choice)

order tucaseid tufnwgtp tuactdur24 choice action ttdur trcodep tustarttim tustoptime tewhere location trtier1p trtier2p  tesex teage telfs peeduca income pehspnon ptdtrace prcitshp hetelhhd trhhchild metsta trnumhou trtalone trchildnum gereg  hehousut hrhtype income2 incomelevl proxinc hubus hetenure computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork, first

sort tufnwgtp ttdur choice action
quietly by tufnwgtp ttdur choice action : gen dup = cond(_N==1,0,_n)
replace ttdur=. if dup>1
drop dup
label variable ttdur "Total duration of activity per period"

sort tucaseid tustarttim tustoptime choice action 
// drop if ttdur==.
// drop tuactdur24 tustarttim tustoptime tustarttim2 tustoptime2
// save totalactdur, replace

* For a day
egen ttdurday=total(tuactdur24), by(tucaseid choice)

order tucaseid tufnwgtp tuactdur24 choice action ttdur ttdurday trcodep tustarttim tustoptime tewhere location trtier1p trtier2p  tesex teage telfs peeduca income pehspnon ptdtrace prcitshp hetelhhd trhhchild metsta trnumhou trtalone trchildnum gereg  hehousut hrhtype income2 incomelevl proxinc hubus hetenure computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork, first

sort tufnwgtp ttdurday choice
quietly by tufnwgtp ttdurday choice : gen dup = cond(_N==1,0,_n)
replace ttdurday=. if dup>1
drop dup
label variable ttdurday "Total duration of activity in a day"

* Repeat task A for this duration 

table choice [aweight = tufnwgtp] if ttdur!=., contents(N tucaseid mean ttdur sd ttdur mean incomelevl mean teage)
by season, sort :table choice [aweight = tufnwgtp] if ttdur!=., contents(N tucaseid mean ttdur sd ttdur mean incomelevl mean teage) 
by action, sort :table choice [aweight = tufnwgtp] if ttdur!=., contents(N tucaseid mean ttdur sd ttdur mean incomelevl mean teage) 
by season action, sort :table choice [aweight = tufnwgtp] if ttdur!=., contents(N tucaseid mean ttdur sd ttdur mean incomelevl mean teage)

table choice [aweight = tufnwgtp] if ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday mean incomelevl mean teage)
by season, sort :table choice [aweight = tufnwgtp] if ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday mean incomelevl mean teage) 
by action, sort :table choice [aweight = tufnwgtp] if ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday mean incomelevl mean teage) 
by season action, sort :table choice [aweight = tufnwgtp] if ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday mean incomelevl mean teage)

* Tried graphing in Stata
graph hbar (mean) ttdurday (semean) ttdurday [pweight = tufnwgtp] if ttdurday!=., over(choice)

table choice, contents(N tucaseid mean tuactdur24 semean tuactdur24)
table choice [aweight = tufnwgtp] if ttdur!=., contents(N tucaseid mean ttdur semean ttdur)
table choice [aweight = tufnwgtp] if ttdurday!=., contents(N tucaseid mean ttdurday semean ttdurday)


// Annual Typical Day
// Weekend
// Off-peak
// Day-peak
// Critical peak
// Evening peak
// Cross peak

cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSmodels.log, append
sysuse thisdata, clear

* THoughts 
* Go take care of yourself. Having migraines is not worth it.

* Back on track after meeting with Xcel Energy
* https://gist.github.com/philngo/d3e251040569dba67942#file-climate_zones-csv
* https://public.opendatasoft.com/explore/dataset/core-based-statistical-areas-cbsas-and-combined-statistical-areas-csas/table/
* https://codes.iccsafe.org/content/IECC2015/chapter-3-ce-general-requirements?site_type=public
// cbsacode
// Internet Release Date: October 2018
// Source: File prepared by U.S. Census Bureau, Population Division, based on Office of Management and Budget, September 2018 delineations <https://www.whitehouse.gov/wp-content/uploads/2018/09/Bulletin-18-04.pdf>.
// Note: The 2010 OMB Standards for Delineating Metropolitan and Micropolitan Statistical Areas are at <https://www.gpo.gov/fdsys/pkg/FR-2010-06-28/pdf/2010-15605.pdf> and <https://www.gpo.gov/fdsys/pkg/FR-2010-07-07/pdf/2010-16368.pdf>.

import delimited "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cbsa codes.csv", encoding(UTF-8) clear
save cbsacode

import delimited "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\climate_zones.csv", clear 
save ieccclimatecode

sysuse cbsacode
merge m:m fipsstatecode fipscountycode using "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\ieccclimatecode.dta"
    Result                           # of obs.
    -----------------------------------------
    not matched                         1,323
        from master                         3  (_merge==1)
        from using                      1,320  (_merge==2)

    matched                             1,915  (_merge==3)
    -----------------------------------------

duplicates list
(0 observations are duplicates)
duplicates drop cbsacode if _merge==2, force
drop if _merge==1

ds                                     

order cbsacode state statename fipsstatec~e fipscounty~e countyname countycoun~t csacode csatitle cbsatitle ieccclimat~e ieccmoistu~e baclimatez~e metropoli~de metropolit~i metropoli~le centralout~y _merge, first

rename fipsstatecode gestfips
rename cbsacode gtcbsa
rename fipscountycode gtco

destring gtcbsa, generate(gtcbsa2)
drop gtcbsa
rename gtcbsa2 gtcbsa
drop _merge
save cbsaclimate, replace

use "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\thisdata.dta", clear
merge m:m gestfips gtcbsa gtco using "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cbsaclimate.dta"

    Result                           # of obs.
    -----------------------------------------
    not matched                     2,583,564
        from master                 2,582,026  (_merge==1)
        from using                      1,538  (_merge==2)

    matched                         1,340,781  (_merge==3)
    -----------------------------------------
drop if _merge==2 & tucaseid==.
	(1,538 observations deleted)

list ieccclimatezone state statename gestfips if _merge==3 in 1/100000
	 98459. |        2      AZ    Arizona         AZ |

drop _merge centraloutlyingcounty metropolitandivisiontitle metropolitanmicropolitanstatisti metropolitandivisioncode cbsatitle csatitle csacode countycountyequivalent countyname statename state

order tucaseid tufnwgtp tuactdur24 choice action ttdur ttdurday trcodep tustarttim tustoptime tewhere location trtier1p trtier2p  tesex teage telfs peeduca income pehspnon ptdtrace prcitshp hetelhhd trhhchild metsta trnumhou trtalone trchildnum gereg  hehousut hrhtype income2 incomelevl proxinc hubus hetenure gediv gestfips gtcbsa gtco ieccclimatezone ieccmoistureregime baclimatezone computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exrcise laundry justhome away awayatwork, first

save atusclimate, replace

by gereg, sort : tab1 ieccclimatezone ieccmoistureregime baclimatezone
by ieccmoistureregime, sort : tab1 gereg
by ieccmoistureregime, sort : tab1 gestfips
by ieccmoistureregime, sort : tab1 gtco
by ieccmoistureregime, sort : tab1 gtco if gtco==59 | gtco==33
by ieccmoistureregime, sort : tab1 gtcbsa if gtco==59 | gtco==33
by ieccmoistureregime, sort : tab1 gtcbsa if gtco==59 | gtco==33 | gtco==97
tab1 ieccmoistureregime
       IECC |
   Moisture |
     Regime |      Freq.     Percent        Cum.
------------+-----------------------------------
          A |    953,696       71.13       71.13
          B |    289,146       21.57       92.70
          C |     93,325        6.96       99.66
        N/A |      4,614        0.34      100.00
------------+-----------------------------------
      Total |  1,340,781      100.00

tab1 gtcbsa if gtcbsa == 35620 | gtcbsa == 19740 | gtcbsa == 42220
tab1 gtcbsa if ieccmoistureregime=="A" |ieccmoistureregime=="B" |ieccmoistureregime=="C" & gtcbsa == 35620 | gtcbsa == 19740 | gtcbsa == 42220
tab1 gtcbsa if ieccmoistureregime=="A" & gtcbsa == 35620 | ieccmoistureregime=="B" & gtcbsa == 19740 | ieccmoistureregime=="C"  & gtcbsa == 42220
tab1 gtcbsa if ieccmoistureregime=="A" & gtcbsa == 35620 & gtco==59| ieccmoistureregime=="B" & gtcbsa == 19740 | ieccmoistureregime=="C"  & gtcbsa == 42220

   Specific |
metropolita |
     n core |
      based |
statistical |
area (CBSA) |
       code |      Freq.     Percent        Cum.
------------+-----------------------------------
      19740 |     18,310       50.21       50.21
      35620 |     13,027       35.72       85.93
      42220 |      5,131       14.07      100.00
------------+-----------------------------------
      Total |     36,468      100.00

by choice action, sort : tab1 gtcbsa if ieccmoistureregime=="A" & gtcbsa == 35620 & gtco==59| ieccmoistureregime=="B" & gtcbsa == 19740 | ieccmoistureregime=="C"  & gtcbsa == 42220
tab1 gtco if ieccmoistureregime=="A" & gtcbsa == 35620
tab1 gtcbsa if ieccmoistureregime=="A" & gtcbsa == 35620 & gtco==47 | gtco==59 | gtco==61 | gtco==81
tab1 gtcbsa if ieccmoistureregime=="A" & gtcbsa == 35620 & gestfips==36 | ieccmoistureregime=="B" & gtcbsa == 19740 | ieccmoistureregime=="C"  & gtcbsa == 42220
tab1 gtcbsa if ieccmoistureregime=="A" & gtcbsa == 35620 & gestfips==34 | ieccmoistureregime=="B" & gtcbsa == 19740 | ieccmoistureregime=="C"  & gtcbsa == 42220

gen testsample=1 if ieccmoistureregime=="A" & gtcbsa == 35620 & gestfips==34 | ieccmoistureregime=="B" & gtcbsa == 19740 | ieccmoistureregime=="C"  & gtcbsa == 42220
by action, sort: tab1 choice if testsample==1
distinct tucaseid if testsample==1
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     74869       3790
---------------------------------

distinct tucaseid if testsample==1 & gestfips==34
---------------------------------
NJ, CBSA 35620 (New York-Newark-Jersey city), moisture regime A, mix of 4A abd 5A
          |     total   distinct
----------+----------------------
 tucaseid |     51428       2599
---------------------------------
by ieccclimatezone, sort: tab1 gtcbsa if ieccmoistureregime==1 & gestfips==34 & gtcbsa==35620 
	  35620 |     27,029       					 (NJ only: gestfips==34, zone 4A)
	  35620 |     24,399 						 (NJ only: gestfips==34, zone 5A)

distinct tucaseid if testsample==1 & gestfips==8
---------------------------------
CO, CBSA 19740 (Denver-Aurora-Lakewood), IECC moisture regime B, 5B Denver
          |     total   distinct
----------+----------------------
 tucaseid |     18310        947
---------------------------------

distinct tucaseid if testsample==1 & gestfips==6
---------------------------------
CA, CBSA 42220 (Santa Rosa-Petaluma), IECC moisture regime C, 3C San Francisco
          |     total   distinct
----------+----------------------
 tucaseid |      5131        244
---------------------------------

save "atusclimate.dta", replace
save "./atusclimate.dta", replace

* System crash
cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSmodels.log, append
sysuse atusclimate, clear

gen ieccmoistureregime2=1 if ieccmoistureregime =="A"
replace ieccmoistureregime2=2 if ieccmoistureregime =="B"
replace ieccmoistureregime2=3 if ieccmoistureregime =="C"
replace ieccmoistureregime2=4 if ieccmoistureregime =="N/A"
label define labelmoisture 1 "A" 2 "B" 3 "C" 4 "N/A", replace
label value ieccmoistureregime2 labelmoisture
label variable ieccmoistureregime2 "IECC Moisture Regime"
drop ieccmoistureregime
rename ieccmoistureregime2 ieccmoistureregime

order tucaseid tufnwgtp tuactdur24 choice action ttdur ttdurday trcodep tustarttim tustoptime tewhere location trtier1p trtier2p  tesex teage telfs peeduca income pehspnon ptdtrace prcitshp hetelhhd trhhchild metsta trnumhou trtalone trchildnum gereg  hehousut hrhtype income2 incomelevl proxinc hubus hetenure gediv gestfips gtcbsa gtco ieccclimatezone ieccmoistureregime baclimatezone computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork, first


* On Janet's request; select different CBSAs with different temperature zones from the 3 moisture regimes
tab1 gtcbsa if ieccclimatezone==5 & ieccmoistureregime==3
tab1 gtcbsa if ieccmoistureregime==1 & ieccclimatezone==5
by ieccclimatezone ieccmoistureregime, sort: tab1 gtcbsa if ieccmoistureregime==1 & ieccclimatezone==5 & gtcbsa==35620
by ieccclimatezone ieccmoistureregime, sort: tab1 gtcbsa if ieccmoistureregime==1 & gtcbsa==35620
* Looking for a CBSA with known full climate zone information with about 50,000 observations to account for about 6% of each region
tab1 gtcbsa if ieccmoistureregime==1 & ieccclimatezone==6
tab1 gtcbsa if ieccmoistureregime==1 & ieccclimatezone==7
tab1 gtcbsa if ieccmoistureregime==1 & ieccclimatezone==4
      35620 |    128,041       35.10       50.56 
      37980 |     59,572       16.33       67.08
tab1 gtcbsa if ieccmoistureregime==1 & ieccclimatezone==1
      33100 |     38,564       96.77       96.77

tab1 gtcbsa if ieccmoistureregime==1 & gestfips==34 & gtcbsa==35620 

by ieccclimatezone, sort: tab1 gtcbsa if ieccmoistureregime==1 & gestfips==34 & gtcbsa==35620 
* Showed mix of 4A and 5A

by ieccclimatezone ieccmoistureregime, sort: tab1 gtcbsa if gtcbsa==37980 
* Region 4A only
* See example demographic information publicly available on 37980
* https://www.homearea.com/cbsa/philadelphia-camden-wilmington-pa-nj-de-md-metro-area/37980/#demographics
* 37980 Philadelphia-Camden-Wilmington PA-NJ-DE
   Specific |
metropolita |
     n core |
      based |
statistical |
area (CBSA) |
       code |      Freq.     Percent        Cum.
------------+-----------------------------------
      37980 |     59,572      100.00      100.00
------------+-----------------------------------
      Total |     59,572      100.00

tab gestfips if gtcbsa==37980 & ieccmoistureregime==1 
tab gestfips if gtcbsa==37980 & ieccmoistureregime==1

    Federal |
 Processing |
Information |
  Standards |
     (FIPS) |
 state code |      Freq.     Percent        Cum.
------------+-----------------------------------
         DE |      6,246       10.48       10.48
         MD |        103        0.17       10.66
         NJ |     10,361       17.39       28.05
         PA |     42,862       71.95      100.00
------------+-----------------------------------
      Total |     59,572      100.00

distinct tucaseid if gtcbsa==37980 & ieccclimatezone==4
---------------------------------
CBSA 37980 (Philadelphia-Camden-Wilmington PA-NJ-DE), IECC moisture regime A, 4A Philadephia (PA) and 4A Camden (NJ)
          |     total   distinct
----------+----------------------
 tucaseid |     59572       3034
---------------------------------

distinct tucaseid if testsample==1 & gestfips==8
---------------------------------
CO, CBSA 19740 (Denver-Aurora-Lakewood), IECC moisture regime B, 5B Denver
          |     total   distinct
----------+----------------------
 tucaseid |     18310        947
---------------------------------

distinct tucaseid if testsample==1 & gestfips==6
---------------------------------
CA, CBSA 42220 (Santa Rosa-Petaluma), IECC moisture regime C, 3C San Francisco
          |     total   distinct
----------+----------------------
 tucaseid |      5131        244
---------------------------------

* test numbers before generating new sample demarcation
distinct tucaseid if ieccmoistureregime==1 & gtcbsa == 37980 & ieccclimatezone==4 & ieccmoistureregime==1
distinct tucaseid if ieccmoistureregime==2 & ieccclimatezone==5 & gtcbsa == 19740
distinct tucaseid if ieccmoistureregime==3 & ieccclimatezone==3 & gtcbsa == 42220

drop testsample
gen testsample=1 if ieccmoistureregime==1 & gtcbsa == 37980 & ieccclimatezone==4 & ieccmoistureregime==1
replace testsample=1 if ieccmoistureregime==2 & ieccclimatezone==5 & gtcbsa == 19740 
replace testsample=1 if ieccmoistureregime==3 & ieccclimatezone==3 & gtcbsa == 42220

distinct tucaseid if testsample==1
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     83013       4225
---------------------------------

table choice [aweight = tufnwgtp] if testsample==1 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday)
table choice [aweight = tufnwgtp] if testsample==1 & gtcbsa == 37980 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday)
table choice [aweight = tufnwgtp] if testsample==1 & gtcbsa == 19740 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday)
table choice [aweight = tufnwgtp] if testsample==1 & gtcbsa == 42220 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday)

label define labelgestfips 1 "AL" 2 "AK" 4 "AZ" 5 "AR" 6 "CA" 8 "CO" 9 "CT" 10 "DE" 11 "DC" 12 "FL" 13 "GA" 15 "HI" 16 "ID" 17 "IL" 18 "IN" 19 "IA" 20 "KS" 21 "KY" 22 "LA" 23 "ME" 24 "MD" 25 "MA" 26 "MI" 27 "MN" 28 "MS" 29 "MO" 30 "MT" 31 "NE" 32 "NV" 33 "NH" 34 "NJ" 35 "NM" 36 "NY" 37 "NC" 38 "ND" 39 "OH" 40 "OK" 41 "OR" 42 "PA" 44 "RI" 45 "SC" 46 "SD" 47 "TN" 48 "TX" 49 "UT" 50 "VT" 51 "VA" 53 "WA" 54 "WV" 55 "WI" 56 "WY" 
label values gestfips labelgestfips

* diversion
* energy prices on BLS
* https://www.bls.gov/regions/mid-atlantic/news-release/averageenergyprices_philadelphia.htm

vl rebuild
vl modify control2 = control2 + (ieccmoistureregime)
vl modify categorical2 = categorical2 + (ieccclimatezone)

display "$binry"
display "$binry2" 
display "$continuous" 
display "$continuous2" 
display "$categ" 
display "$categ2"
display "$ctrl" 
display "$ctrl2"

* Variable list 
tesex pehspnon hetelhhd trhhchild metsta hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc telfs* peeduca* ptdtrace* prcitshp* gereg* ieccclimatezone* hehousut* hrhtype* income* hetenure* tuyear* tumonth* tudiaryday* trholiday* gediv* ieccmoistureregime*

save "./atusclimate.dta", replace
keep if testsample!=1 & ttdurday!=.
save dailyatusclimate, replace

* Resume work from surgery
* Remind myself of what is in place
cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSmodels.log, append
sysuse atusclimate, clear

distinct tucaseid if testsample==1

set seed 202102
gen u=uniform() if testsample!=1
sort u, stable

set java_heapmax 1g
* https://www.statalist.org/forums/forum/general-stata-discussion/general/1451464-out-of-memory-error-java-heap-space

* test estimation store function for rforest
rforest tuactdur24 tesex* pehspnon* proxinc telfs* ieccmoistureregime* in 1/15000 , type(class) iter(50) numvars(5)


search rforest
rforest ttdurday tesex* pehspnon* proxinc telfs* ieccmoistureregime* in 1/15000 , type(class) iter(50) numvars(5)
di e(OOB_Error)
.877

predict prf in 15001/30000
di e(error_rate)
.88093333

* save event basis
drop prf
save "./atusclimate.dta", replace
* As is, the dataset has tuactdur24 (event basis) excluding testsample (83013) as 3839794

* Period basis
* Average cumulative time spent during periods (mins)
* ttdur (period basis)
keep if ttdur!=.
(1,940,551 observations deleted)
drop u
save atusperiod, replace

distinct tucaseid if testsample==1
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     42318       4225
---------------------------------

set seed 202102
gen u=uniform() if testsample!=1
sort u, stable
distinct tucaseid if u!=.
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |   1939938     196926
---------------------------------

* Split period data (excluding testsample) into ratio 70:30
* 1357957: 581981
  
* Split data (1322496 activities-cumulated daily observations) into 70 ratio 30 
* 70% for training: 925748 * 30% for validation: 396748

drop u out_of_bag_error1 validation_error iter1

set seed 202102
gen u=uniform()
sort u, stable
// figure out how large the value of iterations need to be
gen out_of_bag_error1 = .
gen validation_error = .
gen iter1 = .
local j = 0
forvalues i = 10(5)500 {
	local j = `j' + 1
	rforest ttdur tesex pehspnon hetelhhd trhhchild  metsta hubus teage trnumhou trtalone trchildnum proxinc telfs* peeduca* ptdtrace* prcitshp* gereg* ieccclimatezone* hehousut* hrhtype* income* hetenure* tuyear* tumonth* tudiaryday* trholiday* gediv* ieccmoistureregime* in 1/1357957, type(class) iter(`i') numvars(1)
	qui replace iter1 = `i' in `j'
	qui replace out_of_bag_error1 = `e(OOB_Error)' in `j'
	predict p in 1357958/1939938
	qui replace validation_error = `e(error_rate)' in `j'
	drop p
}



* Removed income2 and incomelevl or incomelevl* from the varlist
* variable listed
tesex pehspnon hetelhhd trhhchild income2 incomelevl metsta hubus teage trnumhou trtalone trchildnum proxinc telfs* peeduca* ptdtrace* prcitshp* gereg* ieccclimatezone* hehousut* hrhtype* income* hetenure* tuyear* tumonth* tudiaryday* trholiday* gediv* ieccmoistureregime*

* Error code
java.lang.reflect.InvocationTargetException
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
        at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
        at java.base/java.lang.reflect.Method.invoke(Unknown Source)
        at com.stata.Javacall.load(Javacall.java:130)
        at com.stata.Javacall.load(Javacall.java:90)
Caused by: java.lang.IllegalArgumentException: Attribute names are not unique! Causes: 'income2' 'incomele
> vl' 
        at weka.core.Instances.<init>(Instances.java:265)
        at RF.RFModel(RF.java:198)
        ... 6 more
r(5100);


java.lang.reflect.InvocationTargetException
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
        at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
        at java.base/java.lang.reflect.Method.invoke(Unknown Source)
        at com.stata.Javacall.load(Javacall.java:130)
        at com.stata.Javacall.load(Javacall.java:90)
Caused by: java.lang.OutOfMemoryError: Java heap space
        at java.base/java.util.Arrays.copyOf(Unknown Source)
        at java.base/java.util.ArrayList.grow(Unknown Source)
        at java.base/java.util.ArrayList.grow(Unknown Source)
        at java.base/java.util.ArrayList.add(Unknown Source)
        at java.base/java.util.ArrayList.add(Unknown Source)
        at weka.core.Instances.add(Instances.java:325)
        at weka.filters.Filter.bufferInput(Filter.java:353)
        at weka.filters.SimpleBatchFilter.input(SimpleBatchFilter.java:205)
        at weka.filters.Filter.useFilter(Filter.java:702)
        at RF.RFModel(RF.java:207)
        ... 6 more
r(5100);


set java_heapmax 4g
(java_heapmax preference recorded; restart required to take effect)

* Restart
// set min_memory 240g 
// op. sys. refuses to provide memory
//     Stata's data-storage memory manager has already allocated 85312m bytes and it just attempted to
//     allocate another 32m bytes.  The operating system said no.  Perhaps you are running another
//     memory-consuming task and the command will work later when the task completes.  Perhaps you are on a
//     multiuser system that is especially busy and the command will work later when activity quiets down.
//     Perhaps a system administrator has put a limit on what you can allocate; see help memory.  Or
//     perhaps that's all the memory your computer can allocate to Stata.
// min_memory not reset
// r(909);


set java_heapmax 32g

cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSmodels.log, append
sysuse atusperiod, clear

drop u out_of_bag_error1 validation_error iter1
set seed 202102
gen u=uniform() if testsample!=1
sort u, stable
gen out_of_bag_error1 = .
gen validation_error = .
gen iter1 = .
local j = 0
forvalues i = 10(5)500 {
	local j = `j' + 1
	rforest ttdur tesex pehspnon hetelhhd trhhchild  metsta hubus teage trnumhou trtalone trchildnum proxinc telfs* peeduca* ptdtrace* prcitshp* gereg* ieccclimatezone* hehousut* hrhtype* income* hetenure* tuyear* tumonth* tudiaryday* trholiday* gediv* ieccmoistureregime* in 1/1357957, type(class) iter(`i') numvars(1)
	qui replace iter1 = `i' in `j'
	qui replace out_of_bag_error1 = `e(OOB_Error)' in `j'
	predict p in 1357958/1939938
	qui replace validation_error = `e(error_rate)' in `j'
	drop p
}

local j = 0
forvalues i = 100(50)500 {
	local j = `j' + 1
	rforest ttdur tesex pehspnon hetelhhd trhhchild  metsta hubus teage trnumhou trtalone trchildnum proxinc telfs* peeduca* ptdtrace* prcitshp* gereg* ieccclimatezone* hehousut* hrhtype* income* hetenure* tuyear* tumonth* tudiaryday* trholiday* gediv* ieccmoistureregime* in 1/1357957, type(class) iter(`i') numvars(1)
	qui replace iter1 = `i' in `j'
	qui replace out_of_bag_error1 = `e(OOB_Error)' in `j'
	predict p in 1357958/1939938
	qui replace validation_error = `e(error_rate)' in `j'
	drop p
}
* Try 7
local j = 0
forvalues i = 100(50)500 {
	local j = `j' + 1
	rforest ttdur tesex pehspnon hetelhhd trhhchild  metsta hubus teage trnumhou trtalone trchildnum proxinc telfs* peeduca* ptdtrace* prcitshp* gereg* ieccclimatezone* hehousut* hrhtype* income* hetenure* tuyear* tumonth* tudiaryday* trholiday* gediv* ieccmoistureregime* in 1/15000, type(class) iter(`i') numvars(1)
	qui replace iter1 = `i' in `j'
	qui replace out_of_bag_error1 = `e(OOB_Error)' in `j'
	predict p in 15001/30000
	qui replace validation_error = `e(error_rate)' in `j'
	drop p
}
java.lang.reflect.InvocationTargetException
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
        at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
        at java.base/java.lang.reflect.Method.invoke(Unknown Source)
        at com.stata.Javacall.load(Javacall.java:130)
        at com.stata.Javacall.load(Javacall.java:90)
Caused by: java.lang.OutOfMemoryError: Java heap space
        at weka.classifiers.trees.RandomTree$Tree.distribution(RandomTree.java:1865)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1490)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree$Tree.buildTree(RandomTree.java:1531)
        at weka.classifiers.trees.RandomTree.buildClassifier(RandomTree.java:801)
        at weka.classifiers.ParallelIteratedSingleClassifierEnhancer.buildClassifiers(ParallelIteratedSing
> leClassifierEnhancer.java:229)
        at weka.classifiers.meta.Bagging.buildClassifier(Bagging.java:739)
        at RF.RFModel(RF.java:245)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
r(5100);


java.lang.reflect.InvocationTargetException
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Unknown Source)
        at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source)
        at java.base/java.lang.reflect.Method.invoke(Unknown Source)
        at com.stata.Javacall.load(Javacall.java:130)
        at com.stata.Javacall.load(Javacall.java:90)
Caused by: java.lang.OutOfMemoryError: Java heap space
r(5100);


label var out_of_bag_error1 "Out of Bag Error"
label var iter1 "Iterations"
label var validation_error "Validation Error"
scatter out_of_bag_error1 iter1, mcolor(blue) msize(tiny) || scatter validation_error iter1, mcolor(red) msize(tiny)

// tune the hyper-parameter numvars
gen oob_error = .
gen nvars = .
gen val_error = .
local j = 0
forvalues i = 1(1)26{
    local j = `j' + 1
	rforest defaultpaymentnextmonth limit_bal sex education marriage_enum* age pay* bill* in 1/15000, type(class) iter(500) numvars(`i')
	qui replace nvars = `i' in `j'
	qui replace oob_error = `e(OOB_Error)' in `j'
	predict p in 15001/30000
	qui replace val_error = `e(error_rate)' in `j'
	drop p
}

label var oob_error "Out of Bag Error"
label var val_error "Validation Error"
label var nvars "Number of Variables Randomly Selected at Each Split"
scatter oob_error nvars, mcolor(blue) msize(tiny) || scatter val_error nvars, mcolor(red) msize(tiny)

// The following code automates finding the minimum error and the corresponding number of variables.
frame put val_error nvars, into(mydata)
frame mydata {
    sort val_error, stable
	local min_val_err = val_error[1]
	local min_nvars = nvars[1]
}
frame drop mydata
di "Minimum Error: `min_val_err'; Corresponding number of variables `min_nvars'" 

// final model: numvars = "18", iter = "1000"
rforest Y X in 1/15000, type(class) iter(1000) numvars(18)
di e(OOB_Error)
predict prf in 15001/30000
di e(error_rate)

// variable importance plot
matrix importance = e(importance)
svmat importance
gen importid=""
local mynames : rownames importance
local k : word count `mynames'
if `k'>_N {
    set obs `k'
}
forvalues i = 1(1)`k'{
    local aword : word `i' of `mynames'
	local alabel : variable label `aword'
	if ("`alabel'"!="") qui replace importid= "`alabel'" in `i'
	else qui replace importid= "`aword'" in `i'
}

graph hbar (mean) importance, over(importid, sort(1) label(labsize(2))) ytitle(Importance)

// Overlay histograms for important predictors for instance
twoway (hist limit_bal if defaultpaymentnextmonth == 0) (hist limit_bal if defaultpaymentnextmonth == 1, fcolor(none) lcolor(black)), legend(order(1 "no default" 2 "default" ))

search fitstat
* https://www.stata.com/manuals/cm.pdf
cmset tucaseid choice
cmchoiceset
cmclogit choice time, casevars(i.income_cat income partysize)
margins
* case-specific variables
* continuous variables 
margins, at(income=(30(10)70))
marginsplot, noci 
* no confidence interval
margins, at(income=30) contrast(outcomejoint)
margins, at(income=50) outcome(bus train) contrast(outcomecontrast(r) nowald effects)
* categorical variables
margins income_cat, outcome(train)
margins ar.income_cat, outcome(train) contrast(nowald effects)
* alternative-specific variables e.g. time
margins, at(time=generate(time+60)) alternative(air)
margins, at(time=generate(time)) at(time=generate(time+60)) alternative(air)
marginsplot, xdimension(_outcome)
margins, at(time=generate(time)) at(time=generate(time+60)) alternative(air) contrast(atcontrast(r) nowald effects)
margins, at(time=generate(time)) at(time=generate(newtime)) alternative(simultaneous)
margins, at(time=generate(time)) at(time=generate(newtime)) alternative(simultaneous) contrast(atcontrast(r) nowald effects)


set seed 202102
gen u=uniform()
sort u, stable

// figure out how large the value of iterations need to be
gen out_of_bag_error1 = .
gen validation_error = .
gen iter1 = .
local j = 0
forvalues i = 10(5)500 {
    local j = `j' + 1
	rforest Y X in 1/15000, type(class) iter(`i') numvars(1)
	qui replace iter1 = `i' in `j'
	qui replace out_of_bag_error1 = `e(OOB_Error)' in `j'
	predict p in 15001/30000
	qui replace validation_error = `e(error_rate)' in `j'
	drop p
}

label var out_of_bag_error1 "Out of Bag Error"
label var iter1 "Iterations"
label var validation_error "Validation Error"
scatter out_of_bag_error1 iter1, mcolor(blue) msize(tiny) || scatter validation_error iter1, mcolor(red) msize(tiny)

// tune the hyper-parameter numvars
gen oob_error = .
gen nvars = .
gen val_error = .
local j = 0
forvalues i = 1(1)26{
    local j = `j' + 1
	rforest defaultpaymentnextmonth limit_bal sex education marriage_enum* age pay* bill* in 1/15000, type(class) iter(500) numvars(`i')
	qui replace nvars = `i' in `j'
	qui replace oob_error = `e(OOB_Error)' in `j'
	predict p in 15001/30000
	qui replace val_error = `e(error_rate)' in `j'
	drop p
}

label var oob_error "Out of Bag Error"
label var val_error "Validation Error"
label var nvars "Number of Variables Randomly Selected at Each Split"
scatter oob_error nvars, mcolor(blue) msize(tiny) || scatter val_error nvars, mcolor(red) msize(tiny)

// The following code automates finding the minimum error and the corresponding number of variables.
frame put val_error nvars, into(mydata)
frame mydata {
    sort val_error, stable
	local min_val_err = val_error[1]
	local min_nvars = nvars[1]
}
frame drop mydata
di "Minimum Error: `min_val_err'; Corresponding number of variables `min_nvars'" 

// final model: numvars = "18", iter = "1000"
rforest Y X in 1/15000, type(class) iter(1000) numvars(18)
di e(OOB_Error)
predict prf in 15001/30000
di e(error_rate)

// variable importance plot
matrix importance = e(importance)
svmat importance
gen importid=""
local mynames : rownames importance
local k : word count `mynames'
if `k'>_N {
    set obs `k'
}
forvalues i = 1(1)`k'{
    local aword : word `i' of `mynames'
	local alabel : variable label `aword'
	if ("`alabel'"!="") qui replace importid= "`alabel'" in `i'
	else qui replace importid= "`aword'" in `i'
}

graph hbar (mean) importance, over(importid, sort(1) label(labsize(2))) ytitle(Importance)

// Overlay histograms for important predictors for instance
twoway (hist limit_bal if defaultpaymentnextmonth == 0) (hist limit_bal if defaultpaymentnextmonth == 1, fcolor(none) lcolor(black)), legend(order(1 "no default" 2 "default" ))

* Choice

* LASSO logit regression on each activity using adaptive lasso
* Multinomial logit regression
* Random forest model


// Annual Typical Day
// Weekend
// Off-peak 
// Day-peak
// Critical peak
// Evening peak
// Cross peak

set seed 202102
gen u=uniform()
sort u, stable

// figure out how large the value of iterations need to be
gen out_of_bag_error1 = .
gen validation_error = .
gen iter1 = .
local j = 0
forvalues i = 10(5)500 {
    local j = `j' + 1
	rforest Y X in 1/15000, type(class) iter(`i') numvars(1)
	qui replace iter1 = `i' in `j'
	qui replace out_of_bag_error1 = `e(OOB_Error)' in `j'
	predict p in 15001/30000
	qui replace validation_error = `e(error_rate)' in `j'
	drop p
}

label var out_of_bag_error1 "Out of Bag Error"
label var iter1 "Iterations"
label var validation_error "Validation Error"
scatter out_of_bag_error1 iter1, mcolor(blue) msize(tiny) || scatter validation_error iter1, mcolor(red) msize(tiny)

// tune the hyper-parameter numvars
gen oob_error = .
gen nvars = .
gen val_error = .
local j = 0
forvalues i = 1(1)26{
    local j = `j' + 1
	rforest defaultpaymentnextmonth limit_bal sex education marriage_enum* age pay* bill* in 1/15000, type(class) iter(500) numvars(`i')
	qui replace nvars = `i' in `j'
	qui replace oob_error = `e(OOB_Error)' in `j'
	predict p in 15001/30000
	qui replace val_error = `e(error_rate)' in `j'
	drop p
}

label var oob_error "Out of Bag Error"
label var val_error "Validation Error"
label var nvars "Number of Variables Randomly Selected at Each Split"
scatter oob_error nvars, mcolor(blue) msize(tiny) || scatter val_error nvars, mcolor(red) msize(tiny)

// The following code automates finding the minimum error and the corresponding number of variables.
frame put val_error nvars, into(mydata)
frame mydata {
    sort val_error, stable
	local min_val_err = val_error[1]
	local min_nvars = nvars[1]
}
frame drop mydata
di "Minimum Error: `min_val_err'; Corresponding number of variables `min_nvars'" 

// final model: numvars = "18", iter = "1000"
rforest Y X in 1/15000, type(class) iter(1000) numvars(18)
di e(OOB_Error)
predict prf in 15001/30000
di e(error_rate)

// variable importance plot
matrix importance = e(importance)
svmat importance
gen importid=""
local mynames : rownames importance
local k : word count `mynames'
if `k'>_N {
    set obs `k'
}
forvalues i = 1(1)`k'{
    local aword : word `i' of `mynames'
	local alabel : variable label `aword'
	if ("`alabel'"!="") qui replace importid= "`alabel'" in `i'
	else qui replace importid= "`aword'" in `i'
}

graph hbar (mean) importance, over(importid, sort(1) label(labsize(2))) ytitle(Importance)

// Overlay histograms for important predictors for instance
twoway (hist limit_bal if defaultpaymentnextmonth == 0) (hist limit_bal if defaultpaymentnextmonth == 1, fcolor(none) lcolor(black)), legend(order(1 "no default" 2 "default" ))

// Compare with logit regression
logistic defaultpaymentnextmonth limit_bal sex education marriage_enum* age pay* bill* in 1/15000
predict plogit in 15001/30000
replace plogit = 0 if plogit <= 0.5 & plogit != .
replace plogit = 1 if plogit > 0.5 & plogit != .
gen error = plogit != defaultpaymentnextmonth
sum error in 15001/30000

* Task C: Selecting Demographic variables
* Model for inference
* https://www.stata.com/new-in-stata/lasso-inferential-methods/

* LASSO inferential methods
* https://www.stata.com/manuals/lassolassoinferenceintro.pdf#lassoLassoinferenceintro
* https://www.stata.com/manuals/lassoinferenceexamples.pdf#lassoInferenceexamples

* March 31, 2021 - Wednesday
cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSmodels2.log, append
sysuse atusclimate, clear
drop u

distinct tucaseid if gtcbsa==37980 & ieccclimatezone==4
---------------------------------
CBSA 37980 (Philadelphia-Camden-Wilmington PA-NJ-DE), IECC moisture regime A, 4A Philadephia (PA) and 4A Camden (NJ)
          |     total   distinct
----------+----------------------
 tucaseid |     59572       3034
---------------------------------

distinct tucaseid if testsample==1 & gestfips==8
---------------------------------
CO, CBSA 19740 (Denver-Aurora-Lakewood), IECC moisture regime B, 5B Denver
          |     total   distinct
----------+----------------------
 tucaseid |     18310        947
---------------------------------

distinct tucaseid if testsample==1 & gestfips==6
---------------------------------
CA, CBSA 42220 (Santa Rosa-Petaluma), IECC moisture regime C, 3C San Francisco
          |     total   distinct
----------+----------------------
 tucaseid |      5131        244
---------------------------------

distinct tucaseid if testsample==1

---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |     83013       4225
---------------------------------

distinct tucaseid if testsample==.
---------------------------------
          |     total   distinct
----------+----------------------
 tucaseid |   3839794     196926
---------------------------------
* Sampling 1: Take 2% of the data out and test prediction power
gen testsample=1 if ieccmoistureregime==1 & gtcbsa == 37980 & ieccclimatezone==4 & ieccmoistureregime==1
replace testsample=1 if ieccmoistureregime==2 & ieccclimatezone==5 & gtcbsa == 19740 
replace testsample=1 if ieccmoistureregime==3 & ieccclimatezone==3 & gtcbsa == 42220
replace testsample=0 if testsample==.
* Sampling 2: Use random sampling
splitsample, generate(sample) nsplit(2) rseed(1234)

* duration model
* lasso linear tuactdur24 ($climate) $binry $binry2 $continuous $continuous2 $categ $categ2 $ctrl $ctrl2 if testsample == 0
Lasso linear model                          No. of obs        =    406,070
                                            No. of covariates =        114
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    5.424406         2       0.0003      10127.8
      49 |   lambda before    .0623675        81       0.0113     10015.57
    * 50 | selected lambda    .0568269        82       0.0113     10015.57
      51 |    lambda after    .0517786        84       0.0113     10015.57
      72 |     last lambda    .0073395        91       0.0113      10015.8
--------------------------------------------------------------------------
* lambda selected by cross-validation.

lasso linear tuactdur24 (i.ieccclimatezone i.ieccmoistureregime) tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg  i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if testsample == 0

Lasso linear model                          No. of obs        =    406,070
                                            No. of covariates =        109
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    5.200197         6       0.0002     10127.96
      50 |   lambda before    .0544781        81       0.0112     10016.93
    * 51 | selected lambda    .0496384        82       0.0112     10016.93
      52 |    lambda after    .0452287        83       0.0112     10016.93
      72 |     last lambda    .0070361        90       0.0112     10017.07
--------------------------------------------------------------------------
* lambda selected by cross-validation.

* metsta is constant drop metsta*
* Also make i.ieccclimatezone and i.ieccmoistureregime non-compulsory

* Use:
* Testsample
lasso linear tuactdur24 i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if testsample == 0, nolog rseed(1234)
cvplot
estimates store cv1

lassoknots, display(nonzero osr2 bic)
lassoselect id = 29
	ID = 29  lambda = .4063834 selected
	* Minimum BIC of 4893711
cvplot
estimates store minBIC1

lasso linear tuactdur24 i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if testsample == 0, nolog selection(adaptive) rseed(1234) 
estimates store adaptive1

lassocoef cv1 minBIC1 adaptive1, sort(coef, standardized) nofvlabel
lassogof cv1 minBIC1 adaptive1, over(testsample) postselection

* Results for Lasso model prediction/
* Over testsample with 2% data excludedPostselection coefficients
-------------------------------------------------------------
Name         testsample |         MSE    R-squared        Obs
------------------------+------------------------------------
cv1                     |
*                     1 |     9980.76       0.0127     23,400
------------------------+------------------------------------
minBIC1                 |
                      1 |    9982.527       0.0124     23,423
------------------------+------------------------------------
adaptive1               |
                      1 |     9980.91       0.0126     23,423
-------------------------------------------------------------
* We compare MSE and R-squared for excluded test sample. Cross-validation (cv1) did best by both measures. considering constants

* Model cv1
Lasso linear model                          No. of obs        =    406,070
                                            No. of covariates =        113
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    5.498561         0       0.0000     10130.17
      48 |   lambda before     .069384        78       0.0113     10016.28
    * 49 | selected lambda    .0632201        79       0.0113     10016.28
      50 |    lambda after    .0576038        79       0.0113     10016.28
      73 |     last lambda    .0067789        91       0.0112      10016.5
--------------------------------------------------------------------------
* lambda selected by cross-validation.
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1_cvplot.gph"
(file C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1_cvplot.gph saved)

graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1_cvplot.jpg", as(jpg) name("Graph") quality(100)
(file C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1_cvplot.jpg written in JPEG format)

lassoknots, display(nonzero osr2 bic)

---------------------------------------------------
       |              No. of     Out-of-
       |             nonzero      sample
    ID |   lambda      coef.   R-squared        BIC
-------+-------------------------------------------
     2 | 5.010084          1      0.0005    4897498
     3 | 4.565002          2      0.0010    4897326
     5 | 3.789945          4      0.0023    4896804
     6 | 3.453257          5      0.0032    4896461
    10 | 2.380196          8      0.0055    4895539
    11 | 2.168746         11      0.0060    4895359
    13 | 1.800531         13      0.0073    4894863
    14 | 1.640577         14      0.0078    4894663
    15 | 1.494832         15      0.0082    4894495
    17 | 1.241036         16      0.0089    4894232
    19 |  1.03033         17      0.0094    4894051
    21 |  .855398         23      0.0097    4893961
    23 | .7101665         24      0.0101    4893821
    24 | .6470772         26      0.0102    4893787
    25 | .5895927         27      0.0104    4893748
    26 | .5372149         30      0.0105    4893741
    27 | .4894902         33      0.0106    4893736
    28 | .4460052         35      0.0106    4893721
  * 29 | .4063834         37      0.0107    4893711  BICmin  
    30 | .3702814         40      0.0108    4893717
    31 | .3373866         43      0.0108    4893726
    32 | .3074141         44      0.0109    4893713
    33 | .2801043         47      0.0109    4893727
    34 | .2552206         52      0.0110    4893760
    35 | .2325475         56      0.0111    4893784
    36 | .2118886         57      0.0111    4893774
    37 |  .193065         59      0.0111    4893779
    38 | .1759137         60      0.0112    4893775
    39 |  .160286         63      0.0112    4893800
    41 | .1330722         65      0.0112    4893803
    43 | .1104789         67      0.0112    4893813
    44 | .1006643         71      0.0112    4893858
    45 | .0917215         72      0.0113    4893865
    46 | .0835732         74      0.0113    4893886
    47 | .0761488         76      0.0113    4893908
    48 |  .069384         78      0.0113    4893930
  * 49 | .0632201         79      0.0113    4893940
    51 | .0524864         81      0.0113    4893961
    52 | .0478237         84      0.0113    4893997
    53 | .0435752         85      0.0113    4894009
    54 | .0397041         87      0.0113    4894033
    55 | .0361769         88      0.0113    4894045
    58 | .0273665         89      0.0113    4894055
    59 | .0249353         91      0.0113    4894080
    69 |  .009835         90      0.0112    4894064
    71 | .0081652         91      0.0112    4894077
    73 | .0067789         91      0.0112    4894077
---------------------------------------------------
* lambda selected by cross-validation.
 graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\minBIC1_cvplot.gph"
(file C:\Users\wolawale\Documents\on PC mode\ATUS new codes\minBIC1_cvplot.gph saved)

graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\minBIC1_cvplot.jpg", as(jpg) name("Graph") quality(100)
(file C:\Users\wolawale\Documents\on PC mode\ATUS new codes\minBIC1_cvplot.jpg written in JPEG format)


Lasso linear model                         No. of obs         =    406,070
                                           No. of covariates  =        113
Selection: Adaptive                        No. of lasso steps =          2

Final adaptive step results
--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
      74 |    first lambda     4564951         1       0.0000     10130.17
     156 |   lambda before    2219.754        59       0.0114     10015.34
   * 157 | selected lambda    2022.557        59       0.0114     10015.34
     158 |    lambda after    1842.879        59       0.0114     10015.35
     173 |     last lambda    456.4951        69       0.0113     10015.51
--------------------------------------------------------------------------
* lambda selected by cross-validation in final adaptive step.

* Sample
lasso linear tuactdur24 i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if sample == 1, nolog rseed(1234)
cvplot
estimates store cv2

lassoknots, display(nonzero osr2 bic)
lassoselect id = 25
	ID = 25  lambda = .5947567 selected
	* Minimum BIC of 2584801

cvplot
estimates store minBIC2

lasso linear tuactdur24 i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if sample == 1, nolog selection(adaptive) rseed(1234) 
estimates store adaptive2

lassocoef cv2 minBIC2 adaptive2, sort(coef, standardized) nofvlabel
lassogof cv2 minBIC2 adaptive2, over(sample) postselection

* Overall comparison of selected variables
lassocoef cv1 cv2 minBIC1 minBIC2 adaptive1 adaptive2, sort(coef, standardized) nofvlabel
lassogof cv1 cv2 minBIC1 minBIC2 adaptive1 adaptive2, over(testsample) postselection

* Results LASSO model/prediction*
* Over random sample with 50:50 splitsample
Postselection coefficients
-------------------------------------------------------------
Name             sample |         MSE    R-squared        Obs
------------------------+------------------------------------
cv2                     |
                      1 |    9989.976       0.0114    214,681
*                     2 |    10032.74       0.0118    215,134
------------------------+------------------------------------
minBIC2                 |
                      1 |    9995.421       0.0108    214,681
                      2 |    10036.17       0.0114    215,134
------------------------+------------------------------------
adaptive2               |
                      1 |     9990.17       0.0113    214,681
                      2 |    10032.89       0.0118    215,134
-------------------------------------------------------------

* Model cv2 
Lasso linear model                          No. of obs        =    214,510
                                            No. of covariates =        113
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    5.546721         0       0.0000     10103.61
      42 |   lambda before    .1223124        66       0.0106      9996.96
    * 43 | selected lambda    .1114465        67       0.0106      9996.96
      44 |    lambda after    .1015459        67       0.0106     9996.982
      74 |     last lambda    .0062308        93       0.0104     9998.353
--------------------------------------------------------------------------
* lambda selected by cross-validation.
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2_cvplot.gph"
(file C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2_cvplot.gph saved)

. graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2_cvplot.jpg", as(jpg) name("Graph") quality(100)
(file C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2_cvplot.jpg written in JPEG format)

---------------------------------------------------
       |              No. of     Out-of-
       |             nonzero      sample
    ID |   lambda      coef.   R-squared        BIC
-------+-------------------------------------------
     2 | 5.053966          1      0.0005    2586591
     3 | 4.604985          2      0.0011    2586480
     5 |  3.82314          3      0.0025    2586191
     6 | 3.483502          5      0.0032    2586049
     9 | 2.635142          6      0.0051    2585650
    11 | 2.187741          8      0.0061    2585474
    12 | 1.993388          9      0.0065    2585393
    13 | 1.816301         11      0.0069    2585304
    14 | 1.654946         12      0.0074    2585211
    15 | 1.507925         13      0.0078    2585129
    18 |  1.14069         14      0.0087    2584940
    19 | 1.039354         15      0.0090    2584905
    20 | .9470209         18      0.0091    2584900
    21 | .8628902         20      0.0093    2584876
    22 | .7862334         21      0.0095    2584846
    23 | .7163866         22      0.0097    2584822
 *  25 | .5947567         25      0.0099    2584801
    26 | .5419202         29      0.0100    2584825
    27 | .4937775         32      0.0101    2584839
    30 | .3735245         37      0.0103    2584843
    31 | .3403417         39      0.0103    2584853
    32 | .3101066         44      0.0104    2584901
    34 |  .257456         48      0.0104    2584925
    35 | .2345843         54      0.0105    2584985
    36 | .2137445         55      0.0105    2584984
    37 |  .194756         57      0.0105    2584998
    38 | .1774544         60      0.0105    2585026
    39 | .1616899         61      0.0105    2585030
    39 | .1616899         61      0.0105    2585030
    40 | .1473258         63      0.0106    2585048
    41 | .1342378         66      0.0106    2585079
  * 43 | .1114465         67      0.0106    2585082
    46 | .0843052         70      0.0106    2585110
    47 | .0768158         72      0.0106    2585132
    48 | .0699917         73      0.0105    2585143
    49 | .0637738         76      0.0105    2585178
    50 | .0581083         81      0.0105    2585238
    51 | .0529461         83      0.0105    2585261
    55 | .0364937         85      0.0105    2585283
    58 | .0276062         86      0.0105    2585294
    59 | .0251537         86      0.0105    2585294
    59 | .0251537         86      0.0105    2585294
    60 | .0229191         87      0.0105    2585306
    61 |  .020883         88      0.0105    2585318
    63 | .0173375         89      0.0105    2585330
    64 | .0157973         91      0.0105    2585354
    65 | .0143939         92      0.0105    2585366
    66 | .0131152         93      0.0104    2585378
    74 | .0062308         93      0.0104    2585378
---------------------------------------------------
* lambda selected by cross-validation.

graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\minBIC2_cvplot.gph"
(file C:\Users\wolawale\Documents\on PC mode\ATUS new codes\minBIC2_cvplot.gph saved)

. graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\minBIC2_cvplot.jpg", as(jpg) name("Graph") quality(100)
(file C:\Users\wolawale\Documents\on PC mode\ATUS new codes\minBIC2_cvplot.jpg written in JPEG format)

Lasso linear model                         No. of obs         =    214,510
                                           No. of covariates  =        113
Selection: Adaptive                        No. of lasso steps =          2

Final adaptive step results
--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
      75 |    first lambda    1.59e+09         0       0.0000     10103.61
     155 |   lambda before      932566        55       0.0108     9995.141
   * 156 | selected lambda    849719.5        55       0.0108     9995.137
     157 |    lambda after    774232.7        55       0.0108     9995.137
     174 |     last lambda    159221.9        64       0.0107     9995.387
--------------------------------------------------------------------------
* lambda selected by cross-validation in final adaptive step.

* noconstant
* added selection(cv, alllambdas) but still problematic
lasso linear tuactdur24 i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if testsample == 0, noconstant selection(cv, alllambdas) rseed(1234)
cvplot
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1NOC_cvplot.gph"
graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1NOC_cvplot.jpg", as(jpg) name("Graph") quality(100)
estimates store cv1_NOC

lasso linear tuactdur24 i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if testsample == 0, noconstant selection(adaptive) rseed(1234) 
estimates store adaptive1_NOC

lasso linear tuactdur24 i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if sample == 1, noconstant rseed(1234)
cvplot
estimates store cv2_NOC
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2NOC_cvplot.gph"
graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2NOC_cvplot.jpg", as(jpg) name("Graph") quality(100)

lasso linear tuactdur24 i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if sample == 1, noconstant selection(adaptive) rseed(1234) 
estimates store adaptive2_NOC

lassocoef cv1_NOC cv2_NOC adaptive1_NOC adaptive2_NOC, sort(coef, standardized) nofvlabel
lassogof cv1_NOC cv2_NOC adaptive1_NOC adaptive2_NOC, over(testsample) postselection
// e(b) not found
// r(498);

* Results for noconstant estimation are ridiculous
Lasso linear model                          No. of obs        =    406,070
                                            No. of covariates =        113
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    5.498561         0      -0.5365     15565.74
      72 |   lambda before    .0074398        91      -0.3546     13722.68
    * 73 | selected lambda    .0067789        91      -0.3514     13690.47
--------------------------------------------------------------------------
* lambda selected by cross-validation.
Note: Minimum of CV function not found; lambda selected based on stop()
      stopping criterion.

Lasso linear model                         No. of obs         =    406,070
                                           No. of covariates  =        113
Selection: Adaptive                        No. of lasso steps =          1

Final adaptive step results
--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
     * 1 | selected lambda    5.498561         0      -0.5365     15565.74
       2 |    lambda after    5.010084         1      -0.5443     15644.38
       4 |     last lambda     4.15946         2      -0.5637     15840.92
--------------------------------------------------------------------------
* lambda selected by cross-validation in final adaptive step.

Lasso linear model                          No. of obs        =    214,510
                                            No. of covariates =        113
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
     * 1 | selected lambda    5.546721         0      -0.5384     15543.91
       2 |    lambda after    5.053966         1      -0.5463     15623.09
       4 |     last lambda    4.195891         2      -0.5673     15835.46
--------------------------------------------------------------------------
* lambda selected by cross-validation.

Lasso linear model                         No. of obs         =    214,510
                                           No. of covariates  =        113
Selection: Adaptive                        No. of lasso steps =          1

Final adaptive step results
--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
     * 1 | selected lambda    5.546721         0      -0.5384     15543.91
       2 |    lambda after    5.053966         1      -0.5463     15623.09
       4 |     last lambda    4.195891         2      -0.5673     15835.46
--------------------------------------------------------------------------
* lambda selected by cross-validation in final adaptive step.

* Period basis
lasso linear ttdur i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if testsample == 0, nolog rseed(1234)
cvplot
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1per_cvplot.gph"
graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1per_cvplot.jpg", as(jpg) name("Graph") quality(100)
estimates store cv1_per

lasso linear ttdur i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if testsample == 0, nolog selection(adaptive) rseed(1234) 
estimates store adaptive1_per

lasso linear ttdur i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if sample == 1, nolog rseed(1234)
cvplot
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2per_cvplot.gph"
graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2per_cvplot.jpg", as(jpg) name("Graph") quality(100)
estimates store cv2_per

lasso linear ttdur i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if sample == 1, nolog selection(adaptive) rseed(1234) 
estimates store adaptive2_per

lassocoef cv1_per cv2_per adaptive1_per adaptive2_per, sort(coef, standardized) nofvlabel
lassogof cv1_per cv2_per adaptive1_per adaptive2_per, over(testsample) postselection

* Results for period basis
*cv1_per
Lasso linear model                          No. of obs        =    206,584
                                            No. of covariates =        113
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    33.58795         0       0.0001     28936.95
      52 |   lambda before    .2921308        44       0.1006     26029.99
    * 53 | selected lambda    .2661787        48       0.1006     26029.96
      54 |    lambda after    .2425321        51       0.1006     26030.03
      76 |     last lambda    .0313242        88       0.1004      26034.2
--------------------------------------------------------------------------
* lambda selected by cross-validation.

*adaptive1_per
Lasso linear model                         No. of obs         =    206,584
                                           No. of covariates  =        113
Selection: Adaptive                        No. of lasso steps =          2

Final adaptive step results
--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
      77 |    first lambda    21279.98         0       0.0001        28937
     175 |   lambda before    2.335475        26       0.1008     26022.41
   * 176 | selected lambda    2.127998        28       0.1008     26022.35
--------------------------------------------------------------------------
* lambda selected by cross-validation in final adaptive step.

*cv2_per
Lasso linear model                          No. of obs        =    108,918
                                            No. of covariates =        113
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    33.33027         0       0.0002     28695.25
      44 |   lambda before      .61019        32       0.0993     25851.92
    * 45 | selected lambda    .5559824        34       0.0993     25851.82
      46 |    lambda after    .5065905        38       0.0993      25851.9
      76 |     last lambda    .0310839        89       0.0989     25861.98
--------------------------------------------------------------------------
* lambda selected by cross-validation.

*adaptive2_per
Lasso linear model                         No. of obs         =    108,918
                                           No. of covariates  =        113
Selection: Adaptive                        No. of lasso steps =          2

Final adaptive step results
--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
      77 |    first lambda    1.22e+11         1       0.0002      28695.3
     172 |   lambda before    1.77e+07        19       0.0997     25841.83
   * 173 | selected lambda    1.61e+07        20       0.0997     25841.83
     174 |    lambda after    1.47e+07        21       0.0996     25841.86
     176 |     last lambda    1.22e+07        22       0.0996     25841.99
--------------------------------------------------------------------------
* lambda selected by cross-validation in final adaptive step.

*lassogof cv1_per cv2_per adaptive1_per adaptive2_per, over(testsample) postselection

Postselection coefficients
-------------------------------------------------------------
Name         testsample |         MSE    R-squared        Obs
------------------------+------------------------------------
cv1_per                 |
                      0 |    26010.86       0.1012    206,584
                      1 |    25924.63       0.1012     11,757
------------------------+------------------------------------
cv2_per                 |
                      0 |    26022.49       0.1008    206,739
                      1 |    25900.66       0.1016     11,771
------------------------+------------------------------------
adaptive1_per           |
                      0 |    26011.44       0.1012    206,739
                      1 |    25919.17       0.1009     11,771
------------------------+------------------------------------
adaptive2_per           |
                      0 |    25791.87       0.1022    1807309
                      1 |    24629.86       0.1042     39,381
-------------------------------------------------------------
save atusmodelpub

* Day basis
lasso linear ttdurday i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if testsample == 0, nolog rseed(1234)
cvplot
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1day_cvplot.gph"
graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv1day_cvplot.jpg", as(jpg) name("Graph") quality(100)
estimates store cv1_day

lasso linear ttdurday i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if testsample == 0, nolog selection(adaptive) rseed(1234) 
estimates store adaptive1_day

lasso linear ttdurday i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if sample == 1, nolog rseed(1234)
cvplot
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2day_cvplot.gph"
graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv2day_cvplot.jpg", as(jpg) name("Graph") quality(100)
estimates store cv2_day

lasso linear ttdurday i.ieccclimatezone i.ieccmoistureregime tesex pehspnon hetelhhd trhhchild  hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv if sample == 1, nolog selection(adaptive) rseed(1234) 
estimates store adaptive2_day

lassocoef cv1_day cv2_day adaptive1_day adaptive2_day, sort(coef, standardized) nofvlabel
lassogof cv1_day cv2_day adaptive1_day adaptive2_day, over(testsample) postselection

* Results for daily basis
*cv1_day
note: 7.ieccclimatezone dropped because of collinearity with another variable

Lasso linear model                          No. of obs        =    140,614
                                            No. of covariates =        113
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    8.508394         0       0.0000     45732.73
      30 |   lambda before    .5729681        37       0.0058     45467.56
    * 31 | selected lambda    .5220672        40       0.0058     45467.41
      32 |    lambda after    .4756882        43       0.0058     45467.55
      75 |     last lambda    .0087086        92       0.0055     45482.29
--------------------------------------------------------------------------
* lambda selected by cross-validation.

*adaptive1_day
note: 7.ieccclimatezone dropped because of collinearity with another variable

Lasso linear model                         No. of obs         =    140,614
                                           No. of covariates  =        113
Selection: Adaptive                        No. of lasso steps =          2

Final adaptive step results
--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
      76 |    first lambda    6.97e+08         0       0.0000     45732.73
     151 |   lambda before    650290.6        31       0.0061     45453.87
   * 152 | selected lambda    592520.6        31       0.0061     45453.81
     153 |    lambda after    539882.7        31       0.0061     45453.83
     175 |     last lambda    69728.53        35       0.0061     45454.77
--------------------------------------------------------------------------
* lambda selected by cross-validation in final adaptive step.

*cv2_day

note: 7.ieccclimatezone dropped because of collinearity with another variable

Lasso linear model                          No. of obs        =     74,123
                                            No. of covariates =        113
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    9.125005         0      -0.0000      45427.7
      24 |   lambda before    1.073842        28       0.0054     45180.27
    * 25 | selected lambda    .9784444        33       0.0054     45180.17
      26 |    lambda after    .8915221        40       0.0054     45180.28
      89 |     last lambda    .0025391        93       0.0048     45210.88
--------------------------------------------------------------------------
* lambda selected by cross-validation.

*adaptive2_day
note: 4.ieccmoistureregime dropped because of collinearity with another variable

Lasso linear model                         No. of obs         =     74,123
                                           No. of covariates  =        113
Selection: Adaptive                        No. of lasso steps =          2

Final adaptive step results
--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
      90 |    first lambda    9.16e+09         0      -0.0000      45427.7
     160 |   lambda before    1.36e+07        25       0.0062      45146.2
   * 161 | selected lambda    1.24e+07        25       0.0062     45146.17
     162 |    lambda after    1.13e+07        25       0.0062     45146.28
     189 |     last lambda    915691.8        30       0.0061     45148.83
--------------------------------------------------------------------------
* lambda selected by cross-validation in final adaptive step.


*lassogof cv1_day cv2_day adaptive1_day adaptive2_day, over(testsample) postselection

Postselection coefficients
-------------------------------------------------------------
Name         testsample |         MSE    R-squared        Obs
------------------------+------------------------------------
cv1_day                 |
                      0 |    45429.23       0.0066    140,614
                      1 |    45286.18       0.0085      8,097
------------------------+------------------------------------
cv2_day                 |
                      0 |    45462.98       0.0060    140,712
                      1 |    45287.82       0.0085      8,103
------------------------+------------------------------------
adaptive1_day           |
                      0 |    45430.63       0.0066    140,614
                      1 |     45284.5       0.0086      8,097
------------------------+------------------------------------
adaptive2_day           |
                      0 |    45463.28       0.0060    140,712
                      1 |    45290.42       0.0084      8,103
-------------------------------------------------------------


* Selected variable list based on test and random sampling comparison of minBIC, adaptive, and cross-validation LASSO methods for activities duration per event with constant
tesex trhhchild trchildnum trtalone incomelevl i.peeduca i.ptdtrace i.prcitshp i.hrhtype i.hetenure i.tumonth i.tudiaryday i.trholiday i.gediv i.ieccmoistureregime 

i.ieccclimatezone pehspnon hetelhhd hubus teage trnumhou income2 proxinc  i.telfs  i.gereg i.hehousut i.income tuyear

tesex trhhchild
trchildnum trtalone incomelevl
peeduca ptdtrace prcitshp hrhtype hetenure
tudiaryday trholiday tumonth gediv
ieccmoistureregime

* Selected variable list based on test and random sampling comparison of adaptive and cross-validation LASSO methods for activities duration per period with constant

tesex trhhchild trtalone trchildnum incomelevl i.telfs i.peeduca i.ptdtrace i.hehousut i.hrhtype i.tumonth i.tudiaryday i.trholiday

pehspnon hetelhhd hubus teage trnumhou income2 proxinc i.prcitshp i.gereg i.income i.hetenure tuyear i.gediv i.ieccclimatezone i.ieccmoistureregime 

tesex trhhchild
trchildnum trtalone incomelevl
peeduca ptdtrace telfs hrhtype 4.hehousut
trholiday tudiaryday tumonth

* Cris-cross demographic variable selection from all three time sets for duration
hrhtype incomelevl peeduca ptdtrace tesex trchildnum trhhchild trholiday trtalone tudiaryday

tesex trhhchild trtalone trchildnum incomelevl i.peeduca i.ptdtrace i.hrhtype i.tudiaryday i.trholiday 

pehspnon hetelhhd hubus teage trnumhou income2 proxinc i.telfs i.prcitshp i.gereg i.hehousut i.income i.hetenure tuyear i.tumonth i.gediv i.ieccclimatezone i.ieccmoistureregime 

* sample lasso model demonstration
* https://www.stata.com/manuals/lassolasso.pdf
* https://www.stata.com/new-in-stata/lasso-model-selection-prediction/
* Lambda (λ) is lasso's penalty parameter. Lasso fits a range of models, from models with no covariates to models with lots, corresponding to models with large λ to models with small λ. Cross-validation chooses the model that minimizes the cross-validation function.
* We can select the model corresponding to any λ we wish after fitting the lasso. Picking the λ that has the minimum Bayes information criterion (BIC) gives good predictions under certain conditions.
* Adaptive lasso is another selection technique that tends to select fewer covariates. It also uses cross-validation but runs multiple lassos. By default, it runs two.
* Example 1: Lasso with λ selected by cross-validation
lasso linear q104 ($idemographics) $ifactors $vlcontinuous if sample == 1
cvplot
estimates store cv
* Example 2: The same lasso, but we select λ to minimize the BIC
lassoknots, display(nonzero osr2 bic)
lassoselect id = 14
cvplot
estimates store minBIC
* Example 3. The same lasso, fit by adaptive lasso
lasso linear q104 ($idemographics) $ifactors $vlcontinuous if sample == 1, selection(adaptive)
estimates store adaptive
lassocoef cv minBIC adaptive, sort(coef, standardized) nofvlabel
lassogof cv minBIC adaptive, over(sample) postselection



rseed(12345)
describe
vl set
vl list vlcategorical
tabulate siblings_old
vl move (siblings_old siblings_young) vlcontinuous
summarize $vlcontinuous
tabulate age0
vl list vluncertain
vl create cc = vlcontinuous - (react no2_class)
vl create fc = vlcategorical
xporegress react no2_class, controls($cc i.($fc)) rseed(12345)
lassoinfo
xporegress react no2_class, controls($cc i.($fc)) selection(cv) rseed(12345)
dsregress react no2_class, controls($cc i.($fc)) selection(cv) rseed(12345)
estimates store ds_cv
lassocoef (ds_plugin, for(react)) (ds_cv , for(react)) (ds_plugin, for(no2_class)) (ds_cv , for(no2_class))
 

* using the default plugin method for choosing the included controls via its choice of the lasso penalty parameter λ.
* cross-partialing out or double machine learning 
xporegress y d1 d2, controls(x1-x100 i.(f1-f30))
* double selection lasso
dsregress y d1 d2, controls(x1-x100 i.(f1-f30))
* using the cross-validation method to choose the lasso penalty parameter λ and thereby to choose the included control covariates
xporegress y d1 d2, controls(x1-x100 i.(f1-f30)) selection(cv)
* Notes: 1. Use xporegress with no options to fit your model using the cross-fit partialing-out method with λ, and thereby the control covariates, selected using the plugin method. The plugin method was designed for variable selection in this inferential framework and has the strongest theoretical justification.
* 2. If you want to explore the process whereby the control covariates were selected, add option selection(cv) to your xporegress specification. You can then explore the path by which each lasso selected control covariates. You are still on firm theoretical footing. Cross-validation meets the requirements of a sufficient variable-selection method. Cross-validation has a long history in machine learning. Moreover, what cross-validation is doing and how it chooses the covariates is easy to explain.
* 3. If you do not want to explore lots of lassos and you want to fit models much more quickly, use commands dsregress or poregress rather than using xporegress.
* We also note that xporegress estimates robust standard errors, so all the associated statistics are also robust. With xporegress, we are robust to nonnormality of the error and to heteroskedasticity.
* plugin is designed to be cautious about adding noise through variable selection while cross-validation cares only about minimizing the cross-validation mean squared error.

vl rebuild

display "$binry"
display "$binry2" 
display "$continuous" 
display "$continuous2" 
display "$categ" 
display "$categ2"
display "$ctrl" 
display "$ctrl2"
display "$climate"

* Variable list under consideration based on LASSO model selection event basis
tesex trchildnum peeduca trhhchild tudiaryday trtalone ptdtrace prcitshp trholiday hrhtype tumonth hetenure gediv incomelevl income2 ieccmoistureregime

tesex trhhchild
trchildnum trtalone incomelevl
peeduca ptdtrace prcitshp hrhtype hetenure
tudiaryday trholiday tumonth gediv
ieccmoistureregime

* period basis
tudiaryday tesex peeduca trchildnum trtalone ptdtrace trhhchild telfs hrhtype incomelevl trholiday 4.hehousut tumonth

tesex  trhhchild
trchildnum trtalone incomelevl
peeduca ptdtrace telfs hrhtype 4.hehousut
trholiday tudiaryday tumonth

* daily basis
tesex tudiaryday peeduca telfs ptdtrace trtalone hrhtype trchildnum incomelevl 1.hetenure trhhchild trholiday income

tesex trhhchild  
trchildnum trtalone incomelevl 
i.peeduca i.telfs i.ptdtrace i.hrhtype i.hetenure i.income 
i.tudiaryday i.trholiday

* Variable list 
*binary *continuous *categorical *control *climate
tesex pehspnon hetelhhd trhhchild metsta hubus 
teage trnumhou trtalone trchildnum income2 incomelevl proxinc 
telfs* peeduca* ptdtrace* prcitshp* gereg*  hehousut* hrhtype* income* hetenure* 
tuyear* tumonth* tudiaryday* trholiday* gediv* 
ieccclimatezone* ieccmoistureregime*

tesex pehspnon hetelhhd trhhchild hubus 
teage trnumhou trtalone trchildnum income2 incomelevl proxinc
i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure 
tuyear i.tumonth i.tudiaryday i.trholiday i.gediv
i.ieccclimatezone i.ieccmoistureregime 

tesex pehspnon hetelhhd trhhchild hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv i.ieccclimatezone i.ieccmoistureregime 

display "$binry"
i.tesex i.pehspnon i.hetelhhd i.trhhchild i.metsta

display "$binry2" 
i.hubus

display "$continuous" 
teage trnumhou trtalone trchildnum

display "$continuous2" 
income2 incomelevl proxinc

display "$categ" 
i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype

display "$categ2"
i.income i.hetenure

display "$ctrl" 
i.tuyear i.tumonth i.tudiaryday i.trholiday

display "$ctrl2"
i.gediv

display "$climate"
ieccclimatezone ieccmoistureregime

vl modify control2 = control2 - (ieccmoistureregime)
vl modify categorical2 = categorical2 - (ieccclimatezone)
vl create climate = (ieccclimatezone ieccmoistureregime)
vl modify binary = binary - (metsta)
vl modify continuous = continuous + (metsta)

* Cris-cross demographic variable selection from all three time sets for duration
hrhtype incomelevl peeduca ptdtrace tesex trchildnum trhhchild trholiday trtalone tudiaryday

*across-temporal selection 
tesex trhhchild trtalone trchildnum incomelevl i.peeduca i.ptdtrace i.hrhtype i.tudiaryday i.trholiday 
pehspnon hetelhhd hubus teage trnumhou income2 proxinc i.telfs i.prcitshp i.gereg i.hehousut i.income i.hetenure tuyear i.tumonth i.gediv i.ieccclimatezone i.ieccmoistureregime 

dsregress tuactdur24 tesex trhhchild trtalone trchildnum incomelevl i.peeduca i.ptdtrace i.hrhtype i.tudiaryday i.trholiday, controls(pehspnon hetelhhd hubus teage trnumhou income2 proxinc i.telfs i.prcitshp i.gereg i.hehousut i.income i.hetenure tuyear i.tumonth i.gediv i.ieccmoistureregime) rseed(1234)
estimates store ds_across
*error result remove ieccclimatezone
// note: convergence for the lasso penalty = 0.006535 not reached after 100000 iterations; solutions for
//       larger penalty values returned
// r(430);

* same problem
// note: convergence for the lasso penalty = 0.006503 not reached after 100000 iterations; solutions for
//       larger penalty values returned
// r(430);

* Try cross-validation instead of plugin
dsregress tuactdur24 tesex trhhchild trtalone trchildnum incomelevl i.peeduca i.ptdtrace i.hrhtype i.tudiaryday i.trholiday, controls(pehspnon hetelhhd hubus teage trnumhou income2 proxinc i.telfs i.prcitshp i.gereg i.hehousut i.income i.hetenure tuyear i.tumonth i.gediv i.ieccmoistureregime) selection(cv) rseed(1234)
estimates store dscv_across


Double-selection linear model         Number of obs               =    429,470
                                      Number of controls          =         72
                                      Number of selected controls =         72
                                      Wald chi2(30)               =    3426.68
                                      Prob > chi2                 =     0.0000

---------------------------------------------------------------------------------------------------------
                                        |               Robust
                             tuactdur24 |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
----------------------------------------+----------------------------------------------------------------
                                  tesex |  -11.91722   .3869845   -30.80   0.000     -12.6757   -11.15874
                              trhhchild |  -5.990228   .6211604    -9.64   0.000     -7.20768   -4.772776
                               trtalone |  -.0062776   .0008016    -7.83   0.000    -.0078486   -.0047065
                             trchildnum |   -4.02034   .3403718   -11.81   0.000    -4.687457   -3.353224
                             incomelevl |  -.2181244   .6040497    -0.36   0.718     -1.40204    .9657912
                                        |
                                peeduca |
                           High school  |  -6.360345   .6677025    -9.53   0.000    -7.669018   -5.051673
              Some college - no degree  |  -10.16954   .6836449   -14.88   0.000    -11.50946   -8.829618
           College or associate degree  |   -11.3056   .6420004   -17.61   0.000     -12.5639    -10.0473
                         Post graduate  |  -14.25086   .7041586   -20.24   0.000    -15.63099   -12.87073
                                        |
                               ptdtrace |
             Black or African American  |   6.148119   .4985171    12.33   0.000     5.171043    7.125194
                                 Asian  |   2.568197   .7437755     3.45   0.001     1.110424     4.02597
     American Indian and Alaska Native  |   4.721224   2.235955     2.11   0.035     .3388333    9.103614
Native Hawaiian and Other Pacific Is..  |  -5.329151    2.82962    -1.88   0.060     -10.8751     .216801
                     Two or More Races  |  -.8190588   1.282757    -0.64   0.523    -3.333215    1.695098
                                        |
                                hrhtype |
Husband/wife primary family (either..)  |   .3503993   1.702413     0.21   0.837     -2.98627    3.687068
Unmarried civilian male - primary fa..  |   2.466681   .8588056     2.87   0.004     .7834525    4.149909
Unmarried civilian female - primary ..  |   3.050412   .5620456     5.43   0.000     1.948822    4.152001
Primary family householder - respond..  |  -2.350998   7.756347    -0.30   0.762    -17.55316    12.85116
      Civilian male primary individual  |   1.515927   .6868104     2.21   0.027     .1698032    2.862051
    Civilian female primary individual  |   5.370519    .616866     8.71   0.000     4.161484    6.579555
Primary individual householder - res..  |  -31.16099   10.50257    -2.97   0.003    -51.74565   -10.57632
            Group quarters with family  |  -40.69639   16.63796    -2.45   0.014    -73.30619   -8.086596
         Group quarters without family  |  -15.45819   16.32114    -0.95   0.344    -47.44704    16.53066
                                        |
                             tudiaryday |
                                Monday  |  -5.388519   .5723292    -9.42   0.000    -6.510264   -4.266775
                               Tuesday  |  -6.131901   .5750621   -10.66   0.000    -7.259002     -5.0048
                             Wednesday  |  -8.754121   .5481608   -15.97   0.000    -9.828496   -7.679746
                              Thursday  |  -7.970237   .5590669   -14.26   0.000    -9.065988   -6.874486
                                Friday  |   -7.37744   .5601605   -13.17   0.000    -8.475334   -6.279545
                              Saturday  |   .2162077   .4514253     0.48   0.632    -.6685695    1.100985
                                        |
                              trholiday |
               Diary day was a holiday  |   8.170795   1.418288     5.76   0.000     5.391001    10.95059
---------------------------------------------------------------------------------------------------------
Note: Chi-squared test is a Wald test of the coefficients of the variables
      of interest jointly equal to zero. Lassos select controls for model
      estimation. Type lassoinfo to see number of selected variables in each
      lasso.

*Exclude income2 proxinc i.income i.ieccclimatezone
dsregress tuactdur24 tesex trhhchild trtalone trchildnum incomelevl i.peeduca i.ptdtrace i.hrhtype i.tudiaryday i.trholiday, controls(pehspnon hetelhhd hubus teage trnumhou  i.telfs i.prcitshp i.gereg i.hehousut i.hetenure tuyear i.tumonth i.gediv i.ieccmoistureregime)  rseed(1234)


* wondering about gender
dsregress tuactdur24 tesex, controls(trhhchild trtalone trchildnum teage incomelevl i.peeduca i.ptdtrace i.hrhtype i.tudiaryday i.trholiday pehspnon hetelhhd hubus trnumhou income2 proxinc i.telfs i.prcitshp i.gereg i.hehousut i.income i.hetenure tuyear i.tumonth i.gediv i.ieccmoistureregime) rseed(1234)

Estimating lasso for tuactdur24 using plugin
Estimating lasso for tesex using plugin

Double-selection linear model         Number of obs               =    429,470
                                      Number of controls          =        106
                                      Number of selected controls =         57
                                      Wald chi2(1)                =     947.09
                                      Prob > chi2                 =     0.0000

------------------------------------------------------------------------------
             |               Robust
  tuactdur24 |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
       tesex |  -11.90527   .3868506   -30.77   0.000    -12.66349   -11.14706
------------------------------------------------------------------------------
Note: Chi-squared test is a Wald test of the coefficients of the variables
      of interest jointly equal to zero. Lassos select controls for model
      estimation. Type lassoinfo to see number of selected variables in each
      lasso.

* gender and age
dsregress tuactdur24 tesex teage, controls(trhhchild trtalone trchildnum incomelevl i.peeduca i.ptdtrace i.hrhtype i.tudiaryday i.trholiday pehspnon hetelhhd hubus trnumhou income2 proxinc i.telfs i.prcitshp i.gereg i.hehousut i.income i.hetenure tuyear i.tumonth i.gediv i.ieccmoistureregime) rseed(1234)

Double-selection linear model         Number of obs               =    429,470
                                      Number of controls          =        105
                                      Number of selected controls =         76
                                      Wald chi2(2)                =     946.12
                                      Prob > chi2                 =     0.0000

------------------------------------------------------------------------------
             |               Robust
  tuactdur24 |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
       tesex |  -11.90131    .386921   -30.76   0.000    -12.65966   -11.14296
       teage |  -.0277101    .012772    -2.17   0.030    -.0527428   -.0026775
------------------------------------------------------------------------------
Note: Chi-squared test is a Wald test of the coefficients of the variables
      of interest jointly equal to zero. Lassos select controls for model
      estimation. Type lassoinfo to see number of selected variables in each
      lasso.

* wondering about age
dsregress tuactdur24 teage, controls(tesex trhhchild trtalone trchildnum incomelevl i.peeduca i.ptdtrace i.hrhtype i.tudiaryday i.trholiday pehspnon hetelhhd hubus trnumhou income2 proxinc i.telfs i.prcitshp i.gereg i.hehousut i.income i.hetenure tuyear i.tumonth i.gediv i.ieccmoistureregime) rseed(1234)

Double-selection linear model         Number of obs               =    429,470
                                      Number of controls          =        106
                                      Number of selected controls =         64
                                      Wald chi2(1)                =       4.50
                                      Prob > chi2                 =     0.0340

------------------------------------------------------------------------------
             |               Robust
  tuactdur24 |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
       teage |  -.0270683   .0127653    -2.12   0.034    -.0520878   -.0020488
------------------------------------------------------------------------------
Note: Chi-squared test is a Wald test of the coefficients of the variables
      of interest jointly equal to zero. Lassos select controls for model
      estimation. Type lassoinfo to see number of selected variables in each
      lasso.

// across-temporal selection (only demographics)
tesex trhhchild trtalone trchildnum incomelevl i.peeduca i.ptdtrace i.hrhtype 
pehspnon hetelhhd hubus teage trnumhou income2 proxinc i.telfs i.prcitshp i.gereg i.hehousut i.income i.hetenure tuyear i.tumonth i.tudiaryday i.trholiday i.gediv i.ieccclimatezone i.ieccmoistureregime 

// (not-across-temporal selection)
i.gediv i.hehousut i.hetenure i.ieccmoistureregime i.prcitshp i.telfs i.trholiday i.tudiaryday i.tumonth
tesex pehspnon hetelhhd trhhchild hubus teage trnumhou trtalone trchildnum income2 incomelevl proxinc i.peeduca i.ptdtrace i.gereg i.hrhtype i.income tuyear i.ieccclimatezone

* All LASSO selected
dsregress tuactdur24 tesex trtalone trhhchild trchildnum i.telfs incomelevl i.income i.peeduca i.ptdtrace i.prcitshp i.hrhtype i.hehousut i.hetenure i.gediv i.tudiaryday i.trholiday i.tumonth i.ieccmoistureregime, controls(pehspnon hetelhhd hubus teage trnumhou i.gereg tuyear) selection(cv) rseed(1234)
estimates store dscv_lassoselect
* stored result on .txt and Excel spreadsheet

*wondering about all the variables with controls
tesex pehspnon hetelhhd trhhchild hubus teage trnumhou trtalone trchildnum proxinc incomelevl telfs peeduca ptdtrace prcitshp gereg hehousut hrhtype hetenure tuyear tumonth tudiaryday trholiday gediv ieccclimatezone ieccmoistureregime

// 39 variables in total (revised)
* Level 1 (16 variables and 4 control variables)
binary = (tesex pehspnon hetelhhd trhhchild "metsta")
continuous = (teage trnumhou trtalone trchildnum)
categorical = (gereg telfs peeduca ptdtrace prcitshp hehousut hrhtype)
control = ("tumonth" $season tudiaryday trholiday tuyear)
* Level 2 (6 variables and 1 control variables) < 10% data missing
binary2 = (hubus)
continuous2 = ("income2" $incomelevl! proxinc)
categorical2 = ("income" incomelevl hetenure)
* Level 3 (9 variables and 3 control variable) > 10% missing observations
binary3 = (trdpftpt prcowpg teschenr teernhry)
continuous3 = (tehruslt tryhhchild teernhro teern)
categorical3 = (teio1cow2)
// control2 = ("gediv")
control3 = (gtcbsa gtco tudurstop)

i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure i.tuyear i.tumonth i.tudiaryday i.trholiday i.gediv i.ieccclimatezone i.ieccmoistureregime

* revise to reduce number of sub-categories and avoid multi-collinearity
* Initial all listed
i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.gediv i.hehousut i.hrhtype i.hetenure tuyear i.season i.tumonth i.tudiaryday i.trholiday i.ieccmoistureregime i.ieccclimatezone

i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season 
i.tudiaryday i.trholiday i.ieccmoistureregime

"i.gediv i.ieccclimatezone i.tumonth = i.season"
"i.tuyear ~ tuyear"
 
dsregress tuactdur24 i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season , controls(i.tudiaryday i.trholiday i.ieccmoistureregime) selection(cv) rseed(1234)
estimates store dscv_all
* stored result on .txt and Excel spreadsheet

esttab dscv_across dscv_lassoselect dscv_all using comparedurlassoinf.html, se aic obslast scalar(F) bic r2 label title("Lasso inference models for single-event duration spent on any of the considered activities in a day") mtitle("Model 1" "Model 2" "Model 3")

"Try this later for comparison sake"
xporegress tuactdur24 i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure, controls(i.tuyear i.tumonth i.tudiaryday i.trholiday i.gediv i.ieccclimatezone i.ieccmoistureregime) selection(cv) rseed(1234)
estimates store xpocv_all


* Presenting the variable list 'cos I needed their names. Also worked on pairwise correlation matrix
i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime

describe tesex pehspnon hetelhhd trhhchild hubus teage trnumhou trtalone trchildnum proxinc incomelevl telfs peeduca ptdtrace prcitshp gereg hehousut hrhtype hetenure tuyear season tumonth tudiaryday trholiday gediv ieccclimatezone ieccmoistureregime

summarize tesex pehspnon hetelhhd trhhchild hubus teage trnumhou trtalone trchildnum proxinc incomelevl telfs peeduca ptdtrace prcitshp gereg hehousut hrhtype hetenure tuyear season tumonth tudiaryday trholiday gediv ieccclimatezone ieccmoistureregime, sep(0)

pwcorr tesex pehspnon hetelhhd trhhchild hubus teage trnumhou trtalone trchildnum proxinc incomelevl telfs peeduca ptdtrace prcitshp gereg gediv hehousut hrhtype hetenure, print(.01) star(.001)

pwcorr gediv gereg tuyear season tumonth tudiaryday trholiday ieccclimatezone ieccmoistureregime, print(.01) star(.001)

pwcorr tesex pehspnon hetelhhd trhhchild hubus teage trnumhou trtalone trchildnum proxinc incomelevl telfs peeduca ptdtrace prcitshp gereg gediv hehousut hrhtype hetenure, print(.001)

pwcorr gediv gereg tuyear season tumonth tudiaryday trholiday ieccclimatezone ieccmoistureregime, print(.001)

* Lasso inference
* cross-partialing out or double machine learning 
xporegress y d1 d2, controls(x1-x100 i.(f1-f30))
* double selection lasso
dsregress y d1 d2, controls(x1-x100 i.(f1-f30))
* using the cross-validation method to choose the lasso penalty parameter λ and thereby to choose the included control covariates
xporegress y d1 d2, controls(x1-x100 i.(f1-f30)) selection(cv)
* Save models

log using ATUSmodels2.log, append
save atusmodelpub, replace

* variable list
i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime
""

"Start comparing prediction power of lasso against linear regression"
drop _est_cv2 _est_minBIC2 _est_adaptive2 _est_cv1_per _est_adaptive1_per _est_cv2_per _est_adaptive2_per _est_adaptive1 _est_cv1 _est_minBIC1 _est_dscv_across _est_dscv_lassoselect _est_dscv_all

save atusdurmodels, replace
* Use test sample for prediction
* Duration of time spent in a typical day at a single stretch without switching activities

lasso linear tuactdur24 i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime if testsample == 0, nolog rseed(1234)
est sto lasso_cv_single
predict p if testsample == 1

lasso linear tuactdur24 i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime if testsample == 0, nolog selection(adaptive) rseed(1234)
est sto lasso_adapt_single
predict p_adapt if testsample == 1

regress tuactdur24 i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime if testsample == 0 , beta
est sto reg_single
predict p_regs if testsample == 1

regress tuactdur24 i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime if testsample == 0 , noconstant beta
est sto reg_noc_single
predict p_regnocs if testsample == 1

* rethinking noconstant r-squared was useless
// regress tuactdur24 i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime if testsample == 0 , hascons beta

regress tuactdur24 i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  [pweight = tufnwgtp] if testsample == 0, beta
est sto reg_weighted_single
predict p_regwets if testsample == 1

regress tuactdur24 i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  [pweight = tufnwgtp] if testsample == 0, noconstant beta
est sto reg_weightnoc_single
predict p_regwetnocs if testsample == 1


Lasso linear model                          No. of obs        =  1,185,191
                                            No. of covariates =         79
Selection: Cross-validation                 No. of CV folds   =         10

--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
       1 |    first lambda    5.539582         0       0.0000     10050.37
      64 |   lambda before    .0157769        60       0.0124     9926.129
    * 65 | selected lambda    .0143753        60       0.0124     9926.129
      66 |    lambda after    .0130983        60       0.0124     9926.129
      70 |     last lambda    .0090281        60       0.0124      9926.13
--------------------------------------------------------------------------
* lambda selected by cross-validation.


Lasso linear model                         No. of obs         =  1,185,191
                                           No. of covariates  =         79
Selection: Adaptive                        No. of lasso steps =          2

Final adaptive step results
--------------------------------------------------------------------------
         |                                No. of      Out-of-      CV mean
         |                               nonzero       sample   prediction
      ID |     Description      lambda     coef.    R-squared        error
---------+----------------------------------------------------------------
      71 |    first lambda    2.14e+09         1       0.0000     10050.37
     160 |   lambda before    541726.2        45       0.0124     9925.952
   * 161 | selected lambda    493600.7        45       0.0124      9925.95
     162 |    lambda after    449750.6        45       0.0124     9925.951
     170 |     last lambda      213668        49       0.0124     9925.999
--------------------------------------------------------------------------
* lambda selected by cross-validation in final adaptive step.

// regs
      Source |       SS           df       MS      Number of obs   = 1,185,191
-------------+----------------------------------   F(61, 1185129)  =    245.73
       Model |   148777777        61  2438979.95   Prob > F        =    0.0000
    Residual |  1.1763e+10 1,185,129  9925.51382   R-squared       =    0.0125
-------------+----------------------------------   Adj R-squared   =    0.0124
       Total |  1.1912e+10 1,185,190  10050.5337   Root MSE        =    99.627

// regnocs
      Source |       SS           df       MS      Number of obs   = 1,185,191
-------------+----------------------------------   F(61, 1185130)  =  10905.78
       Model |  6.6031e+09        61   108246814   Prob > F        =    0.0000
    Residual |  1.1763e+10 1,185,130  9925.63578   R-squared       =    0.3595
-------------+----------------------------------   Adj R-squared   =    0.3595
       Total |  1.8366e+10 1,185,191  15496.4258   Root MSE        =    99.627

// regnocsstata (hascons false)
* https://www.theanalysisfactor.com/the-impact-of-removing-the-constant-from-a-regression-model-the-categorical-case/
	  Source |       SS           df       MS      Number of obs   = 1,185,191
-------------+----------------------------------   F(61, 1185129)  =    245.73
       Model |   148777777        61  2438979.95   Prob > F        =    0.0000
    Residual |  1.1763e+10 1,185,129  9925.51382   R-squared       =    0.0125
-------------+----------------------------------   Adj R-squared   =    0.0124
       Total |  1.1912e+10 1,185,190  10050.5337   Root MSE        =    99.627

	   
// regwet
Linear regression                               Number of obs     =  1,185,191
                                                F(61, 1185129)    =     127.98
                                                Prob > F          =     0.0000
                                                R-squared         =     0.0106
                                                Root MSE          =     100.55

// regwetnocs
Linear regression                               Number of obs     =  1,185,191
                                                F(61, 1185130)    =    8219.55
                                                Prob > F          =     0.0000
                                                R-squared         =     0.3566
                                                Root MSE          =     100.55
												
. summarize tuactdur24 p p_adapt p_regs p_regnocs p_regwets p_regwetnocs, sep(0)


    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |  3,922,807    73.58894    100.2249          1       1350
           p |     77,307    71.72921     11.0636   43.57337   111.0276
     p_adapt |     77,307    71.75366    11.08807   43.54549   110.9724
      p_regs |     77,245    71.68562    11.12782   43.34956   111.1587
   p_regnocs |     77,245     71.7274    11.10388   43.63028   111.6432
   p_regwets |     77,245     72.2204    10.59174   44.80517   113.4916
p_regwetnocs |     77,245    72.28581    10.57628   45.22171   113.8761

summarize tuactdur24 p p_adapt p_regs p_regnocs p_regwets p_regwetnocs if testsample ==1, sep(0)

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |     83,013     73.0235    98.92528          1       1295
           p |     77,307    71.72921     11.0636   43.57337   111.0276
     p_adapt |     77,307    71.75366    11.08807   43.54549   110.9724
      p_regs |     77,245    71.68562    11.12782   43.34956   111.1587
   p_regnocs |     77,245     71.7274    11.10388   43.63028   111.6432
   p_regwets |     77,245     72.2204    10.59174   44.80517   113.4916
p_regwetnocs |     77,245    72.28581    10.57628   45.22171   113.8761

gen diff_sqr_cv= (tuactdur24 - p)^2 if testsample==1
gen diff_sqr_adapt= (tuactdur24 - p_adapt)^2 if testsample==1
gen diff_sqr_regs= (tuactdur24 - p_regs)^2 if testsample==1
gen diff_sqr_regnocs= (tuactdur24 - p_regnocs)^2 if testsample==1
gen diff_sqr_regwets= (tuactdur24 - p_regwets)^2 if testsample==1
gen diff_sqr_regwetnocs= (tuactdur24 - p_regwetnocs)^2 if testsample==1

summarize diff_sqr_cv diff_sqr_adapt diff_sqr_regs diff_sqr_regnocs diff_sqr_regwets diff_sqr_regwetnocs, sep(0)

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
 diff_sqr_cv |     77,307    9599.034    29447.39   .0000557    1483479
diff_sqr_a~t |     77,307     9598.97    29442.87   .0000219    1483010
*diff_sqr_~gs|     77,245    9598.858    29457.23   .0000819    1483362
diff_s~gnocs |     77,245    9599.037    29453.89   2.52e-06    1483447
diff_sqr_~ts |     77,245    9601.538    29401.46   .0001338    1482128
diff_s~tnocs |     77,245    9601.685    29393.51   3.44e-06    1482097


. lassogof lasso_cv_single lasso_adapt_single, over(testsample) postselection

Postselection coefficients
-------------------------------------------------------------
Name         testsample |         MSE    R-squared        Obs
------------------------+------------------------------------
lasso_cv_single         |
                      0 |    9924.927       0.0125    1186151
                      1 |    9599.091       0.0150     77,307
------------------------+------------------------------------
lasso_adapt_single      |
                      0 |    9924.965       0.0125    1186151
                      1 |    9599.043       0.0150     77,307
-------------------------------------------------------------

summarize tuactdur24 p p_adapt p_regs p_regnocs p_regwets p_regwetnocs 
lassogof lasso_cv_single lasso_adapt_single, over(testsample) postselection
// lassocoef lasso_cv_single lasso_adapt_single, sort(coef, standardized) 

esttab lasso_cv_single lasso_adapt_single reg_single reg_noc_single using comparedur.html, se aic obslast scalar(F) bic r2 label title("Models for duration of time spent on single activities at a single stretch in a typical day") mtitle("LASSO CV" "LASSO Adaptive" "Linear regression" "Linear regression through the origin")

// Having checked all, the linear regression model outperformed the Lasso model by very small margins.
* Deviation from mean, comparable RMSE, and R-squared
save "atusdurmodels.dta", replace
drop diff_sqr_cv diff_sqr_adapt diff_sqr_regs diff_sqr_regnocs diff_sqr_regwets diff_sqr_regwetnocs

label define labelseason 1 "winter" 2 "shoulder" 3 "summer"
label values season labelseason
label define labellocation 1 "Home" 2 "Workplace" 3 "Not home"
label values location labellocation
label define labelaction 1 "weekend" 2 "off peak" 3 "day peak" 4 "critical peak" 5 "evening peak" 6 "cross peak", replace
label values action labelaction

* Predictions for the periods

* Cumulative time spent in a period on any activities
* Typical day 
Note "i.location"
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location if testsample == 0 , beta
est sto reg_day
predict p_day if testsample == 1 & ttdur!=.

* Weekend
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location if testsample == 0 & action == 1, beta
est sto reg_wknd
predict p_wknd if testsample == 1 & action == 1 & ttdur!=.

* off peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location if testsample == 0 & action == 2, beta
est sto reg_offpeak
predict p_offpeak if testsample == 1 & action == 2 & ttdur!=.

* day peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location if testsample == 0 & action == 3, beta
est sto reg_daypeak
predict p_daypeak if testsample == 1 & action == 3 & ttdur!=.

* critical peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location if testsample == 0 & action == 4, beta
est sto reg_cripeak
predict p_cripeak if testsample == 1 & action == 4 & ttdur!=.

* evening peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location if testsample == 0 & action == 5, beta
est sto reg_evepeak
predict p_evepeak if testsample == 1 & action == 5 & ttdur!=.

* cross peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location if testsample == 0 & action == 6, beta
est sto reg_crosspeak
predict p_crosspeak if testsample == 1 & action == 6 & ttdur!=.

"Try next"
* Try something around the impact of activities differences in time spent
"i.choice"
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location i.choice if testsample == 0 , beta
est sto reg_daych
predict p_daych if testsample == 1 & ttdur!=.

* Weekend
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location i.choice if testsample == 0 & action == 1, beta
est sto reg_wkndch
predict p_wkndch if testsample == 1 & action == 1 & ttdur!=.

* off peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location i.choice if testsample == 0 & action == 2, beta
est sto reg_offpeakch
predict p_offpeakch if testsample == 1 & action == 2 & ttdur!=.

* day peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location i.choice if testsample == 0 & action == 3, beta
est sto reg_daypeakch
predict p_daypeakch if testsample == 1 & action == 3 & ttdur!=.

* critical peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location i.choice if testsample == 0 & action == 4, beta
est sto reg_cripeakch
predict p_cripeakch if testsample == 1 & action == 4 & ttdur!=.

* evening peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location i.choice if testsample == 0 & action == 5, beta
est sto reg_evepeakch
predict p_evepeakch if testsample == 1 & action == 5 & ttdur!=.

* cross peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime i.location i.choice if testsample == 0 & action == 6, beta
est sto reg_crosspeakch
predict p_crosspeakch if testsample == 1 & action == 6 & ttdur!=.

"Exclude i.choice and i.location because these are not known prior"
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 , beta
est sto reg2_day
predict p2_day if testsample == 1 & ttdur!=.

* Weekend
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1, beta
est sto reg2_wknd
predict p2_wknd if testsample == 1 & action == 1 & ttdur!=.

* off peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2, beta
est sto reg2_offpeak
predict p2_offpeak if testsample == 1 & action == 2 & ttdur!=.

* day peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 3, beta
est sto reg2_daypeak
predict p2_daypeak if testsample == 1 & action == 3 & ttdur!=.

* critical peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4, beta
est sto reg2_cripeak
predict p2_cripeak if testsample == 1 & action == 4 & ttdur!=.

* evening peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 5, beta
est sto reg2_evepeak
predict p2_evepeak if testsample == 1 & action == 5 & ttdur!=.

* cross peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 6, beta
est sto reg2_crosspeak
predict p2_crosspeak if testsample == 1 & action == 6 & ttdur!=.


* Compare results 
_est_reg_day _est_reg_wknd _est_reg_offpeak _est_reg_daypeak _est_reg_cripeak _est_reg_evepeak _est_reg_crosspeak _est_reg_daych _est_reg_wkndch _est_reg_offpeakch _est_reg_daypeakch _est_reg_cripeakch _est_reg_evepeakch _est_reg_crosspeakch

reg_day reg_wknd reg_offpeak reg_daypeak reg_cripeak reg_evepeak reg_crosspeak reg_daych reg_wkndch reg_offpeakch reg_daypeakch reg_cripeakch reg_evepeakch reg_crosspeakch

p_day p_wknd p_offpeak p_daypeak p_cripeak p_evepeak p_crosspeak p_daych p_wkndch p_offpeakch p_daypeakch p_cripeakch p_evepeakch p_crosspeakch  

diffsq_day diffsq_wknd diffsq_offpeak diffsq_daypeak diffsq_cripeak diffsq_evepeak diffsq_crosspeak diffsq_daych diffsq_wkndch diffsq_offpeakch diffsq_daypeakch diffsq_cripeakch diffsq_evepeakch diffsq_crosspeakch

summarize ttdur p_day if testsample == 1 & ttdur!=.
summarize ttdur p_wknd if testsample == 1 & action == 1 & ttdur!=.
summarize ttdur p_offpeak if testsample == 1 & action == 2 & ttdur!=.
summarize ttdur p_daypeak if testsample == 1 & action == 3 & ttdur!=.
summarize ttdur p_cripeak if testsample == 1 & action == 4 & ttdur!=.
summarize ttdur p_evepeak if testsample == 1 & action == 5 & ttdur!=.
summarize ttdur p_crosspeak if testsample == 1 & action == 6 & ttdur!=.
summarize ttdur p_daych if testsample == 1 & ttdur!=.
summarize ttdur p_wkndch if testsample == 1 & action == 1 & ttdur!=.
summarize ttdur p_offpeakch if testsample == 1 & action == 2 & ttdur!=.
summarize ttdur p_daypeakch if testsample == 1 & action == 3 & ttdur!=.
summarize ttdur p_cripeakch if testsample == 1 & action == 4 & ttdur!=.
summarize ttdur p_evepeakch if testsample == 1 & action == 5 & ttdur!=.
summarize ttdur p_crosspeakch if testsample == 1 & action == 6 & ttdur!=.

summarize ttdur p_day p_wknd p_offpeak p_daypeak p_cripeak p_evepeak p_crosspeak, sep(0)
summarize ttdur p_day p_wknd p_offpeak p_daypeak p_cripeak p_evepeak p_crosspeak if testsample ==1, sep(0)

gen diffsq_day = (ttdur - p_day)^2 if testsample==1
gen diffsq_wknd = (ttdur - p_wknd)^2 if testsample==1
gen diffsq_offpeak = (ttdur - p_offpeak)^2 if testsample==1
gen diffsq_daypeak = (ttdur - p_daypeak)^2 if testsample==1
gen diffsq_cripeak = (ttdur - p_cripeak)^2 if testsample==1
gen diffsq_evepeak = (ttdur - p_evepeak)^2 if testsample==1
gen diffsq_crosspeak = (ttdur - p_crosspeak)^2 if testsample==1

summarize diffsq_day diffsq_wknd diffsq_offpeak diffsq_daypeak diffsq_cripeak diffsq_evepeak diffsq_crosspeak, sep(0)

esttab reg_day reg_wknd reg_offpeak reg_daypeak reg_cripeak reg_evepeak reg_crosspeak using durperiods.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities across different periods of the day") mtitle("typical day" "weekend" "off peak" "day peak" "critical peak" "evening peak" "cross peak")
//
// summarize ttdur p_daych p_wkndch p_offpeakch p_daypeakch p_cripeakch p_evepeakch p_crosspeakch, sep(0)
// summarize ttdur p_daych p_wkndch p_offpeakch p_daypeakch p_cripeakch p_evepeakch p_crosspeakch if testsample ==1, sep(0)

gen diffsq_daych = (ttdur - p_daych)^2 if testsample==1
gen diffsq_wkndch = (ttdur - p_wkndch)^2 if testsample==1
gen diffsq_offpeakch = (ttdur - p_offpeakch)^2 if testsample==1
gen diffsq_daypeakch = (ttdur - p_daypeakch)^2 if testsample==1
gen diffsq_cripeakch = (ttdur - p_cripeakch)^2 if testsample==1
gen diffsq_evepeakch = (ttdur - p_evepeakch)^2 if testsample==1
gen diffsq_crosspeakch = (ttdur - p_crosspeakch)^2 if testsample==1

summarize diffsq_daych diffsq_wkndch diffsq_offpeakch diffsq_daypeakch diffsq_cripeakch diffsq_evepeakch diffsq_crosspeakch, sep(0)

esttab reg_daych reg_wkndch reg_offpeakch reg_daypeakch reg_cripeakch reg_evepeakch reg_crosspeakch using durperiodschoice.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities across different periods of the day considering choice") mtitle("typical day" "weekend" "off peak" "day peak" "critical peak" "evening peak" "cross peak")

* Correct curiosity of including choice and location
drop p_day p_wknd p_offpeak p_daypeak p_cripeak p_evepeak p_crosspeak p_daych p_wkndch p_offpeakch p_daypeakch p_cripeakch p_evepeakch p_crosspeakch diffsq_day diffsq_wknd diffsq_offpeak diffsq_daypeak diffsq_cripeak diffsq_evepeak diffsq_crosspeak diffsq_daych diffsq_wkndch diffsq_offpeakch diffsq_daypeakch diffsq_cripeakch diffsq_evepeakch diffsq_crosspeakch _est_reg_day _est_reg_wknd _est_reg_offpeak _est_reg_daypeak _est_reg_cripeak _est_reg_evepeak _est_reg_crosspeak _est_reg_daych _est_reg_wkndch _est_reg_offpeakch _est_reg_daypeakch _est_reg_cripeakch _est_reg_evepeakch _est_reg_crosspeakch

save "atusdurmodels.dta", replace

summarize ttdur p2_day if testsample == 1 & ttdur!=.
summarize ttdur p2_wknd if testsample == 1 & action == 1 & ttdur!=.
summarize ttdur p2_offpeak if testsample == 1 & action == 2 & ttdur!=.
summarize ttdur p2_daypeak if testsample == 1 & action == 3 & ttdur!=.
summarize ttdur p2_cripeak if testsample == 1 & action == 4 & ttdur!=.
summarize ttdur p2_evepeak if testsample == 1 & action == 5 & ttdur!=.
summarize ttdur p2_crosspeak if testsample == 1 & action == 6 & ttdur!=.
gen diffsq2_day = (ttdur - p2_day)^2 if testsample==1
gen diffsq2_wknd = (ttdur - p2_wknd)^2 if testsample==1
gen diffsq2_offpeak = (ttdur - p2_offpeak)^2 if testsample==1
gen diffsq2_daypeak = (ttdur - p2_daypeak)^2 if testsample==1
gen diffsq2_cripeak = (ttdur - p2_cripeak)^2 if testsample==1
gen diffsq2_evepeak = (ttdur - p2_evepeak)^2 if testsample==1
gen diffsq2_crosspeak = (ttdur - p2_crosspeak)^2 if testsample==1

summarize diffsq2_day diffsq2_wknd diffsq2_offpeak diffsq2_daypeak diffsq2_cripeak diffsq2_evepeak diffsq2_crosspeak, sep(0)

esttab reg2_day reg2_wknd reg2_offpeak reg2_daypeak reg2_cripeak reg2_evepeak reg2_crosspeak using durperiods2.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities across different periods of the day") mtitle("typical day" "weekend" "off peak" "day peak" "critical peak" "evening peak" "cross peak")

. summarize ttdur p2_day if testsample == 1 & ttdur!=.

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |     42,318    143.2322    166.3503          1       1310
      p2_day |     39,341    142.8236    53.71495   79.62778   261.4832

. 
. summarize ttdur p2_wknd if testsample == 1 & action == 1 & ttdur!=.

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |     13,457    219.4423    214.7051          1       1310
     p2_wknd |     12,488     218.955     15.4092   183.1482   281.2828

. 
. summarize ttdur p2_offpeak if testsample == 1 & action == 2 & ttdur!=.

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      3,974     74.8616    76.35277          1        420
  p2_offpeak |      3,687    74.38259    11.44378   49.82837   115.1636

. 
. summarize ttdur p2_daypeak if testsample == 1 & action == 3 & ttdur!=.

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      6,952    84.15607    93.67246          1       1070
  p2_daypeak |      6,467    84.68636    7.286616   64.35966    105.072

. 
. summarize ttdur p2_cripeak if testsample == 1 & action == 4 & ttdur!=.

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      6,651    60.52082    68.00196          1        810
  p2_cripeak |      6,167    60.95852    6.914584   47.02149   83.86819

. 
. summarize ttdur p2_evepeak if testsample == 1 & action == 5 & ttdur!=.

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      7,021    133.2756     134.923          1        540
  p2_evepeak |      6,572    132.0205    15.63641   101.2463   189.1363

. 
. summarize ttdur p2_crosspeak if testsample == 1 & action == 6 & ttdur!=.

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      4,263    208.1773    169.7725          5       1050
p2_crosspeak |      3,960    205.1166    32.85374    109.327   309.8326




* Activities list
computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork
* * Activity choice
computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork

* Consider different activities during critical peak
* critical peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & computeruse == 1, beta
est sto reg2_cripeak_computeruse
predict p2_cripeak_computeruse if testsample == 1 & action == 4 & ttdur!=. & computeruse == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & sleeping == 1, beta
est sto reg2_cripeak_sleeping
predict p2_cripeak_sleeping if testsample == 1 & action == 4 & ttdur!=. & sleeping == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & traveling == 1, beta
est sto reg2_cripeak_traveling
predict p2_cripeak_traveling if testsample == 1 & action == 4 & ttdur!=. & traveling == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & cleaning == 1, beta
est sto reg2_cripeak_cleaning
predict p2_cripeak_cleaning if testsample == 1 & action == 4 & ttdur!=. & cleaning == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & dishwashing == 1, beta
est sto reg2_cripeak_dishwashing
predict p2_cripeak_dishwashing if testsample == 1 & action == 4 & ttdur!=. & dishwashing == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & yardwork == 1, beta
est sto reg2_cripeak_yardwork
predict p2_cripeak_yardwork if testsample == 1 & action == 4 & ttdur!=. & yardwork == 1
    
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & cooking == 1, beta
est sto reg2_cripeak_cooking
predict p2_cripeak_cooking if testsample == 1 & action == 4 & ttdur!=. & cooking == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & pooluse == 1, beta
est sto reg2_cripeak_pooluse
predict p2_cripeak_pooluse if testsample == 1 & action == 4 & ttdur!=. & pooluse == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & TVgaming == 1, beta
est sto reg2_cripeak_TVgaming
predict p2_cripeak_TVgaming if testsample == 1 & action == 4 & ttdur!=. & TVgaming == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & exercise == 1, beta
est sto reg2_cripeak_exercise
predict p2_cripeak_exercise if testsample == 1 & action == 4 & ttdur!=. & exercise == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & laundry == 1, beta
est sto reg2_cripeak_laundry
predict p2_cripeak_laundry if testsample == 1 & action == 4 & ttdur!=. & laundry == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & justhome == 1, beta
est sto reg2_cripeak_justhome
predict p2_cripeak_justhome if testsample == 1 & action == 4 & ttdur!=. & justhome == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & away == 1, beta
est sto reg2_cripeak_away
predict p2_cripeak_away if testsample == 1 & action == 4 & ttdur!=. & away == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 4 & awayatwork == 1, beta
est sto reg2_cripeak_awayatwork
predict p2_cripeak_awayatwork if testsample == 1 & action == 4 & ttdur!=. & awayatwork == 1

// Now compare results for critical peak period
reg2_cripeak_computeruse reg2_cripeak_sleeping reg2_cripeak_traveling reg2_cripeak_cleaning reg2_cripeak_dishwashing reg2_cripeak_yardwork reg2_cripeak_cooking reg2_cripeak_pooluse reg2_cripeak_TVgaming reg2_cripeak_exercise reg2_cripeak_laundry reg2_cripeak_justhome reg2_cripeak_away reg2_cripeak_awayatwork

_est_reg2_cripeak_computeruse _est_reg2_cripeak_sleeping _est_reg2_cripeak_traveling _est_reg2_cripeak_cleaning _est_reg2_cripeak_dishwashing _est_reg2_cripeak_yardwork _est_reg2_cripeak_cooking _est_reg2_cripeak_pooluse _est_reg2_cripeak_TVgaming _est_reg2_cripeak_exercise _est_reg2_cripeak_laundry _est_reg2_cripeak_justhome _est_reg2_cripeak_away _est_reg2_cripeak_awayatwork

p2_cripeak_computeruse p2_cripeak_sleeping p2_cripeak_traveling p2_cripeak_cleaning p2_cripeak_dishwashing p2_cripeak_yardwork p2_cripeak_cooking p2_cripeak_pooluse p2_cripeak_TVgaming p2_cripeak_exercise p2_cripeak_laundry p2_cripeak_justhome p2_cripeak_away p2_cripeak_awayatwork

computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork

summarize ttdur p2_cripeak_computeruse if testsample == 1 & action == 4 & ttdur!=. & computeruse == 1
summarize ttdur p2_cripeak_sleeping if testsample == 1 & action == 4 & ttdur!=. & sleeping == 1
summarize ttdur p2_cripeak_traveling if testsample == 1 & action == 4 & ttdur!=. & traveling == 1
summarize ttdur p2_cripeak_traveling if testsample == 1 & action == 4 & ttdur!=. & cleaning == 1
summarize ttdur p2_cripeak_dishwashing if testsample == 1 & action == 4 & ttdur!=. & dishwashing == 1
summarize ttdur p2_cripeak_yardwork if testsample == 1 & action == 4 & ttdur!=. & yardwork == 1
summarize ttdur p2_cripeak_cooking if testsample == 1 & action == 4 & ttdur!=. & cooking == 1
summarize ttdur p2_cripeak_pooluse if testsample == 1 & action == 4 & ttdur!=. & pooluse == 1
summarize ttdur p2_cripeak_TVgaming if testsample == 1 & action == 4 & ttdur!=. & TVgaming == 1
summarize ttdur p2_cripeak_exercise if testsample == 1 & action == 4 & ttdur!=. & exercise == 1
summarize ttdur p2_cripeak_laundry if testsample == 1 & action == 4 & ttdur!=. & laundry == 1
summarize ttdur p2_cripeak_justhome if testsample == 1 & action == 4 & ttdur!=. & justhome == 1
summarize ttdur p2_cripeak_away if testsample == 1 & action == 4 & ttdur!=. & away == 1
summarize ttdur p2_cripeak_awayatwork if testsample == 1 & action == 4 & ttdur!=. & awayatwork == 1

gen diffsq2_cripeak_computeruse = (ttdur - p2_cripeak_computeruse)^2 if testsample==1 & action == 4 & ttdur!=. & computeruse == 1
gen diffsq2_cripeak_sleeping = (ttdur - p2_cripeak_sleeping)^2 if testsample==1 & action == 4 & ttdur!=. & sleeping == 1
gen diffsq2_cripeak_traveling = (ttdur - p2_cripeak_traveling)^2 if testsample==1 & action == 4 & ttdur!=. & traveling == 1
gen diffsq2_cripeak_cleaning = (ttdur - p2_cripeak_cleaning)^2 if testsample==1 & action == 4 & ttdur!=. & cleaning == 1
gen diffsq2_cripeak_dishwashing = (ttdur - p2_cripeak_dishwashing)^2 if testsample==1 & action == 4 & ttdur!=. & dishwashing == 1
gen diffsq2_cripeak_yardwork = (ttdur - p2_cripeak_yardwork)^2 if testsample==1 & action == 4 & ttdur!=. & yardwork == 1
gen diffsq2_cripeak_cooking = (ttdur - p2_cripeak_cooking)^2 if testsample==1 & action == 4 & ttdur!=. & cooking == 1
gen diffsq2_cripeak_pooluse = (ttdur - p2_cripeak_pooluse)^2 if testsample==1 & action == 4 & ttdur!=. & pooluse == 1
gen diffsq2_cripeak_TVgaming = (ttdur - p2_cripeak_TVgaming)^2 if testsample==1 & action == 4 & ttdur!=. & TVgaming == 1
gen diffsq2_cripeak_exercise = (ttdur - p2_cripeak_exercise)^2 if testsample==1 & action == 4 & ttdur!=. & exercise == 1
gen diffsq2_cripeak_laundry = (ttdur - p2_cripeak_laundry)^2 if testsample==1 & action == 4 & ttdur!=. & laundry == 1
gen diffsq2_cripeak_justhome = (ttdur - p2_cripeak_justhome)^2 if testsample==1 & action == 4 & ttdur!=. & justhome == 1
gen diffsq2_cripeak_away = (ttdur - p2_cripeak_away)^2 if testsample==1 & action == 4 & ttdur!=. & away == 1
gen diffsq2_cripeak_awayatwork = (ttdur - p2_cripeak_awayatwork)^2 if testsample==1 & action == 4 & ttdur!=. & awayatwork == 1

summarize diffsq2_cripeak_computeruse diffsq2_cripeak_sleeping diffsq2_cripeak_traveling diffsq2_cripeak_cleaning diffsq2_cripeak_dishwashing diffsq2_cripeak_yardwork diffsq2_cripeak_cooking diffsq2_cripeak_pooluse diffsq2_cripeak_TVgaming diffsq2_cripeak_exercise diffsq2_cripeak_laundry diffsq2_cripeak_justhome diffsq2_cripeak_away diffsq2_cripeak_awayatwork, sep(0)

esttab reg2_cripeak reg2_cripeak_justhome reg2_cripeak_sleeping reg2_cripeak_laundry reg2_cripeak_dishwashing reg2_cripeak_cooking reg2_cripeak_cleaning  reg2_cripeak_yardwork reg2_cripeak_exercise reg2_cripeak_pooluse reg2_cripeak_TVgaming reg2_cripeak_computeruse reg2_cripeak_traveling reg2_cripeak_awayatwork reg2_cripeak_away using durcritpeak.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during critical period") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )


. summarize ttdur p2_cripeak_computeruse if testsample == 1 & action == 4 & ttdur!=. & computeruse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         77    53.98701    37.89476          5        195
p2_crip~ruse |         75    65.79679    25.56507   4.115812   164.6811

. 
. summarize ttdur p2_cripeak_sleeping if testsample == 1 & action == 4 & ttdur!=. & sleeping == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        125     149.192    178.7681         10        775
p2_crip~ping |        110    143.2295    65.23219  -10.81493   315.2825

. 
. summarize ttdur p2_cripeak_traveling if testsample == 1 & action == 4 & ttdur!=. & traveling == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,524    39.88255    28.60065          1        271
p2_crip~ling |      1,418    40.16524    3.804863    27.3425   52.99377

. 
. summarize ttdur p2_cripeak_traveling if testsample == 1 & action == 4 & ttdur!=. & cleaning == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        516    33.99031    31.73699          1        210
p2_crip~ling |          0

. 
. summarize ttdur p2_cripeak_dishwashing if testsample == 1 & action == 4 & ttdur!=. & dishwashing == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        230     24.5913    15.03846          2         90
p2_crip~hing |        217    23.84148    3.201529   16.58789   39.85299

. 
. summarize ttdur p2_cripeak_yardwork if testsample == 1 & action == 4 & ttdur!=. & yardwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         64    67.57813    50.24758          4        195
p2_cri~dwork |         58    63.39363    14.91252   31.28856   95.44454

. 
. summarize ttdur p2_cripeak_cooking if testsample == 1 & action == 4 & ttdur!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        762     36.2664    25.73332          1        240
p2_crip~king |        708    38.51875    7.449288   19.91604   64.02429

. 
. summarize ttdur p2_cripeak_pooluse if testsample == 1 & action == 4 & ttdur!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |          1          20           .         20         20
p2_crip~luse |          1   -22.08677           .  -22.08677  -22.08677

. 
. summarize ttdur p2_cripeak_TVgaming if testsample == 1 & action == 4 & ttdur!=. & TVgaming == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        549    95.55738    95.41566          5        790
p2_crip~ming |        496     94.9862    25.48076   33.79309   174.8098

. 
. summarize ttdur p2_cripeak_exercise if testsample == 1 & action == 4 & ttdur!=. & exercise == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         91    66.46154    43.37493         15        300
p2_cripe~ise |         88    71.25846    18.75277   37.49289   122.2165

. 
. summarize ttdur p2_cripeak_laundry if testsample == 1 & action == 4 & ttdur!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        136    48.68382    72.93546          2        745
p2_cripea~ry |        134    39.99621    10.70272   15.70633   74.87852

. 
. summarize ttdur p2_cripeak_justhome if testsample == 1 & action == 4 & ttdur!=. & justhome == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,549    78.35249    71.03094          1        810
p2_cripea~me |      1,431    76.95877    14.24044   34.15917   123.6786

. 
. summarize ttdur p2_cripeak_away if testsample == 1 & action == 4 & ttdur!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        851    56.62985    59.09906          1        710
p2_cripea~ay |        794    59.41548    11.02667   35.25352   94.68228

. 
. summarize ttdur p2_cripeak_awayatwork if testsample == 1 & action == 4 & ttdur!=. & awayatwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        265    139.8264    102.5876          1        765
p2_cri~twork |        245    142.1853    13.91412   99.10599    176.472



* Consider different activities during weekend
* Weekend
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1, beta
est sto reg2_wknd
predict p2_wknd if testsample == 1 & action == 1 & ttdur!=.

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & computeruse == 1, beta
est sto reg2_wknd_computeruse
predict p2_wknd_computeruse if testsample == 1 & action == 1 & ttdur!=. & computeruse == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & sleeping == 1, beta
est sto reg2_wknd_sleeping
predict p2_wknd_sleeping if testsample == 1 & action == 1 & ttdur!=. & sleeping == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & traveling == 1, beta
est sto reg2_wknd_traveling
predict p2_wknd_traveling if testsample == 1 & action == 1 & ttdur!=. & traveling == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & cleaning == 1, beta
est sto reg2_wknd_cleaning
predict p2_wknd_cleaning if testsample == 1 & action == 1 & ttdur!=. & cleaning == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & dishwashing == 1, beta
est sto reg2_wknd_dishwashing
predict p2_wknd_dishwashing if testsample == 1 & action == 1 & ttdur!=. & dishwashing == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & yardwork == 1, beta
est sto reg2_wknd_yardwork
predict p2_wknd_yardwork if testsample == 1 & action == 1 & ttdur!=. & yardwork == 1
    
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & cooking == 1, beta
est sto reg2_wknd_cooking
predict p2_wknd_cooking if testsample == 1 & action == 1 & ttdur!=. & cooking == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & pooluse == 1, beta
est sto reg2_wknd_pooluse
predict p2_wknd_pooluse if testsample == 1 & action == 1 & ttdur!=. & pooluse == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & TVgaming == 1, beta
est sto reg2_wknd_TVgaming
predict p2_wknd_TVgaming if testsample == 1 & action == 1 & ttdur!=. & TVgaming == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & exercise == 1, beta
est sto reg2_wknd_exercise
predict p2_wknd_exercise if testsample == 1 & action == 1 & ttdur!=. & exercise == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & laundry == 1, beta
est sto reg2_wknd_laundry
predict p2_wknd_laundry if testsample == 1 & action == 1 & ttdur!=. & laundry == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & justhome == 1, beta
est sto reg2_wknd_justhome
predict p2_wknd_justhome if testsample == 1 & action == 1 & ttdur!=. & justhome == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & away == 1, beta
est sto reg2_wknd_away
predict p2_wknd_away if testsample == 1 & action == 1 & ttdur!=. & away == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 1 & awayatwork == 1, beta
est sto reg2_wknd_awayatwork
predict p2_wknd_awayatwork if testsample == 1 & action == 1 & ttdur!=. & awayatwork == 1

// Now compare results for weekend period
reg2_wknd_computeruse reg2_wknd_sleeping reg2_wknd_traveling reg2_wknd_cleaning reg2_wknd_dishwashing reg2_wknd_yardwork reg2_wknd_cooking reg2_wknd_pooluse reg2_wknd_TVgaming reg2_wknd_exercise reg2_wknd_laundry reg2_wknd_justhome reg2_wknd_away reg2_wknd_awayatwork

_est_reg2_wknd_computeruse _est_reg2_wknd_sleeping _est_reg2_wknd_traveling _est_reg2_wknd_cleaning _est_reg2_wknd_dishwashing _est_reg2_wknd_yardwork _est_reg2_wknd_cooking _est_reg2_wknd_pooluse _est_reg2_wknd_TVgaming _est_reg2_wknd_exercise _est_reg2_wknd_laundry _est_reg2_wknd_justhome _est_reg2_wknd_away _est_reg2_wknd_awayatwork

p2_wknd_computeruse p2_wknd_sleeping p2_wknd_traveling p2_wknd_cleaning p2_wknd_dishwashing p2_wknd_yardwork p2_wknd_cooking p2_wknd_pooluse p2_wknd_TVgaming p2_wknd_exercise p2_wknd_laundry p2_wknd_justhome p2_wknd_away p2_wknd_awayatwork

computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork

summarize ttdur p2_wknd_computeruse if testsample == 1 & action == 1 & ttdur!=. & computeruse == 1
summarize ttdur p2_wknd_sleeping if testsample == 1 & action == 1 & ttdur!=. & sleeping == 1
summarize ttdur p2_wknd_traveling if testsample == 1 & action == 1 & ttdur!=. & traveling == 1
summarize ttdur p2_wknd_traveling if testsample == 1 & action == 1 & ttdur!=. & cleaning == 1
summarize ttdur p2_wknd_dishwashing if testsample == 1 & action == 1 & ttdur!=. & dishwashing == 1
summarize ttdur p2_wknd_yardwork if testsample == 1 & action == 1 & ttdur!=. & yardwork == 1
summarize ttdur p2_wknd_cooking if testsample == 1 & action == 1 & ttdur!=. & cooking == 1
summarize ttdur p2_wknd_pooluse if testsample == 1 & action == 1 & ttdur!=. & pooluse == 1
summarize ttdur p2_wknd_TVgaming if testsample == 1 & action == 1 & ttdur!=. & TVgaming == 1
summarize ttdur p2_wknd_exercise if testsample == 1 & action == 1 & ttdur!=. & exercise == 1
summarize ttdur p2_wknd_laundry if testsample == 1 & action == 1 & ttdur!=. & laundry == 1
summarize ttdur p2_wknd_justhome if testsample == 1 & action == 1 & ttdur!=. & justhome == 1
summarize ttdur p2_wknd_away if testsample == 1 & action == 1 & ttdur!=. & away == 1
summarize ttdur p2_wknd_awayatwork if testsample == 1 & action == 1 & ttdur!=. & awayatwork == 1

gen diffsq2_wknd_computeruse = (ttdur - p2_wknd_computeruse)^2 if testsample==1 & action == 1 & ttdur!=. & computeruse == 1
gen diffsq2_wknd_sleeping = (ttdur - p2_wknd_sleeping)^2 if testsample==1 & action == 1 & ttdur!=. & sleeping == 1
gen diffsq2_wknd_traveling = (ttdur - p2_wknd_traveling)^2 if testsample==1 & action == 1 & ttdur!=. & traveling == 1
gen diffsq2_wknd_cleaning = (ttdur - p2_wknd_cleaning)^2 if testsample==1 & action == 1 & ttdur!=. & cleaning == 1
gen diffsq2_wknd_dishwashing = (ttdur - p2_wknd_dishwashing)^2 if testsample==1 & action == 1 & ttdur!=. & dishwashing == 1
gen diffsq2_wknd_yardwork = (ttdur - p2_wknd_yardwork)^2 if testsample==1 & action == 1 & ttdur!=. & yardwork == 1
gen diffsq2_wknd_cooking = (ttdur - p2_wknd_cooking)^2 if testsample==1 & action == 1 & ttdur!=. & cooking == 1
gen diffsq2_wknd_pooluse = (ttdur - p2_wknd_pooluse)^2 if testsample==1 & action == 1 & ttdur!=. & pooluse == 1
gen diffsq2_wknd_TVgaming = (ttdur - p2_wknd_TVgaming)^2 if testsample==1 & action == 1 & ttdur!=. & TVgaming == 1
gen diffsq2_wknd_exercise = (ttdur - p2_wknd_exercise)^2 if testsample==1 & action == 1 & ttdur!=. & exercise == 1
gen diffsq2_wknd_laundry = (ttdur - p2_wknd_laundry)^2 if testsample==1 & action == 1 & ttdur!=. & laundry == 1
gen diffsq2_wknd_justhome = (ttdur - p2_wknd_justhome)^2 if testsample==1 & action == 1 & ttdur!=. & justhome == 1
gen diffsq2_wknd_away = (ttdur - p2_wknd_away)^2 if testsample==1 & action == 1 & ttdur!=. & away == 1
gen diffsq2_wknd_awayatwork = (ttdur - p2_wknd_awayatwork)^2 if testsample==1 & action == 1 & ttdur!=. & awayatwork == 1

summarize diffsq2_wknd_computeruse diffsq2_wknd_sleeping diffsq2_wknd_traveling diffsq2_wknd_cleaning diffsq2_wknd_dishwashing diffsq2_wknd_yardwork diffsq2_wknd_cooking diffsq2_wknd_pooluse diffsq2_wknd_TVgaming diffsq2_wknd_exercise diffsq2_wknd_laundry diffsq2_wknd_justhome diffsq2_wknd_away diffsq2_wknd_awayatwork, sep(0)

esttab reg2_wknd reg2_wknd_justhome reg2_wknd_sleeping reg2_wknd_laundry reg2_wknd_dishwashing reg2_wknd_cooking reg2_wknd_cleaning  reg2_wknd_yardwork reg2_wknd_exercise reg2_wknd_pooluse reg2_wknd_TVgaming reg2_wknd_computeruse reg2_wknd_traveling reg2_wknd_awayatwork reg2_wknd_away using durweekend.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during weekend") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

esttab reg2_wknd reg2_wknd_computeruse reg2_wknd_sleeping reg2_wknd_traveling reg2_wknd_cleaning reg2_wknd_dishwashing reg2_wknd_yardwork reg2_wknd_cooking reg2_wknd_pooluse reg2_wknd_TVgaming reg2_wknd_exercise reg2_wknd_laundry reg2_wknd_justhome reg2_wknd_away reg2_wknd_awayatwork using durweekend2.html, se aic obslast scalar(F) bic r2 label nonumber 


. summarize ttdur p2_wknd_computeruse if testsample == 1 & action == 1 & ttdur!=. & computeruse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        223    87.17489    79.11054          5        506
p2_wknd_co~e |        208    93.76599    32.43741   31.58361   218.6283

. 
. summarize ttdur p2_wknd_sleeping if testsample == 1 & action == 1 & ttdur!=. & sleeping == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      2,058    556.7653     132.272         25       1260
p2_wknd_sl~g |      1,907    552.2463    38.78938   433.8955   687.5066

. 
. summarize ttdur p2_wknd_traveling if testsample == 1 & action == 1 & ttdur!=. & traveling == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,740    90.75115    96.10694          1       1145
p2_wknd_tr~g |      1,622    90.40184    17.17424   37.55017   170.1914

. 
. summarize ttdur p2_wknd_traveling if testsample == 1 & action == 1 & ttdur!=. & cleaning == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,687    86.82336    78.10415          2       1080
p2_wknd_tr~g |          0

. 
. summarize ttdur p2_wknd_dishwashing if testsample == 1 & action == 1 & ttdur!=. & dishwashing == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        456    36.55482    28.64227          2        240
p2_wknd_di~g |        423    35.61652    5.489248   19.25588   55.37257

. 
. summarize ttdur p2_wknd_yardwork if testsample == 1 & action == 1 & ttdur!=. & yardwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        190    134.1421    101.4035          5        480
p2_wknd_ya~k |        173     128.994    30.97196   28.92297   193.1846

. 
. summarize ttdur p2_wknd_cooking if testsample == 1 & action == 1 & ttdur!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,119    58.78999    55.02401          1        450
p2_wknd_co~g |      1,038    59.07585    12.22145   31.90433   108.4437

. 
. summarize ttdur p2_wknd_pooluse if testsample == 1 & action == 1 & ttdur!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |          7    71.71429    72.01091         10        192
p2_wknd_po~e |          7    98.86236    49.12733    32.4978   190.1993

. 
. summarize ttdur p2_wknd_TVgaming if testsample == 1 & action == 1 & ttdur!=. & TVgaming == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,700    250.5906    180.1931          1       1020
p2_wknd_TV~g |      1,580    238.6909     79.2938   34.58743   530.8088

. 
. summarize ttdur p2_wknd_exercise if testsample == 1 & action == 1 & ttdur!=. & exercise == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        276    145.8188    147.3492         10        715
p2_wknd_ex~e |        259    147.8104    43.17962   32.75719   246.3822

. 
. summarize ttdur p2_wknd_laundry if testsample == 1 & action == 1 & ttdur!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        456    74.64474    79.38617          1        810
p2_wknd_la~y |        420    74.61987    15.86685   35.99331    125.384

. 
. summarize ttdur p2_wknd_justhome if testsample == 1 & action == 1 & ttdur!=. & justhome == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,988    262.5885    187.2859          3       1080
p2_wknd_ju~e |      1,840    265.6593    44.02938   120.2174    420.433

. 
. summarize ttdur p2_wknd_away if testsample == 1 & action == 1 & ttdur!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,530    193.6157    158.1143          1       1075
p2_wknd_away |      1,422    200.9099    39.01938   79.52743   415.6559

. 
. summarize ttdur p2_wknd_awayatwork if testsample == 1 & action == 1 & ttdur!=. & awayatwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        240    456.6125     233.712          2       1310
p2_wknd_aw~k |        225    434.9341    75.97673    153.558   617.7577

. 


* Consider different activities during offpeak
* off peak
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2, beta
est sto reg2_offpeak
predict p2_offpeak if testsample == 1 & action == 2 & ttdur!=.

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & computeruse == 1, beta
est sto reg2_offpeak_computeruse
predict p2_offpeak_computeruse if testsample == 1 & action == 2 & ttdur!=. & computeruse == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & sleeping == 1, beta
est sto reg2_offpeak_sleeping
predict p2_offpeak_sleeping if testsample == 1 & action == 2 & ttdur!=. & sleeping == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & traveling == 1, beta
est sto reg2_offpeak_traveling
predict p2_offpeak_traveling if testsample == 1 & action == 2 & ttdur!=. & traveling == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & cleaning == 1, beta
est sto reg2_offpeak_cleaning
predict p2_offpeak_cleaning if testsample == 1 & action == 2 & ttdur!=. & cleaning == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & dishwashing == 1, beta
est sto reg2_offpeak_dishwashing
predict p2_offpeak_dishwashing if testsample == 1 & action == 2 & ttdur!=. & dishwashing == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & yardwork == 1, beta
est sto reg2_offpeak_yardwork
predict p2_offpeak_yardwork if testsample == 1 & action == 2 & ttdur!=. & yardwork == 1
    
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & cooking == 1, beta
est sto reg2_offpeak_cooking
predict p2_offpeak_cooking if testsample == 1 & action == 2 & ttdur!=. & cooking == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & pooluse == 1, beta
est sto reg2_offpeak_pooluse
predict p2_offpeak_pooluse if testsample == 1 & action == 2 & ttdur!=. & pooluse == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & TVgaming == 1, beta
est sto reg2_offpeak_TVgaming
predict p2_offpeak_TVgaming if testsample == 1 & action == 2 & ttdur!=. & TVgaming == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & exercise == 1, beta
est sto reg2_offpeak_exercise
predict p2_offpeak_exercise if testsample == 1 & action == 2 & ttdur!=. & exercise == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & laundry == 1, beta
est sto reg2_offpeak_laundry
predict p2_offpeak_laundry if testsample == 1 & action == 2 & ttdur!=. & laundry == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & justhome == 1, beta
est sto reg2_offpeak_justhome
predict p2_offpeak_justhome if testsample == 1 & action == 2 & ttdur!=. & justhome == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & away == 1, beta
est sto reg2_offpeak_away
predict p2_offpeak_away if testsample == 1 & action == 2 & ttdur!=. & away == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 & action == 2 & awayatwork == 1, beta
est sto reg2_offpeak_awayatwork
predict p2_offpeak_awayatwork if testsample == 1 & action == 2 & ttdur!=. & awayatwork == 1

// Now compare results for offpeak period
reg2_offpeak_computeruse reg2_offpeak_sleeping reg2_offpeak_traveling reg2_offpeak_cleaning reg2_offpeak_dishwashing reg2_offpeak_yardwork reg2_offpeak_cooking reg2_offpeak_pooluse reg2_offpeak_TVgaming reg2_offpeak_exercise reg2_offpeak_laundry reg2_offpeak_justhome reg2_offpeak_away reg2_offpeak_awayatwork

_est_reg2_offpeak_computeruse _est_reg2_offpeak_sleeping _est_reg2_offpeak_traveling _est_reg2_offpeak_cleaning _est_reg2_offpeak_dishwashing _est_reg2_offpeak_yardwork _est_reg2_offpeak_cooking _est_reg2_offpeak_pooluse _est_reg2_offpeak_TVgaming _est_reg2_offpeak_exercise _est_reg2_offpeak_laundry _est_reg2_offpeak_justhome _est_reg2_offpeak_away _est_reg2_offpeak_awayatwork

p2_offpeak_computeruse p2_offpeak_sleeping p2_offpeak_traveling p2_offpeak_cleaning p2_offpeak_dishwashing p2_offpeak_yardwork p2_offpeak_cooking p2_offpeak_pooluse p2_offpeak_TVgaming p2_offpeak_exercise p2_offpeak_laundry p2_offpeak_justhome p2_offpeak_away p2_offpeak_awayatwork

computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork

summarize ttdur p2_offpeak_computeruse if testsample == 1 & action == 2 & ttdur!=. & computeruse == 1
summarize ttdur p2_offpeak_sleeping if testsample == 1 & action == 2 & ttdur!=. & sleeping == 1
summarize ttdur p2_offpeak_traveling if testsample == 1 & action == 2 & ttdur!=. & traveling == 1
summarize ttdur p2_offpeak_traveling if testsample == 1 & action == 2 & ttdur!=. & cleaning == 1
summarize ttdur p2_offpeak_dishwashing if testsample == 1 & action == 2 & ttdur!=. & dishwashing == 1
summarize ttdur p2_offpeak_yardwork if testsample == 1 & action == 2 & ttdur!=. & yardwork == 1
summarize ttdur p2_offpeak_cooking if testsample == 1 & action == 2 & ttdur!=. & cooking == 1
summarize ttdur p2_offpeak_pooluse if testsample == 1 & action == 2 & ttdur!=. & pooluse == 1
summarize ttdur p2_offpeak_TVgaming if testsample == 1 & action == 2 & ttdur!=. & TVgaming == 1
summarize ttdur p2_offpeak_exercise if testsample == 1 & action == 2 & ttdur!=. & exercise == 1
summarize ttdur p2_offpeak_laundry if testsample == 1 & action == 2 & ttdur!=. & laundry == 1
summarize ttdur p2_offpeak_justhome if testsample == 1 & action == 2 & ttdur!=. & justhome == 1
summarize ttdur p2_offpeak_away if testsample == 1 & action == 2 & ttdur!=. & away == 1
summarize ttdur p2_offpeak_awayatwork if testsample == 1 & action == 2 & ttdur!=. & awayatwork == 1

gen diffsq2_offpeak_computeruse = (ttdur - p2_offpeak_computeruse)^2 if testsample==1 & action == 2 & ttdur!=. & computeruse == 1
gen diffsq2_offpeak_sleeping = (ttdur - p2_offpeak_sleeping)^2 if testsample==1 & action == 2 & ttdur!=. & sleeping == 1
gen diffsq2_offpeak_traveling = (ttdur - p2_offpeak_traveling)^2 if testsample==1 & action == 2 & ttdur!=. & traveling == 1
gen diffsq2_offpeak_cleaning = (ttdur - p2_offpeak_cleaning)^2 if testsample==1 & action == 2 & ttdur!=. & cleaning == 1
gen diffsq2_offpeak_dishwashing = (ttdur - p2_offpeak_dishwashing)^2 if testsample==1 & action == 2 & ttdur!=. & dishwashing == 1
gen diffsq2_offpeak_yardwork = (ttdur - p2_offpeak_yardwork)^2 if testsample==1 & action == 2 & ttdur!=. & yardwork == 1
gen diffsq2_offpeak_cooking = (ttdur - p2_offpeak_cooking)^2 if testsample==1 & action == 2 & ttdur!=. & cooking == 1
gen diffsq2_offpeak_pooluse = (ttdur - p2_offpeak_pooluse)^2 if testsample==1 & action == 2 & ttdur!=. & pooluse == 1
gen diffsq2_offpeak_TVgaming = (ttdur - p2_offpeak_TVgaming)^2 if testsample==1 & action == 2 & ttdur!=. & TVgaming == 1
gen diffsq2_offpeak_exercise = (ttdur - p2_offpeak_exercise)^2 if testsample==1 & action == 2 & ttdur!=. & exercise == 1
gen diffsq2_offpeak_laundry = (ttdur - p2_offpeak_laundry)^2 if testsample==1 & action == 2 & ttdur!=. & laundry == 1
gen diffsq2_offpeak_justhome = (ttdur - p2_offpeak_justhome)^2 if testsample==1 & action == 2 & ttdur!=. & justhome == 1
gen diffsq2_offpeak_away = (ttdur - p2_offpeak_away)^2 if testsample==1 & action == 2 & ttdur!=. & away == 1
gen diffsq2_offpeak_awayatwork = (ttdur - p2_offpeak_awayatwork)^2 if testsample==1 & action == 2 & ttdur!=. & awayatwork == 1

summarize diffsq2_offpeak_computeruse diffsq2_offpeak_sleeping diffsq2_offpeak_traveling diffsq2_offpeak_cleaning diffsq2_offpeak_dishwashing diffsq2_offpeak_yardwork diffsq2_offpeak_cooking diffsq2_offpeak_pooluse diffsq2_offpeak_TVgaming diffsq2_offpeak_exercise diffsq2_offpeak_laundry diffsq2_offpeak_justhome diffsq2_offpeak_away diffsq2_offpeak_awayatwork, sep(0)

esttab reg2_offpeak reg2_offpeak_justhome reg2_offpeak_sleeping reg2_offpeak_laundry reg2_offpeak_dishwashing reg2_offpeak_cooking reg2_offpeak_cleaning  reg2_offpeak_yardwork reg2_offpeak_exercise reg2_offpeak_pooluse reg2_offpeak_TVgaming reg2_offpeak_computeruse reg2_offpeak_traveling reg2_offpeak_awayatwork reg2_offpeak_away using duroffpeak.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during offpeak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

esttab reg2_offpeak reg2_offpeak_computeruse reg2_offpeak_sleeping reg2_offpeak_traveling reg2_offpeak_cleaning reg2_offpeak_dishwashing reg2_offpeak_yardwork reg2_offpeak_cooking reg2_offpeak_pooluse reg2_offpeak_TVgaming reg2_offpeak_exercise reg2_offpeak_laundry reg2_offpeak_justhome reg2_offpeak_away reg2_offpeak_awayatwork using duroffpeak2.html, se aic obslast scalar(F) bic r2 label nonumber

. summarize ttdur p2_offpeak_computeruse if testsample == 1 & action == 2 & ttdur!=. & computeruse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         17    61.52941    79.40255         10        345
p2_offp~ruse |         15    42.96389    22.76626    11.6987   83.97536

. 
. summarize ttdur p2_offpeak_sleeping if testsample == 1 & action == 2 & ttdur!=. & sleeping == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,448    147.2604     75.6946          1        420
p2_offp~ping |      1,344    148.3711    13.78179   114.8052   191.6649

. 
. summarize ttdur p2_offpeak_traveling if testsample == 1 & action == 2 & ttdur!=. & traveling == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        419    26.50358    23.01605          1        230
p2_offp~ling |        388    26.27719     3.78344   10.88453    37.2202

. 
. summarize ttdur p2_offpeak_traveling if testsample == 1 & action == 2 & ttdur!=. & cleaning == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        760       34.45    19.47642          1        120
p2_offp~ling |          0

. 
. summarize ttdur p2_offpeak_dishwashing if testsample == 1 & action == 2 & ttdur!=. & dishwashing == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         32    20.40625    20.20038          1        110
p2_offp~hing |         28    16.74535    4.808048   .4872456   26.40242

. 
. summarize ttdur p2_offpeak_yardwork if testsample == 1 & action == 2 & ttdur!=. & yardwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |          2        37.5    31.81981         15         60
p2_off~dwork |          1    34.57457           .   34.57457   34.57457

. 
. summarize ttdur p2_offpeak_cooking if testsample == 1 & action == 2 & ttdur!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        289    16.85813    14.44736          1        120
p2_offp~king |        268    16.40054     4.57248   6.959286   33.00642

. 
. summarize ttdur p2_offpeak_pooluse if testsample == 1 & action == 2 & ttdur!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |          0
p2_offp~luse |          0

. 
. summarize ttdur p2_offpeak_TVgaming if testsample == 1 & action == 2 & ttdur!=. & TVgaming == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        137    57.14599     44.3314          5        240
p2_offp~ming |        120    60.93291    23.26148   28.25118   230.3526

. 
. summarize ttdur p2_offpeak_exercise if testsample == 1 & action == 2 & ttdur!=. & exercise == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         55    44.03636    24.00846          5        120
p2_offpe~ise |         52    47.19313    8.114817   33.52876   70.75676

. 
. summarize ttdur p2_offpeak_laundry if testsample == 1 & action == 2 & ttdur!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         26    26.88462    21.76479          1         85
p2_offpea~ry |         24    20.92681    8.399713   8.149625   33.83789

. 
. summarize ttdur p2_offpeak_justhome if testsample == 1 & action == 2 & ttdur!=. & justhome == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        643     34.1493    33.33741          1        240
p2_offpea~me |        604    34.40599    7.482014    19.4543   66.82607

. 
. summarize ttdur p2_offpeak_away if testsample == 1 & action == 2 & ttdur!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        125      28.488    32.74427          1        180
p2_offpea~ay |        115    30.05792    10.14768   7.904286   58.44286

. 
. summarize ttdur p2_offpeak_awayatwork if testsample == 1 & action == 2 & ttdur!=. & awayatwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         64    87.85938    107.5323          2        405
p2_off~twork |         61    97.72347    34.04151   37.53811   224.9285


* Consider different activities during day
* During the day
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0 , beta
est sto reg2_day
predict p2_day if testsample == 1 & ttdur!=.

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & computeruse == 1, beta
est sto reg2_day_computeruse
predict p2_day_computeruse if testsample == 1  & ttdur!=. & computeruse == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & sleeping == 1, beta
est sto reg2_day_sleeping
predict p2_day_sleeping if testsample == 1  & ttdur!=. & sleeping == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & traveling == 1, beta
est sto reg2_day_traveling
predict p2_day_traveling if testsample == 1  & ttdur!=. & traveling == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & cleaning == 1, beta
est sto reg2_day_cleaning
predict p2_day_cleaning if testsample == 1  & ttdur!=. & cleaning == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & dishwashing == 1, beta
est sto reg2_day_dishwashing
predict p2_day_dishwashing if testsample == 1  & ttdur!=. & dishwashing == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & yardwork == 1, beta
est sto reg2_day_yardwork
predict p2_day_yardwork if testsample == 1  & ttdur!=. & yardwork == 1
    
regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & cooking == 1, beta
est sto reg2_day_cooking
predict p2_day_cooking if testsample == 1  & ttdur!=. & cooking == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & pooluse == 1, beta
est sto reg2_day_pooluse
predict p2_day_pooluse if testsample == 1  & ttdur!=. & pooluse == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & TVgaming == 1, beta
est sto reg2_day_TVgaming
predict p2_day_TVgaming if testsample == 1  & ttdur!=. & TVgaming == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & exercise == 1, beta
est sto reg2_day_exercise
predict p2_day_exercise if testsample == 1  & ttdur!=. & exercise == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & laundry == 1, beta
est sto reg2_day_laundry
predict p2_day_laundry if testsample == 1  & ttdur!=. & laundry == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & justhome == 1, beta
est sto reg2_day_justhome
predict p2_day_justhome if testsample == 1  & ttdur!=. & justhome == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & away == 1, beta
est sto reg2_day_away
predict p2_day_away if testsample == 1  & ttdur!=. & away == 1

regress ttdur i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime  if testsample == 0  & awayatwork == 1, beta
est sto reg2_day_awayatwork
predict p2_day_awayatwork if testsample == 1  & ttdur!=. & awayatwork == 1

// Now compare results for day period
reg2_day_computeruse reg2_day_sleeping reg2_day_traveling reg2_day_cleaning reg2_day_dishwashing reg2_day_yardwork reg2_day_cooking reg2_day_pooluse reg2_day_TVgaming reg2_day_exercise reg2_day_laundry reg2_day_justhome reg2_day_away reg2_day_awayatwork

_est_reg2_day_computeruse _est_reg2_day_sleeping _est_reg2_day_traveling _est_reg2_day_cleaning _est_reg2_day_dishwashing _est_reg2_day_yardwork _est_reg2_day_cooking _est_reg2_day_pooluse _est_reg2_day_TVgaming _est_reg2_day_exercise _est_reg2_day_laundry _est_reg2_day_justhome _est_reg2_day_away _est_reg2_day_awayatwork

p2_day_computeruse p2_day_sleeping p2_day_traveling p2_day_cleaning p2_day_dishwashing p2_day_yardwork p2_day_cooking p2_day_pooluse p2_day_TVgaming p2_day_exercise p2_day_laundry p2_day_justhome p2_day_away p2_day_awayatwork

computeruse sleeping traveling cleaning dishwashing yardwork cooking pooluse TVgaming exercise laundry justhome away awayatwork

summarize ttdur p2_day_computeruse if testsample == 1  & ttdur!=. & computeruse == 1
summarize ttdur p2_day_sleeping if testsample == 1  & ttdur!=. & sleeping == 1
summarize ttdur p2_day_traveling if testsample == 1  & ttdur!=. & traveling == 1
summarize ttdur p2_day_traveling if testsample == 1  & ttdur!=. & cleaning == 1
summarize ttdur p2_day_dishwashing if testsample == 1  & ttdur!=. & dishwashing == 1
summarize ttdur p2_day_yardwork if testsample == 1  & ttdur!=. & yardwork == 1
summarize ttdur p2_day_cooking if testsample == 1  & ttdur!=. & cooking == 1
summarize ttdur p2_day_pooluse if testsample == 1  & ttdur!=. & pooluse == 1
summarize ttdur p2_day_TVgaming if testsample == 1  & ttdur!=. & TVgaming == 1
summarize ttdur p2_day_exercise if testsample == 1  & ttdur!=. & exercise == 1
summarize ttdur p2_day_laundry if testsample == 1  & ttdur!=. & laundry == 1
summarize ttdur p2_day_justhome if testsample == 1  & ttdur!=. & justhome == 1
summarize ttdur p2_day_away if testsample == 1  & ttdur!=. & away == 1
summarize ttdur p2_day_awayatwork if testsample == 1  & ttdur!=. & awayatwork == 1

gen diffsq2_day_computeruse = (ttdur - p2_day_computeruse)^2 if testsample==1  & ttdur!=. & computeruse == 1
gen diffsq2_day_sleeping = (ttdur - p2_day_sleeping)^2 if testsample==1  & ttdur!=. & sleeping == 1
gen diffsq2_day_traveling = (ttdur - p2_day_traveling)^2 if testsample==1  & ttdur!=. & traveling == 1
gen diffsq2_day_cleaning = (ttdur - p2_day_cleaning)^2 if testsample==1  & ttdur!=. & cleaning == 1
gen diffsq2_day_dishwashing = (ttdur - p2_day_dishwashing)^2 if testsample==1  & ttdur!=. & dishwashing == 1
gen diffsq2_day_yardwork = (ttdur - p2_day_yardwork)^2 if testsample==1  & ttdur!=. & yardwork == 1
gen diffsq2_day_cooking = (ttdur - p2_day_cooking)^2 if testsample==1  & ttdur!=. & cooking == 1
gen diffsq2_day_pooluse = (ttdur - p2_day_pooluse)^2 if testsample==1  & ttdur!=. & pooluse == 1
gen diffsq2_day_TVgaming = (ttdur - p2_day_TVgaming)^2 if testsample==1  & ttdur!=. & TVgaming == 1
gen diffsq2_day_exercise = (ttdur - p2_day_exercise)^2 if testsample==1  & ttdur!=. & exercise == 1
gen diffsq2_day_laundry = (ttdur - p2_day_laundry)^2 if testsample==1  & ttdur!=. & laundry == 1
gen diffsq2_day_justhome = (ttdur - p2_day_justhome)^2 if testsample==1  & ttdur!=. & justhome == 1
gen diffsq2_day_away = (ttdur - p2_day_away)^2 if testsample==1  & ttdur!=. & away == 1
gen diffsq2_day_awayatwork = (ttdur - p2_day_awayatwork)^2 if testsample==1  & ttdur!=. & awayatwork == 1

summarize diffsq2_day_computeruse diffsq2_day_sleeping diffsq2_day_traveling diffsq2_day_cleaning diffsq2_day_dishwashing diffsq2_day_yardwork diffsq2_day_cooking diffsq2_day_pooluse diffsq2_day_TVgaming diffsq2_day_exercise diffsq2_day_laundry diffsq2_day_justhome diffsq2_day_away diffsq2_day_awayatwork, sep(0)

esttab reg2_day reg2_day_justhome reg2_day_sleeping reg2_day_laundry reg2_day_dishwashing reg2_day_cooking reg2_day_cleaning  reg2_day_yardwork reg2_day_exercise reg2_day_pooluse reg2_day_TVgaming reg2_day_computeruse reg2_day_traveling reg2_day_awayatwork reg2_day_away using durday.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during day") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

esttab reg2_day reg2_day_computeruse reg2_day_sleeping reg2_day_traveling reg2_day_cleaning reg2_day_dishwashing reg2_day_yardwork reg2_day_cooking reg2_day_pooluse reg2_day_TVgaming reg2_day_exercise reg2_day_laundry reg2_day_justhome reg2_day_away reg2_day_awayatwork using durday2.html, se aic obslast scalar(F) bic r2 label nonumber


. summarize ttdur p2_day_computeruse if testsample == 1  & ttdur!=. & computeruse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        588    82.46259    82.46775          5        640
p2_day_com~e |        561     82.2704    27.50927   19.73637   196.4837

. 
. summarize ttdur p2_day_sleeping if testsample == 1  & ttdur!=. & sleeping == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      6,246    356.2989    192.9881          1       1260
p2_day_sle~g |      5,794    354.1571    142.8604   190.9296   646.8743

. 
. summarize ttdur p2_day_traveling if testsample == 1  & ttdur!=. & traveling == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      6,065    53.07519     63.5852          1       1145
p2_day_tra~g |      5,651    53.18995    23.91462   22.84776   126.9934

. 
. summarize ttdur p2_day_traveling if testsample == 1  & ttdur!=. & cleaning == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      4,993    57.43341    62.65452          1       1080
p2_day_tra~g |          0

. 
. summarize ttdur p2_day_dishwashing if testsample == 1  & ttdur!=. & dishwashing == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,161    29.51249    22.88913          1        240
p2_day_dis~g |      1,076    29.57277    6.334054   13.75625   51.27404

. 
. summarize ttdur p2_day_yardwork if testsample == 1  & ttdur!=. & yardwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        382    110.9503    95.10983          4        570
p2_day_yar~k |        342    109.1215    29.97884   34.96947   177.0599

. 
. summarize ttdur p2_day_cooking if testsample == 1  & ttdur!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      2,961    42.17291    44.84096          1        570
p2_day_coo~g |      2,755    42.73573    15.38701   11.72879   105.7541

. 
. summarize ttdur p2_day_pooluse if testsample == 1  & ttdur!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         15        58.8    52.51014         10        192
p2_day_poo~e |         14    81.37526    33.07349   40.53122   133.9207

. 
. summarize ttdur p2_day_TVgaming if testsample == 1  & ttdur!=. & TVgaming == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      4,629    169.6595    149.6529          1       1020
p2_day_TVg~g |      4,269    165.6416    78.41636  -9.077148   430.5231

. 
. summarize ttdur p2_day_exercise if testsample == 1  & ttdur!=. & exercise == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        693    107.6681    116.9488          2        715
p2_day_exe~e |        656    109.3594    40.72185   19.17575    217.028

. 
. summarize ttdur p2_day_laundry if testsample == 1  & ttdur!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        934    63.02141    72.21987          1        810
p2_day_lau~y |        883    59.79294    19.43831   17.34421   121.3055

. 
. summarize ttdur p2_day_justhome if testsample == 1  & ttdur!=. & justhome == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      7,683    132.0472    145.3701          1       1080
p2_day_jus~e |      7,155    132.8792    78.83771   27.78276   327.8402

. 
. summarize ttdur p2_day_away if testsample == 1  & ttdur!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      4,421    121.9819    130.6327          1       1075
 p2_day_away |      4,121    125.5242    57.93948   15.96049   323.0847

. 
. summarize ttdur p2_day_awayatwork if testsample == 1  & ttdur!=. & awayatwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      2,166    276.3301     179.535          1       1310
p2_day_awa~k |      2,019    273.3053    65.00465   62.78958   505.6667

* Compare beta coefficients for justhome, laundry, and awayatwork activities at different periods
esttab reg2_day_justhome reg2_wknd_justhome reg2_cripeak_justhome reg2_offpeak_justhome using justhomeperiods.html, beta not aic obslast scalar(F) bic r2 label nonumber title("Duration models for just home activities during different periods related to HVAC or connected thermostats") mtitle("Typical day" "Weekend" "Critical peak" "Off-peak")

"Removed se"

esttab reg2_day_laundry reg2_wknd_laundry reg2_cripeak_laundry reg2_offpeak_laundry using laundryperiods.html, beta not aic obslast scalar(F) bic r2 label nonumber title("Duration models for just laundry activities during different periods related to smart water heaters (SWH) and smart washing machine") mtitle("Typical day" "Weekend" "Critical peak" "Off-peak")

esttab reg2_day_awayatwork reg2_wknd_awayatwork reg2_cripeak_awayatwork reg2_offpeak_awayatwork using awayatworkperiods.html, beta not aic obslast scalar(F) bic r2 label nonumber title("Duration models for away at work activities during different periods related to remote DR control or EV charging") mtitle("Typical day" "Weekend" "Critical peak" "Off-peak")

*comparison examples
summarize tuactdur24 p p_adapt p_regs p_regnocs p_regwets p_regwetnocs, sep(0)
summarize tuactdur24 p p_adapt p_regs p_regnocs p_regwets p_regwetnocs if testsample ==1, sep(0)
gen diff_sqr_cv= (tuactdur24 - p)^2 if testsample==1

summarize diff_sqr_cv diff_sqr_adapt diff_sqr_regs diff_sqr_regnocs diff_sqr_regwets diff_sqr_regwetnocs, sep(0)

esttab macook macooksig macooksig1 macooksig2 macooksig3 macooksig4 using cooktimemodels.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for cooking activities across different periods of the day") mtitle("Cooking- all predictors" "Significant predictors" "Off-peak" "Peak" "Critical peak" "Cross-peak")

* Multinomial regression models
* Start
cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSmodels2.log, append
use "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusmodelpub.dta"
drop _est_cv2 _est_minBIC2 _est_adaptive2 _est_cv1_per _est_adaptive1_per _est_cv2_per _est_adaptive2_per _est_adaptive1 _est_cv1 _est_minBIC1 _est_dscv_across _est_dscv_lassoselect _est_dscv_all
save atuschmodels
tab choice
    Activity_choice |      Freq.     Percent        Cum.
--------------------+-----------------------------------
          Just_home |  1,024,433       26.11       26.11
           Sleeping |    440,776       11.24       37.35
            Laundry |     51,367        1.31       38.66
        Dishwashing |     59,552        1.52       40.18
            Cooking |    181,208        4.62       44.80
           Cleaning |    339,269        8.65       53.45
   Garden_yard_work |     25,185        0.64       54.09
           Exercise |     13,066        0.33       54.42
      Pool_pump_use |        795        0.02       54.44
        TV_Game_use |    325,110        8.29       62.73
       Computer_use |     27,823        0.71       63.44
Traveling_commuting |    775,526       19.77       83.21
      Away_for_work |    193,592        4.94       88.14
               Away |    465,105       11.86      100.00
--------------------+-----------------------------------
              Total |  3,922,807      100.00


summarize gtcbsa gtco teio1cow2 teio1cow teio1icd trdpftpt tehruslt prcowpg teschenr teernhry tryhhchild teernhro teern, sep(0)

describe trdpftpt prcowpg teschenr teernhry tehruslt tryhhchild teernhro teern teio1cow2 gtcbsa gtco tudurstop

* Testing Examples
esttab mc1 mc2 mc3 mc4 using comparechoicemodels1.html, eform z aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to being away") mtitle("Model 1-C" "Model 2-C" "Model 3-C" "Model 4-C")

esttab mlogit_period using testchoice.html, se aic obslast scalar(F) bic r2 label nonumber title("Choice model tested on each activity")

mlogit choice i.tesex i.pehspnon i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum proxinc i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.gereg i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.ieccmoistureregime if testsample == 0 & ttdur!=.
est sto mlogit_period
// margins, dydx(*) atmeans

esttab mlogit_period using testchoice.html, se aic obslast scalar(F) bic r2 label nonumber title("Choice model tested on each activity")

label define labelhetelhhd 0 "No telephone" 1 "Yes telephone", replace

label define labelhubus 0 "No business or farm" 1 "Yes: business or farm", replace

label define labeltrhhchild 0 "No hh children < 18" 1 "Yes: hh children < 18", replace

predict p_day* if testsample == 1 & ttdur!=.
summarize p_day* i.choice if testsample == 1 & ttdur!=., separator(15)

drop _est_mlogit_period p_day p_day1 p_day2 p_day3 p_day4 p_day5 p_day6 p_day7 p_day8 p_day9 p_day10 p_day11 p_day12 p_day13 p_day14

summarize p_day* i.choice if testsample == 1 & ttdur!=., separator(14)
summarize i.choice if testsample ==1 & ttdurday!=., sep(0)
summarize i.choice if testsample ==1 & tuactdur24!=., sep(0)

* variable list
i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg

* April 12, 2021 output results for presentations
save "atuschmodels.dta", replace
cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSchoicelog, append
use "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atuschmodels.dta"

* Choice model for any given day for DF activities
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & testsample == 0, baseoutcome(14)
est sto mlogit_typday
predict p_day* if testsample == 1 & ttdurday!=.

* trying to create a confusion matrix
egen pred_daymax = rowmax(p_day*)
g pred_daychoice = .
forv i=1/14 {
	replace pred_daychoice = `i' if (pred_daymax == p_day`i')
}
local choice_lab: value label choice
label values pred_daychoice `choice_lab'
tab pred_daychoice choice

summarize p_day* i.choice if testsample == 1 & ttdurday!=., separator(15)

* https://www.stata.com/statalist/archive/2011-07/msg00935.html
mlogit insure age male nonwhite i.site
predict prob*
egen pred_max = rowmax(prob*)

g pred_choice = .
forv i=1/3 {
 replace pred_choice = `i' if (pred_max == prob`i')
}
local insure_lab: value label insure
label values pred_choice `insure_lab'
tab pred_choice insure

* choice model during a period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & testsample == 0, baseoutcome(14) nolog
est sto mlogit_period
predict p_period* if testsample == 1 & ttdur!=.
egen pred_permax = rowmax(p_period*)
g pred_perchoice = .
forv i=1/14 {
	replace pred_perchoice = `i' if (pred_permax == p_period`i')
}
local choice_perlab: value label choice
label values pred_perchoice `choice_perlab'
tab pred_perchoice choice if testsample == 1 & ttdur!=.
summarize p_period* i.choice if testsample == 1 & ttdur!=., separator(15)

* choice model in an instant
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if tuactdur24!=. & testsample == 0, baseoutcome(14) nolog
est sto mlogit_inst
predict p_inst* if testsample == 1 & tuactdur24!=.
summarize p_inst* i.choice if testsample == 1 & tuactdur24!=., separator(15)

* choice model during critical period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & action==4 & testsample == 0, baseoutcome(14) nolog
est sto mlogit_cripeak
predict p_cripeak* if testsample == 1 & action==4 & ttdur!=.
summarize p_cripeak* i.choice if testsample == 1 & action==4 & ttdur!=., separator(15)

* choice model during offpeak period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & action==2 & testsample == 0, baseoutcome(14) nolog
est sto mlogit_offpeak
predict p_offpeak* if testsample == 1 & action==2 & ttdur!=.
summarize p_offpeak* i.choice if testsample == 1 & action==2 & ttdur!=., separator(15)

* choice model during weekend period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & action==1 & testsample == 0, baseoutcome(14) nolog
est sto mlogit_wknd
predict p_wknd* if testsample == 1 & action==1 & ttdurday!=.
summarize p_wknd* i.choice if testsample == 1 & action==1 & ttdurday!=., separator(15)

esttab mlogit_typday mlogit_period mlogit_inst using compchoicemodels1.html, eform se aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to being away") mtitle("Typical day" "Any period" "Single instance")

* Running parallel
cd "C:\Users\wolawale\Documents\on PC mode\ATUS new codes"
log using ATUSchoicelog2, append
use "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusmodelpub.dta"
drop _est_cv2 _est_minBIC2 _est_adaptive2 _est_cv1_per _est_adaptive1_per _est_cv2_per _est_adaptive2_per _est_adaptive1 _est_cv1 _est_minBIC1 _est_dscv_across _est_dscv_lassoselect _est_dscv_all 
save "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atuschmodels2.dta"

summarize i.choice if testsample ==1 & ttdurday!=., sep(0)
summarize i.choice if testsample == 1 & ttdur!=., separator(0)
summarize i.choice if testsample ==1 & tuactdur24!=., sep(0)

summarize i.choice if testsample ==0 & ttdurday!=., sep(0)
summarize i.choice if testsample == 0 & ttdur!=., sep(0)
summarize i.choice if testsample ==0 & tuactdur24!=., sep(0)

summarize i.choice if ttdurday!=., sep(0)
summarize i.choice if ttdur!=., sep(0)
summarize i.choice if tuactdur24!=., sep(0)

table choice if testsample ==1 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if testsample ==1 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 
table choice if testsample ==1 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24) 

table choice if testsample ==0 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if testsample ==0 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 
table choice if testsample ==0 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24) 

table choice if ttdurday<., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if ttdur<., contents(N tucaseid mean ttdur sd ttdur) 
table choice if tuactdur24<., contents(N tucaseid mean tuactdur24 sd tuactdur24) 

* Try lasso adapt, cv, and regress on parallel run
* for a given day for any activity
lasso linear ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & testsample == 0, nolog rseed(1234)
cvplot
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv3day_cvplot.gph"
graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv3day_cvplot.jpg", as(jpg) name("Graph") quality(100)
est sto cv3_day
predict r_cv_day if ttdurday!=. & testsample == 1

lasso linear ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & testsample == 0, nolog selection(adaptive) rseed(1234)
est sto adapt3_day
predict r_adapt_day if ttdurday!=. & testsample == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & testsample == 0, beta
est sto reg3_day
predict r_reg_day if ttdurday!=. & testsample == 1

lassocoef cv3_day adapt3_day, sort(coef, standardized) nofvlabel
lassogof cv3_day adapt3_day, over(testsample) postselection

summarize ttdurday r_cv_day r_adapt_day r_reg_day if ttdurday!=. & testsample == 1, sep(0)

* for a given period
lasso linear ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & testsample == 0, nolog rseed(1234)
cvplot
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv3per_cvplot.gph"
graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv3per_cvplot.jpg", as(jpg) name("Graph") quality(100)
est sto cv3_period
predict r_cv_period if ttdur!=. & testsample == 1

lasso linear ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & testsample == 0, nolog selection(adaptive) rseed(1234)
est sto adapt3_period
predict r_adapt_period if ttdur!=. & testsample == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & testsample == 0, beta
est sto reg3_period
predict r_reg_period if ttdur!=. & testsample == 1

lassocoef cv3_period adapt3_period, sort(coef, standardized) nofvlabel
lassogof cv3_period adapt3_period, over(testsample) postselection

summarize ttdur r_cv_period r_adapt_period r_reg_period if ttdur!=. & testsample == 1, sep(0)

*for a single instance
lasso linear tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if tuactdur24!=. & testsample == 0, nolog rseed(1234)
cvplot
graph save "Graph" "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv3inst_cvplot.gph"
graph export "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\cv3inst_cvplot.jpg", as(jpg) name("Graph") quality(100)
est sto cv3_inst
predict r_cv_inst if tuactdur24!=. & testsample == 1

lasso linear tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if tuactdur24!=. & testsample == 0, nolog selection(adaptive) rseed(1234)
est sto adapt3_inst
predict r_adapt_inst if tuactdur24!=. & testsample == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if tuactdur24!=. & testsample == 0, beta
est sto reg3_inst
predict r_reg_inst if tuactdur24!=. & testsample == 1

lassocoef cv3_inst adapt3_inst, sort(coef, standardized) nofvlabel
lassogof cv3_inst adapt3_inst, over(testsample) postselection

summarize tuactdur24 r_cv_inst r_adapt_inst r_reg_inst if tuactdur24!=. & testsample == 1, sep(0)

* regression models
* day
regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0 , beta
est sto reg3_day
predict r_reg_day if testsample == 1 & ttdurday!=.

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & computeruse == 1, beta
est sto reg3_day_computeruse
predict p3_day_computeruse if testsample == 1  & ttdurday!=. & computeruse == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & sleeping == 1, beta
est sto reg3_day_sleeping
predict p3_day_sleeping if testsample == 1  & ttdurday!=. & sleeping == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & traveling == 1, beta
est sto reg3_day_traveling
predict p3_day_traveling if testsample == 1  & ttdurday!=. & traveling == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cleaning == 1, beta
est sto reg3_day_cleaning
predict p3_day_cleaning if testsample == 1  & ttdurday!=. & cleaning == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & dishwashing == 1, beta
est sto reg3_day_dishwashing
predict p3_day_dishwashing if testsample == 1  & ttdurday!=. & dishwashing == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & yardwork == 1, beta
est sto reg3_day_yardwork
predict p3_day_yardwork if testsample == 1  & ttdurday!=. & yardwork == 1
    
regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cooking == 1, beta
est sto reg3_day_cooking
predict p3_day_cooking if testsample == 1  & ttdurday!=. & cooking == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & pooluse == 1, beta
est sto reg3_day_pooluse
predict p3_day_pooluse if testsample == 1  & ttdurday!=. & pooluse == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & TVgaming == 1, beta
est sto reg3_day_TVgaming
predict p3_day_TVgaming if testsample == 1  & ttdurday!=. & TVgaming == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & exercise == 1, beta
est sto reg3_day_exercise
predict p3_day_exercise if testsample == 1  & ttdurday!=. & exercise == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & laundry == 1, beta
est sto reg3_day_laundry
predict p3_day_laundry if testsample == 1  & ttdurday!=. & laundry == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & justhome == 1, beta
est sto reg3_day_justhome
predict p3_day_justhome if testsample == 1  & ttdurday!=. & justhome == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & away == 1, beta
est sto reg3_day_away
predict p3_day_away if testsample == 1  & ttdurday!=. & away == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & awayatwork == 1, beta
est sto reg3_day_awayatwork
predict p3_day_awayatwork if testsample == 1  & ttdurday!=. & awayatwork == 1

// Now compare results for day 
summarize ttdurday p3_day_justhome if testsample == 1  & ttdurday!=. & justhome == 1
summarize ttdurday p3_day_sleeping if testsample == 1  & ttdurday!=. & sleeping == 1
summarize ttdurday p3_day_laundry if testsample == 1  & ttdurday!=. & laundry == 1
summarize ttdurday p3_day_dishwashing if testsample == 1  & ttdurday!=. & dishwashing == 1
summarize ttdurday p3_day_cooking if testsample == 1  & ttdurday!=. & cooking == 1
summarize ttdurday p3_day_cleaning if testsample == 1  & ttdurday!=. & cleaning == 1
summarize ttdurday p3_day_yardwork if testsample == 1  & ttdurday!=. & yardwork == 1
summarize ttdurday p3_day_exercise if testsample == 1  & ttdurday!=. & exercise == 1
summarize ttdurday p3_day_pooluse if testsample == 1  & ttdurday!=. & pooluse == 1
summarize ttdurday p3_day_TVgaming if testsample == 1  & ttdurday!=. & TVgaming == 1
summarize ttdurday p3_day_computeruse if testsample == 1  & ttdurday!=. & computeruse == 1
summarize ttdurday p3_day_traveling if testsample == 1  & ttdurday!=. & traveling == 1
summarize ttdurday p3_day_awayatwork if testsample == 1  & ttdurday!=. & awayatwork == 1
summarize ttdurday p3_day_away if testsample == 1  & ttdurday!=. & away == 1

gen diffsq3_day_computeruse = (ttdurday - p3_day_computeruse)^2 if testsample==1  & ttdurday!=. & computeruse == 1
gen diffsq3_day_sleeping = (ttdurday - p3_day_sleeping)^2 if testsample==1  & ttdurday!=. & sleeping == 1
gen diffsq3_day_traveling = (ttdurday - p3_day_traveling)^2 if testsample==1  & ttdurday!=. & traveling == 1
gen diffsq3_day_cleaning = (ttdurday - p3_day_cleaning)^2 if testsample==1  & ttdurday!=. & cleaning == 1
gen diffsq3_day_dishwashing = (ttdurday - p3_day_dishwashing)^2 if testsample==1  & ttdurday!=. & dishwashing == 1
gen diffsq3_day_yardwork = (ttdurday - p3_day_yardwork)^2 if testsample==1  & ttdurday!=. & yardwork == 1
gen diffsq3_day_cooking = (ttdurday - p3_day_cooking)^2 if testsample==1  & ttdurday!=. & cooking == 1
gen diffsq3_day_pooluse = (ttdurday - p3_day_pooluse)^2 if testsample==1  & ttdurday!=. & pooluse == 1
gen diffsq3_day_TVgaming = (ttdurday - p3_day_TVgaming)^2 if testsample==1  & ttdurday!=. & TVgaming == 1
gen diffsq3_day_exercise = (ttdurday - p3_day_exercise)^2 if testsample==1  & ttdurday!=. & exercise == 1
gen diffsq3_day_laundry = (ttdurday - p3_day_laundry)^2 if testsample==1  & ttdurday!=. & laundry == 1
gen diffsq3_day_justhome = (ttdurday - p3_day_justhome)^2 if testsample==1  & ttdurday!=. & justhome == 1
gen diffsq3_day_away = (ttdurday - p3_day_away)^2 if testsample==1  & ttdurday!=. & away == 1
gen diffsq3_day_awayatwork = (ttdurday - p3_day_awayatwork)^2 if testsample==1  & ttdurday!=. & awayatwork == 1

summarize diffsq3_day_justhome diffsq3_day_sleeping diffsq3_day_laundry diffsq3_day_dishwashing diffsq3_day_cooking diffsq3_day_cleaning diffsq3_day_yardwork diffsq3_day_exercise diffsq3_day_pooluse diffsq3_day_TVgaming diffsq3_day_computeruse diffsq3_day_traveling diffsq3_day_awayatwork diffsq3_day_away, sep(0)

esttab reg3_day reg3_day_justhome reg3_day_sleeping reg3_day_laundry reg3_day_dishwashing reg3_day_cooking reg3_day_cleaning  reg3_day_yardwork reg3_day_exercise reg3_day_pooluse reg3_day_TVgaming reg3_day_computeruse reg3_day_traveling reg3_day_awayatwork reg3_day_away using durdayslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during day") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

reg3_day_computeruse reg3_day_sleeping reg3_day_traveling reg3_day_cleaning reg3_day_dishwashing reg3_day_yardwork reg3_day_cooking reg3_day_pooluse reg3_day_TVgaming reg3_day_exercise reg3_day_laundry reg3_day_justhome reg3_day_away reg3_day_awayatwork

_est_reg3_day_computeruse _est_reg3_day_sleeping _est_reg3_day_traveling _est_reg3_day_cleaning _est_reg3_day_dishwashing _est_reg3_day_yardwork _est_reg3_day_cooking _est_reg3_day_pooluse _est_reg3_day_TVgaming _est_reg3_day_exercise _est_reg3_day_laundry _est_reg3_day_justhome _est_reg3_day_away _est_reg3_day_awayatwork

p3_day_computeruse p3_day_sleeping p3_day_traveling p3_day_cleaning p3_day_dishwashing p3_day_yardwork p3_day_cooking p3_day_pooluse p3_day_TVgaming p3_day_exercise p3_day_laundry p3_day_justhome p3_day_away p3_day_awayatwork

. summarize ttdurday p3_day_justhome if testsample == 1  & ttdurday!=. & justhome == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      4,076     248.919    192.5201          2       1220
p3_day_jus~e |      3,775    250.8804    54.07247    76.1347   450.9998

. 
. summarize ttdurday p3_day_sleeping if testsample == 1  & ttdurday!=. & sleeping == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      4,221    527.2739    133.9762         20       1370
p3_day_sle~g |      3,915     523.646    48.45861   398.5632    705.472

. 
. summarize ttdurday p3_day_laundry if testsample == 1  & ttdurday!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        847    68.57143    75.67767          1        810
p3_day_lau~y |        799    64.47374     17.7138   16.00632   144.3714

. 
. summarize ttdurday p3_day_dishwashing if testsample == 1  & ttdurday!=. & dishwashing == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,038    32.93545    24.69819          2        240
p3_day_dis~g |        958    33.06509    6.015773    16.0258   55.46206

. 
. summarize ttdurday p3_day_cooking if testsample == 1  & ttdurday!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      2,373    53.82343    56.05165          1        570
p3_day_coo~g |      2,205    55.06699    13.75514   12.66318   115.8431

. 
. summarize ttdurday p3_day_cleaning if testsample == 1  & ttdurday!=. & cleaning == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      3,585     79.9802    73.75233          1       1080
p3_day_cle~g |      3,330    79.14537    20.13655   27.77527   142.2631

. 
. summarize ttdurday p3_day_yardwork if testsample == 1  & ttdurday!=. & yardwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        358    117.8631    99.78653          4        570
p3_day_yar~k |        325    120.2577     30.7137   52.77303   194.5278

. 
. summarize ttdurday p3_day_exercise if testsample == 1  & ttdurday!=. & exercise == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        558    127.6613    139.6957         10        870
p3_day_exe~e |        530    135.8742    37.79159   44.32058   254.9463

. 
. summarize ttdurday p3_day_pooluse if testsample == 1  & ttdurday!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |         15        58.8    52.51014         10        192
p3_day_poo~e |         14    58.11109    21.10259   18.61176   93.04806

. 
. summarize ttdurday p3_day_TVgaming if testsample == 1  & ttdurday!=. & TVgaming == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      3,471    224.5295    176.0697          1       1150
p3_day_TVg~g |      3,224     217.166    86.37362  -12.35522     558.39

. 
. summarize ttdurday p3_day_computeruse if testsample == 1  & ttdurday!=. & computeruse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        514    94.27237    102.6343          5        880
p3_day_com~e |        488    92.12517    30.59996   35.04105   207.9274

. 
. summarize ttdurday p3_day_traveling if testsample == 1  & ttdurday!=. & traveling == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      3,617    88.58059    82.18492          1       1145
p3_day_tra~g |      3,367    88.28139    11.84668   48.40689   149.1882

. 
. summarize ttdurday p3_day_awayatwork if testsample == 1  & ttdurday!=. & awayatwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,238    483.4661    174.9796          2       1310
p3_day_awa~k |      1,152    484.0158    69.37028   134.8361   644.2686

. 
est sto reg3_period_computeruse
predict p3_period_computeruse if testsample == 1  & ttdur!=. & computeruse == 1
. summarize ttdurday p3_day_away if testsample == 1  & ttdurday!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      3,116    173.0494    159.9682          1       1230
 p3_day_away |      2,899    179.2116    42.12914   55.78775   417.4021


* per period per activity
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & computeruse == 1, beta

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & sleeping == 1, beta
est sto reg3_period_sleeping
predict p3_period_sleeping if testsample == 1  & ttdur!=. & sleeping == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & traveling == 1, beta
est sto reg3_period_traveling
predict p3_period_traveling if testsample == 1  & ttdur!=. & traveling == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cleaning == 1, beta
est sto reg3_period_cleaning
predict p3_period_cleaning if testsample == 1  & ttdur!=. & cleaning == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & dishwashing == 1, beta
est sto reg3_period_dishwashing
predict p3_period_dishwashing if testsample == 1  & ttdur!=. & dishwashing == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & yardwork == 1, beta
est sto reg3_period_yardwork
predict p3_period_yardwork if testsample == 1  & ttdur!=. & yardwork == 1
    
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cooking == 1, beta
est sto reg3_period_cooking
predict p3_period_cooking if testsample == 1  & ttdur!=. & cooking == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & pooluse == 1, beta
est sto reg3_period_pooluse
predict p3_period_pooluse if testsample == 1  & ttdur!=. & pooluse == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & TVgaming == 1, beta
est sto reg3_period_TVgaming
predict p3_period_TVgaming if testsample == 1  & ttdur!=. & TVgaming == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & exercise == 1, beta
est sto reg3_period_exercise
predict p3_period_exercise if testsample == 1  & ttdur!=. & exercise == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & laundry == 1, beta
est sto reg3_period_laundry
predict p3_period_laundry if testsample == 1  & ttdur!=. & laundry == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & justhome == 1, beta
est sto reg3_period_justhome
predict p3_period_justhome if testsample == 1  & ttdur!=. & justhome == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & away == 1, beta
est sto reg3_period_away
predict p3_period_away if testsample == 1  & ttdur!=. & away == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & awayatwork == 1, beta
est sto reg3_period_awayatwork
predict p3_period_awayatwork if testsample == 1  & ttdur!=. & awayatwork == 1

// Now compare results for period
summarize ttdur p3_period_justhome if testsample == 1  & ttdur!=. & justhome == 1
summarize ttdur p3_period_sleeping if testsample == 1  & ttdur!=. & sleeping == 1
summarize ttdur p3_period_laundry if testsample == 1  & ttdur!=. & laundry == 1
summarize ttdur p3_period_dishwashing if testsample == 1  & ttdur!=. & dishwashing == 1
summarize ttdur p3_period_cooking if testsample == 1  & ttdur!=. & cooking == 1
summarize ttdur p3_period_cleaning if testsample == 1  & ttdur!=. & cleaning == 1
summarize ttdur p3_period_yardwork if testsample == 1  & ttdur!=. & yardwork == 1
summarize ttdur p3_period_exercise if testsample == 1  & ttdur!=. & exercise == 1
summarize ttdur p3_period_pooluse if testsample == 1  & ttdur!=. & pooluse == 1
summarize ttdur p3_period_TVgaming if testsample == 1  & ttdur!=. & TVgaming == 1
summarize ttdur p3_period_computeruse if testsample == 1  & ttdur!=. & computeruse == 1
summarize ttdur p3_period_traveling if testsample == 1  & ttdur!=. & traveling == 1
summarize ttdur p3_period_awayatwork if testsample == 1  & ttdur!=. & awayatwork == 1
summarize ttdur p3_period_away if testsample == 1  & ttdur!=. & away == 1

gen diffsq3_period_computeruse = (ttdur - p3_period_computeruse)^2 if testsample==1  & ttdur!=. & computeruse == 1
gen diffsq3_period_sleeping = (ttdur - p3_period_sleeping)^2 if testsample==1  & ttdur!=. & sleeping == 1
gen diffsq3_period_traveling = (ttdur - p3_period_traveling)^2 if testsample==1  & ttdur!=. & traveling == 1
gen diffsq3_period_cleaning = (ttdur - p3_period_cleaning)^2 if testsample==1  & ttdur!=. & cleaning == 1
gen diffsq3_period_dishwashing = (ttdur - p3_period_dishwashing)^2 if testsample==1  & ttdur!=. & dishwashing == 1
gen diffsq3_period_yardwork = (ttdur - p3_period_yardwork)^2 if testsample==1  & ttdur!=. & yardwork == 1
gen diffsq3_period_cooking = (ttdur - p3_period_cooking)^2 if testsample==1  & ttdur!=. & cooking == 1
gen diffsq3_period_pooluse = (ttdur - p3_period_pooluse)^2 if testsample==1  & ttdur!=. & pooluse == 1
gen diffsq3_period_TVgaming = (ttdur - p3_period_TVgaming)^2 if testsample==1  & ttdur!=. & TVgaming == 1
gen diffsq3_period_exercise = (ttdur - p3_period_exercise)^2 if testsample==1  & ttdur!=. & exercise == 1
gen diffsq3_period_laundry = (ttdur - p3_period_laundry)^2 if testsample==1  & ttdur!=. & laundry == 1
gen diffsq3_period_justhome = (ttdur - p3_period_justhome)^2 if testsample==1  & ttdur!=. & justhome == 1
gen diffsq3_period_away = (ttdur - p3_period_away)^2 if testsample==1  & ttdur!=. & away == 1
gen diffsq3_period_awayatwork = (ttdur - p3_period_awayatwork)^2 if testsample==1  & ttdur!=. & awayatwork == 1

summarize diffsq3_period_justhome diffsq3_period_sleeping diffsq3_period_laundry diffsq3_period_dishwashing diffsq3_period_cooking diffsq3_period_cleaning diffsq3_period_yardwork diffsq3_period_exercise diffsq3_period_pooluse diffsq3_period_TVgaming diffsq3_period_computeruse diffsq3_period_traveling diffsq3_period_awayatwork diffsq3_period_away, sep(0)

esttab reg3_period reg3_period_justhome reg3_period_sleeping reg3_period_laundry reg3_period_dishwashing reg3_period_cooking reg3_period_cleaning  reg3_period_yardwork reg3_period_exercise reg3_period_pooluse reg3_period_TVgaming reg3_period_computeruse reg3_period_traveling reg3_period_awayatwork reg3_period_away using durperiodslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during day") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

reg3_period_computeruse reg3_period_sleeping reg3_period_traveling reg3_period_cleaning reg3_period_dishwashing reg3_period_yardwork reg3_period_cooking reg3_period_pooluse reg3_period_TVgaming reg3_period_exercise reg3_period_laundry reg3_period_justhome reg3_period_away reg3_period_awayatwork

_est_reg3_period_computeruse _est_reg3_period_sleeping _est_reg3_period_traveling _est_reg3_period_cleaning _est_reg3_period_dishwashing _est_reg3_period_yardwork _est_reg3_period_cooking _est_reg3_period_pooluse _est_reg3_period_TVgaming _est_reg3_period_exercise _est_reg3_period_laundry _est_reg3_period_justhome _est_reg3_period_away _est_reg3_period_awayatwork

p3_period_computeruse p3_period_sleeping p3_period_traveling p3_period_cleaning p3_period_dishwashing p3_period_yardwork p3_period_cooking p3_period_pooluse p3_period_TVgaming p3_period_exercise p3_period_laundry p3_period_justhome p3_period_away p3_period_awayatwork

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      7,683    132.0472    145.3701          1       1080
p3_period~me |      7,155    133.1648    79.73122   27.48656   331.9719

. 
. summarize ttdur p3_period_sleeping if testsample == 1  & ttdur!=. & sleeping == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      6,246    356.2989    192.9881          1       1260
p3_peri~ping |      5,794    354.3209    143.2031   191.7451   650.0786

. 
. summarize ttdur p3_period_laundry if testsample == 1  & ttdur!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        934    63.02141    72.21987          1        810
p3_period~ry |        883    58.20349    19.14408    13.9901   119.0778

. 
. summarize ttdur p3_period_dishwashing if testsample == 1  & ttdur!=. & dishwashing == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,161    29.51249    22.88913          1        240
p3_peri~hing |      1,076    29.66118    6.542009   14.89086   51.98312

. 
. summarize ttdur p3_period_cooking if testsample == 1  & ttdur!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      2,961    42.17291    44.84096          1        570
p3_peri~king |      2,755    43.63095    15.21457   10.84516   101.3193

. 
. summarize ttdur p3_period_cleaning if testsample == 1  & ttdur!=. & cleaning == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      4,993    57.43341    62.65452          1       1080
p3_peri~ning |      4,632    56.90239    24.10225   11.72739   126.0392

. 
. summarize ttdur p3_period_yardwork if testsample == 1  & ttdur!=. & yardwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        382    110.9503    95.10983          4        570
p3_per~dwork |        342    112.9119    31.95507   40.72111   188.2411

. 
. summarize ttdur p3_period_exercise if testsample == 1  & ttdur!=. & exercise == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        693    107.6681    116.9488          2        715
p3_perio~ise |        656    110.1294    42.61283   22.59671   231.7059

. 
. summarize ttdur p3_period_pooluse if testsample == 1  & ttdur!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         15        58.8    52.51014         10        192
p3_peri~luse |         14    57.48181    24.01668   14.22201   96.53143

. 
. summarize ttdur p3_period_TVgaming if testsample == 1  & ttdur!=. & TVgaming == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      4,629    169.6595    149.6529          1       1020
p3_peri~ming |      4,269    165.4156    78.52188  -12.49196   431.2969

. 
. summarize ttdur p3_period_computeruse if testsample == 1  & ttdur!=. & computeruse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        588    82.46259    82.46775          5        640
p3_peri~ruse |        561     81.7043    26.81639   22.56124   190.8201

. 
. summarize ttdur p3_period_traveling if testsample == 1  & ttdur!=. & traveling == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      6,065    53.07519     63.5852          1       1145
p3_peri~ling |      5,651    52.31174    23.69839    21.9606    125.537

. 
. summarize ttdur p3_period_awayatwork if testsample == 1  & ttdur!=. & awayatwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      2,166    276.3301     179.535          1       1310
p3_per~twork |      2,019     273.495    63.20948   40.12442   499.9502

. 
. summarize ttdur p3_period_away if testsample == 1  & ttdur!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      4,421    121.9819    130.6327          1       1075
p3_period~ay |      4,121    125.2759    57.91935   19.62919   327.2821

* single instances
regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & computeruse == 1, beta
est sto reg3_inst_computeruse
predict p3_inst_computeruse if testsample == 1  & tuactdur24!=. & computeruse == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & sleeping == 1, beta
est sto reg3_inst_sleeping
predict p3_inst_sleeping if testsample == 1  & tuactdur24!=. & sleeping == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & traveling == 1, beta
est sto reg3_inst_traveling
predict p3_inst_traveling if testsample == 1  & tuactdur24!=. & traveling == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cleaning == 1, beta
est sto reg3_inst_cleaning
predict p3_inst_cleaning if testsample == 1  & tuactdur24!=. & cleaning == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & dishwashing == 1, beta
est sto reg3_inst_dishwashing
predict p3_inst_dishwashing if testsample == 1  & tuactdur24!=. & dishwashing == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & yardwork == 1, beta
est sto reg3_inst_yardwork
predict p3_inst_yardwork if testsample == 1  & tuactdur24!=. & yardwork == 1
    
regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cooking == 1, beta
est sto reg3_inst_cooking
predict p3_inst_cooking if testsample == 1  & tuactdur24!=. & cooking == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & pooluse == 1, beta
est sto reg3_inst_pooluse
predict p3_inst_pooluse if testsample == 1  & tuactdur24!=. & pooluse == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & TVgaming == 1, beta
est sto reg3_inst_TVgaming
predict p3_inst_TVgaming if testsample == 1  & tuactdur24!=. & TVgaming == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & exercise == 1, beta
est sto reg3_inst_exercise
predict p3_inst_exercise if testsample == 1  & tuactdur24!=. & exercise == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & laundry == 1, beta
est sto reg3_inst_laundry
predict p3_inst_laundry if testsample == 1  & tuactdur24!=. & laundry == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & justhome == 1, beta
est sto reg3_inst_justhome
predict p3_inst_justhome if testsample == 1  & tuactdur24!=. & justhome == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & away == 1, beta
est sto reg3_inst_away
predict p3_inst_away if testsample == 1  & tuactdur24!=. & away == 1

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & awayatwork == 1, beta
est sto reg3_inst_awayatwork
predict p3_inst_awayatwork if testsample == 1  & tuactdur24!=. & awayatwork == 1

* Now compare results for single instances
summarize tuactdur24 p3_inst_justhome if testsample == 1  & tuactdur24!=. & justhome == 1
summarize tuactdur24 p3_inst_sleeping if testsample == 1  & tuactdur24!=. & sleeping == 1
summarize tuactdur24 p3_inst_laundry if testsample == 1  & tuactdur24!=. & laundry == 1
summarize tuactdur24 p3_inst_dishwashing if testsample == 1  & tuactdur24!=. & dishwashing == 1
summarize tuactdur24 p3_inst_cooking if testsample == 1  & tuactdur24!=. & cooking == 1
summarize tuactdur24 p3_inst_cleaning if testsample == 1  & tuactdur24!=. & cleaning == 1
summarize tuactdur24 p3_inst_yardwork if testsample == 1  & tuactdur24!=. & yardwork == 1
summarize tuactdur24 p3_inst_exercise if testsample == 1  & tuactdur24!=. & exercise == 1
summarize tuactdur24 p3_inst_pooluse if testsample == 1  & tuactdur24!=. & pooluse == 1
summarize tuactdur24 p3_inst_TVgaming if testsample == 1  & tuactdur24!=. & TVgaming == 1
summarize tuactdur24 p3_inst_computeruse if testsample == 1  & tuactdur24!=. & computeruse == 1
summarize tuactdur24 p3_inst_traveling if testsample == 1  & tuactdur24!=. & traveling == 1
summarize tuactdur24 p3_inst_awayatwork if testsample == 1  & tuactdur24!=. & awayatwork == 1
summarize tuactdur24 p3_inst_away if testsample == 1  & tuactdur24!=. & away == 1

gen diffsq3_inst_computeruse = (tuactdur24 - p3_inst_computeruse)^2 if testsample==1  & tuactdur24!=. & computeruse == 1
gen diffsq3_inst_sleeping = (tuactdur24 - p3_inst_sleeping)^2 if testsample==1  & tuactdur24!=. & sleeping == 1
gen diffsq3_inst_traveling = (tuactdur24 - p3_inst_traveling)^2 if testsample==1  & tuactdur24!=. & traveling == 1
gen diffsq3_inst_cleaning = (tuactdur24 - p3_inst_cleaning)^2 if testsample==1  & tuactdur24!=. & cleaning == 1
gen diffsq3_inst_dishwashing = (tuactdur24 - p3_inst_dishwashing)^2 if testsample==1  & tuactdur24!=. & dishwashing == 1
gen diffsq3_inst_yardwork = (tuactdur24 - p3_inst_yardwork)^2 if testsample==1  & tuactdur24!=. & yardwork == 1
gen diffsq3_inst_cooking = (tuactdur24 - p3_inst_cooking)^2 if testsample==1  & tuactdur24!=. & cooking == 1
gen diffsq3_inst_pooluse = (tuactdur24 - p3_inst_pooluse)^2 if testsample==1  & tuactdur24!=. & pooluse == 1
gen diffsq3_inst_TVgaming = (tuactdur24 - p3_inst_TVgaming)^2 if testsample==1  & tuactdur24!=. & TVgaming == 1
gen diffsq3_inst_exercise = (tuactdur24 - p3_inst_exercise)^2 if testsample==1  & tuactdur24!=. & exercise == 1
gen diffsq3_inst_laundry = (tuactdur24 - p3_inst_laundry)^2 if testsample==1  & tuactdur24!=. & laundry == 1
gen diffsq3_inst_justhome = (tuactdur24 - p3_inst_justhome)^2 if testsample==1  & tuactdur24!=. & justhome == 1
gen diffsq3_inst_away = (tuactdur24 - p3_inst_away)^2 if testsample==1  & tuactdur24!=. & away == 1
gen diffsq3_inst_awayatwork = (tuactdur24 - p3_inst_awayatwork)^2 if testsample==1  & tuactdur24!=. & awayatwork == 1

summarize diffsq3_inst_justhome diffsq3_inst_sleeping diffsq3_inst_laundry diffsq3_inst_dishwashing diffsq3_inst_cooking diffsq3_inst_cleaning diffsq3_inst_yardwork diffsq3_inst_exercise diffsq3_inst_pooluse diffsq3_inst_TVgaming diffsq3_inst_computeruse diffsq3_inst_traveling diffsq3_inst_awayatwork diffsq3_inst_away, sep(0)

esttab reg3_inst reg3_inst_justhome reg3_inst_sleeping reg3_inst_laundry reg3_inst_dishwashing reg3_inst_cooking reg3_inst_cleaning  reg3_inst_yardwork reg3_inst_exercise reg3_inst_pooluse reg3_inst_TVgaming reg3_inst_computeruse reg3_inst_traveling reg3_inst_awayatwork reg3_inst_away using durinstslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities in an instance") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

reg3_inst_computeruse reg3_inst_sleeping reg3_inst_traveling reg3_inst_cleaning reg3_inst_dishwashing reg3_inst_yardwork reg3_inst_cooking reg3_inst_pooluse reg3_inst_TVgaming reg3_inst_exercise reg3_inst_laundry reg3_inst_justhome reg3_inst_away reg3_inst_awayatwork

_est_reg3_inst_computeruse _est_reg3_inst_sleeping _est_reg3_inst_traveling _est_reg3_inst_cleaning _est_reg3_inst_dishwashing _est_reg3_inst_yardwork _est_reg3_inst_cooking _est_reg3_inst_pooluse _est_reg3_inst_TVgaming _est_reg3_inst_exercise _est_reg3_inst_laundry _est_reg3_inst_justhome _est_reg3_inst_away _est_reg3_inst_awayatwork

p3_inst_computeruse p3_inst_sleeping p3_inst_traveling p3_inst_cleaning p3_inst_dishwashing p3_inst_yardwork p3_inst_cooking p3_inst_pooluse p3_inst_TVgaming p3_inst_exercise p3_inst_laundry p3_inst_justhome p3_inst_away p3_inst_awayatwork

. summarize tuactdur24 p3_inst_justhome if testsample == 1  & tuactdur24!=. & justhome == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |     22,024    46.07923    60.05257          1        990
p3_inst_ju~e |     20,467    46.03124    7.762731   27.24332   80.13508

. 
. summarize tuactdur24 p3_inst_sleeping if testsample == 1  & tuactdur24!=. & sleeping == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |      9,233    241.0509    117.7359          1       1070
p3_inst_sl~g |      8,546    240.3436    18.24661   189.9651    303.582

. 
. summarize tuactdur24 p3_inst_laundry if testsample == 1  & tuactdur24!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |      1,214    48.29736    61.38655          1        810
p3_inst_la~y |      1,150     45.1233    12.44957   20.45213   89.65089

. 
. summarize tuactdur24 p3_inst_dishwashing if testsample == 1  & tuactdur24!=. & dishwashing == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |      1,320    25.98788    19.70614          1        240
p3_inst_di~g |      1,231    25.77287    3.614909   16.82805   41.17122

. 
. summarize tuactdur24 p3_inst_cooking if testsample == 1  & tuactdur24!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |      4,013    31.07276    33.35411          1        570
p3_inst_co~g |      3,754    31.50938    6.535513   19.59863   58.74629

. 
. summarize tuactdur24 p3_inst_cleaning if testsample == 1  & tuactdur24!=. & cleaning == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |      7,234    39.67432    44.08306          1       1060
p3_inst_cl~g |      6,697    39.10494    7.585534   18.48864   65.73674

. 
. summarize tuactdur24 p3_inst_yardwork if testsample == 1  & tuactdur24!=. & yardwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |        443    95.74041    81.73037          2        570
p3_inst_ya~k |        400    95.61375    21.61801   40.98701   148.9025

. 
. summarize tuactdur24 p3_inst_exercise if testsample == 1  & tuactdur24!=. & exercise == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |      1,170    72.35812    75.20862          2        680
p3_inst_ex~e |      1,115    74.30997    21.70795   10.39916   137.7095

. 
. summarize tuactdur24 p3_inst_pooluse if testsample == 1  & tuactdur24!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |         18          49    49.96234          2        180
p3_inst_po~e |         17    53.71787    16.31304   26.67793   76.41623

. 
. summarize tuactdur24 p3_inst_TVgaming if testsample == 1  & tuactdur24!=. & TVgaming == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |      7,063    111.1886    92.23841          1        930
p3_inst_TV~g |      6,509    110.1944    26.67806   40.11729   197.5446

. 
. summarize tuactdur24 p3_inst_computeruse if testsample == 1  & tuactdur24!=. & computeruse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |        718    66.64485    63.49259          1        640
p3_inst_co~e |        687    68.39185    20.18351   23.12088   146.9663

. 
. summarize tuactdur24 p3_inst_traveling if testsample == 1  & tuactdur24!=. & traveling == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |     16,374     19.3362    24.63131          1        930
p3_inst_tr~g |     15,283    18.61377    2.655389   9.163766   30.74268

. 
. summarize tuactdur24 p3_inst_awayatwork if testsample == 1  & tuactdur24!=. & awayatwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |      3,910     153.077    144.6485          1       1295
p3_inst_aw~k |      3,639    150.1247    21.52535   49.51353    220.723

. 
. summarize tuactdur24 p3_inst_away if testsample == 1  & tuactdur24!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  tuactdur24 |      9,658    55.83785    68.82311          1       1050
p3_inst_away |      9,062    56.18432     11.9007   23.77192   109.8093

drop diffsq3_inst_justhome diffsq3_inst_sleeping diffsq3_inst_laundry diffsq3_inst_dishwashing diffsq3_inst_cooking diffsq3_inst_cleaning diffsq3_inst_yardwork diffsq3_inst_exercise diffsq3_inst_pooluse diffsq3_inst_TVgaming diffsq3_inst_computeruse diffsq3_inst_traveling diffsq3_inst_awayatwork diffsq3_inst_away diffsq3_period_justhome diffsq3_period_sleeping diffsq3_period_laundry diffsq3_period_dishwashing diffsq3_period_cooking diffsq3_period_cleaning diffsq3_period_yardwork diffsq3_period_exercise diffsq3_period_pooluse diffsq3_period_TVgaming diffsq3_period_computeruse diffsq3_period_traveling diffsq3_period_awayatwork diffsq3_period_away diffsq3_day_justhome diffsq3_day_sleeping diffsq3_day_laundry diffsq3_day_dishwashing diffsq3_day_cooking diffsq3_day_cleaning diffsq3_day_yardwork diffsq3_day_exercise diffsq3_day_pooluse diffsq3_day_TVgaming diffsq3_day_computeruse diffsq3_day_traveling diffsq3_day_awayatwork diffsq3_day_awayatwork

save "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusallmodels.dta"

*critical peak periods
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0, beta
est sto reg3_cripeak
predict p3_cripeak if action == 4 & testsample == 1  & ttdur!=.

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & computeruse == 1, beta
est sto reg3_cripeak_computeruse
predict p3_cripeak_computeruse if action == 4 & testsample == 1  & ttdur!=. & computeruse == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & sleeping == 1, beta
est sto reg3_cripeak_sleeping
predict p3_cripeak_sleeping if action == 4 & testsample == 1  & ttdur!=. & sleeping == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & traveling == 1, beta
est sto reg3_cripeak_traveling
predict p3_cripeak_traveling if action == 4 & testsample == 1  & ttdur!=. & traveling == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & cleaning == 1, beta
est sto reg3_cripeak_cleaning
predict p3_cripeak_cleaning if action == 4 & testsample == 1  & ttdur!=. & cleaning == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & dishwashing == 1, beta
est sto reg3_cripeak_dishwashing
predict p3_cripeak_dishwashing if action == 4 & testsample == 1  & ttdur!=. & dishwashing == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & yardwork == 1, beta
est sto reg3_cripeak_yardwork
predict p3_cripeak_yardwork if action == 4 & testsample == 1  & ttdur!=. & yardwork == 1
    
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & cooking == 1, beta
est sto reg3_cripeak_cooking
predict p3_cripeak_cooking if action == 4 & testsample == 1  & ttdur!=. & cooking == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & pooluse == 1, beta
est sto reg3_cripeak_pooluse
predict p3_cripeak_pooluse if action == 4 & testsample == 1  & ttdur!=. & pooluse == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & TVgaming == 1, beta
est sto reg3_cripeak_TVgaming
predict p3_cripeak_TVgaming if action == 4 & testsample == 1  & ttdur!=. & TVgaming == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & exercise == 1, beta
est sto reg3_cripeak_exercise
predict p3_cripeak_exercise if action == 4 & testsample == 1  & ttdur!=. & exercise == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & laundry == 1, beta
est sto reg3_cripeak_laundry
predict p3_cripeak_laundry if action == 4 & testsample == 1  & ttdur!=. & laundry == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & justhome == 1, beta
est sto reg3_cripeak_justhome
predict p3_cripeak_justhome if action == 4 & testsample == 1  & ttdur!=. & justhome == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & away == 1, beta
est sto reg3_cripeak_away
predict p3_cripeak_away if action == 4 & testsample == 1  & ttdur!=. & away == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & awayatwork == 1, beta
est sto reg3_cripeak_awayatwork
predict p3_cripeak_awayatwork if action == 4 & testsample == 1  & ttdur!=. & awayatwork == 1

* Now compare results for critical peak period
summarize ttdur p3_cripeak_justhome if action == 4 & testsample == 1  & ttdur!=. & justhome == 1
summarize ttdur p3_cripeak_sleeping if action == 4 & testsample == 1  & ttdur!=. & sleeping == 1
summarize ttdur p3_cripeak_laundry if action == 4 & testsample == 1  & ttdur!=. & laundry == 1
summarize ttdur p3_cripeak_dishwashing if action == 4 & testsample == 1  & ttdur!=. & dishwashing == 1
summarize ttdur p3_cripeak_cooking if action == 4 & testsample == 1  & ttdur!=. & cooking == 1
summarize ttdur p3_cripeak_cleaning if action == 4 & testsample == 1  & ttdur!=. & cleaning == 1
summarize ttdur p3_cripeak_yardwork if action == 4 & testsample == 1  & ttdur!=. & yardwork == 1
summarize ttdur p3_cripeak_exercise if action == 4 & testsample == 1  & ttdur!=. & exercise == 1
summarize ttdur p3_cripeak_pooluse if action == 4 & testsample == 1  & ttdur!=. & pooluse == 1
summarize ttdur p3_cripeak_TVgaming if action == 4 & testsample == 1  & ttdur!=. & TVgaming == 1
summarize ttdur p3_cripeak_computeruse if action == 4 & testsample == 1  & ttdur!=. & computeruse == 1
summarize ttdur p3_cripeak_traveling if action == 4 & testsample == 1  & ttdur!=. & traveling == 1
summarize ttdur p3_cripeak_awayatwork if action == 4 & testsample == 1  & ttdur!=. & awayatwork == 1
summarize ttdur p3_cripeak_away if action == 4 & testsample == 1  & ttdur!=. & away == 1

gen diffsq3_cripeak_computeruse = (ttdur - p3_cripeak_computeruse)^2 if action == 4 & testsample==1  & ttdur!=. & computeruse == 1
gen diffsq3_cripeak_sleeping = (ttdur - p3_cripeak_sleeping)^2 if action == 4 & testsample==1  & ttdur!=. & sleeping == 1
gen diffsq3_cripeak_traveling = (ttdur - p3_cripeak_traveling)^2 if action == 4 & testsample==1  & ttdur!=. & traveling == 1
gen diffsq3_cripeak_cleaning = (ttdur - p3_cripeak_cleaning)^2 if action == 4 & testsample==1  & ttdur!=. & cleaning == 1
gen diffsq3_cripeak_dishwashing = (ttdur - p3_cripeak_dishwashing)^2 if action == 4 & testsample==1  & ttdur!=. & dishwashing == 1
gen diffsq3_cripeak_yardwork = (ttdur - p3_cripeak_yardwork)^2 if action == 4 & testsample==1  & ttdur!=. & yardwork == 1
gen diffsq3_cripeak_cooking = (ttdur - p3_cripeak_cooking)^2 if action == 4 & testsample==1  & ttdur!=. & cooking == 1
gen diffsq3_cripeak_pooluse = (ttdur - p3_cripeak_pooluse)^2 if action == 4 & testsample==1  & ttdur!=. & pooluse == 1
gen diffsq3_cripeak_TVgaming = (ttdur - p3_cripeak_TVgaming)^2 if action == 4 & testsample==1  & ttdur!=. & TVgaming == 1
gen diffsq3_cripeak_exercise = (ttdur - p3_cripeak_exercise)^2 if action == 4 & testsample==1  & ttdur!=. & exercise == 1
gen diffsq3_cripeak_laundry = (ttdur - p3_cripeak_laundry)^2 if action == 4 & testsample==1  & ttdur!=. & laundry == 1
gen diffsq3_cripeak_justhome = (ttdur - p3_cripeak_justhome)^2 if action == 4 & testsample==1  & ttdur!=. & justhome == 1
gen diffsq3_cripeak_away = (ttdur - p3_cripeak_away)^2 if action == 4 & testsample==1  & ttdur!=. & away == 1
gen diffsq3_cripeak_awayatwork = (ttdur - p3_cripeak_awayatwork)^2 if action == 4 & testsample==1  & ttdur!=. & awayatwork == 1

summarize diffsq3_cripeak_justhome diffsq3_cripeak_sleeping diffsq3_cripeak_laundry diffsq3_cripeak_dishwashing diffsq3_cripeak_cooking diffsq3_cripeak_cleaning diffsq3_cripeak_yardwork diffsq3_cripeak_exercise diffsq3_cripeak_pooluse diffsq3_cripeak_TVgaming diffsq3_cripeak_computeruse diffsq3_cripeak_traveling diffsq3_cripeak_awayatwork diffsq3_cripeak_away, sep(0)

esttab reg3_cripeak reg3_cripeak_justhome reg3_cripeak_sleeping reg3_cripeak_laundry reg3_cripeak_dishwashing reg3_cripeak_cooking reg3_cripeak_cleaning  reg3_cripeak_yardwork reg3_cripeak_exercise reg3_cripeak_pooluse reg3_cripeak_TVgaming reg3_cripeak_computeruse reg3_cripeak_traveling reg3_cripeak_awayatwork reg3_cripeak_away using durcripeakslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during critical peak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

reg3_cripeak_computeruse reg3_cripeak_sleeping reg3_cripeak_traveling reg3_cripeak_cleaning reg3_cripeak_dishwashing reg3_cripeak_yardwork reg3_cripeak_cooking reg3_cripeak_pooluse reg3_cripeak_TVgaming reg3_cripeak_exercise reg3_cripeak_laundry reg3_cripeak_justhome reg3_cripeak_away reg3_cripeak_awayatwork

_est_reg3_cripeak_computeruse _est_reg3_cripeak_sleeping _est_reg3_cripeak_traveling _est_reg3_cripeak_cleaning _est_reg3_cripeak_dishwashing _est_reg3_cripeak_yardwork _est_reg3_cripeak_cooking _est_reg3_cripeak_pooluse _est_reg3_cripeak_TVgaming _est_reg3_cripeak_exercise _est_reg3_cripeak_laundry _est_reg3_cripeak_justhome _est_reg3_cripeak_away _est_reg3_cripeak_awayatwork

p3_cripeak_computeruse p3_cripeak_sleeping p3_cripeak_traveling p3_cripeak_cleaning p3_cripeak_dishwashing p3_cripeak_yardwork p3_cripeak_cooking p3_cripeak_pooluse p3_cripeak_TVgaming p3_cripeak_exercise p3_cripeak_laundry p3_cripeak_justhome p3_cripeak_away p3_cripeak_awayatwork

. summarize ttdur p3_cripeak_justhome if action == 4 & testsample == 1  & ttdur!=. & justhome == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,549    78.35249    71.03094          1        810
p3_cripea~me |      1,431    76.36784    13.64528   37.82536   122.6218

. 
. summarize ttdur p3_cripeak_sleeping if action == 4 & testsample == 1  & ttdur!=. & sleeping == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        125     149.192    178.7681         10        775
p3_crip~ping |        110    149.8324    61.06614    2.90974   371.1069

. 
. summarize ttdur p3_cripeak_laundry if action == 4 & testsample == 1  & ttdur!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        136    48.68382    72.93546          2        745
p3_cripea~ry |        134    38.27307    9.737534   17.93445   74.93642

. 
. summarize ttdur p3_cripeak_dishwashing if action == 4 & testsample == 1  & ttdur!=. & dishwashi
> ng == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        230     24.5913    15.03846          2         90
p3_crip~hing |        217    23.34394    3.199505   15.08651   36.74897

. 
. summarize ttdur p3_cripeak_cooking if action == 4 & testsample == 1  & ttdur!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        762     36.2664    25.73332          1        240
p3_crip~king |        708    38.32857    7.044822   19.75363    61.3614

. 
. summarize ttdur p3_cripeak_cleaning if action == 4 & testsample == 1  & ttdur!=. & cleaning == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        516    33.99031    31.73699          1        210
p3_crip~ning |        480    33.31476    7.479486    17.5309   52.44104

. 
. summarize ttdur p3_cripeak_yardwork if action == 4 & testsample == 1  & ttdur!=. & yardwork == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         64    67.57813    50.24758          4        195
p3_cri~dwork |         58    63.94551    11.94733   43.40168   86.96384

. 
. summarize ttdur p3_cripeak_exercise if action == 4 & testsample == 1  & ttdur!=. & exercise == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         91    66.46154    43.37493         15        300
p3_cripe~ise |         88    74.19703    16.87388   41.64594   128.6591

. 
. summarize ttdur p3_cripeak_pooluse if action == 4 & testsample == 1  & ttdur!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |          1          20           .         20         20
p3_crip~luse |          1    62.67718           .   62.67718   62.67718

. 
. summarize ttdur p3_cripeak_TVgaming if action == 4 & testsample == 1  & ttdur!=. & TVgaming == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        549    95.55738    95.41566          5        790
p3_crip~ming |        496    93.72997    25.80343   34.66801    177.911

. 
. summarize ttdur p3_cripeak_computeruse if action == 4 & testsample == 1  & ttdur!=. & computeru
> se == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         77    53.98701    37.89476          5        195
p3_crip~ruse |         75    62.27174    18.59232   6.849011   110.8149

. 
. summarize ttdur p3_cripeak_traveling if action == 4 & testsample == 1  & ttdur!=. & traveling =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,524    39.88255    28.60065          1        271
p3_crip~ling |      1,418    39.00048    2.978619   29.39883   50.30597

. 
. summarize ttdur p3_cripeak_awayatwork if action == 4 & testsample == 1  & ttdur!=. & awayatwork
>  == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        265    139.8264    102.5876          1        765
p3_cri~twork |        245    141.5505     12.6402   60.81657   172.2702

. 
. summarize ttdur p3_cripeak_away if action == 4 & testsample == 1  & ttdur!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        851    56.62985    59.09906          1        710
p3_cripea~ay |        794    59.10831    10.57606   31.33148   92.63965



* off peak periods
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0, beta
est sto reg3_offpeak
predict p3_offpeak if action ==2 & testsample == 1  & ttdur!=.

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & computeruse == 1, beta
est sto reg3_offpeak_computeruse
predict p3_offpeak_computeruse if action ==2 & testsample == 1  & ttdur!=. & computeruse == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & sleeping == 1, beta
est sto reg3_offpeak_sleeping
predict p3_offpeak_sleeping if action ==2 & testsample == 1  & ttdur!=. & sleeping == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & traveling == 1, beta
est sto reg3_offpeak_traveling
predict p3_offpeak_traveling if action ==2 & testsample == 1  & ttdur!=. & traveling == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & cleaning == 1, beta
est sto reg3_offpeak_cleaning
predict p3_offpeak_cleaning if action ==2 & testsample == 1  & ttdur!=. & cleaning == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & dishwashing == 1, beta
est sto reg3_offpeak_dishwashing
predict p3_offpeak_dishwashing if action ==2 & testsample == 1  & ttdur!=. & dishwashing == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & yardwork == 1, beta
est sto reg3_offpeak_yardwork
predict p3_offpeak_yardwork if action ==2 & testsample == 1  & ttdur!=. & yardwork == 1
    
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & cooking == 1, beta
est sto reg3_offpeak_cooking
predict p3_offpeak_cooking if action ==2 & testsample == 1  & ttdur!=. & cooking == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & pooluse == 1, beta
est sto reg3_offpeak_pooluse
predict p3_offpeak_pooluse if action ==2 & testsample == 1  & ttdur!=. & pooluse == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & TVgaming == 1, beta
est sto reg3_offpeak_TVgaming
predict p3_offpeak_TVgaming if action ==2 & testsample == 1  & ttdur!=. & TVgaming == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & exercise == 1, beta
est sto reg3_offpeak_exercise
predict p3_offpeak_exercise if action ==2 & testsample == 1  & ttdur!=. & exercise == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & laundry == 1, beta
est sto reg3_offpeak_laundry
predict p3_offpeak_laundry if action ==2 & testsample == 1  & ttdur!=. & laundry == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & justhome == 1, beta
est sto reg3_offpeak_justhome
predict p3_offpeak_justhome if action ==2 & testsample == 1  & ttdur!=. & justhome == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & away == 1, beta
est sto reg3_offpeak_away
predict p3_offpeak_away if action ==2 & testsample == 1  & ttdur!=. & away == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & awayatwork == 1, beta
est sto reg3_offpeak_awayatwork
predict p3_offpeak_awayatwork if action ==2 & testsample == 1  & ttdur!=. & awayatwork == 1

* Now compare results for off peak period
summarize ttdur p3_offpeak_justhome if action ==2 & testsample == 1  & ttdur!=. & justhome == 1
summarize ttdur p3_offpeak_sleeping if action ==2 & testsample == 1  & ttdur!=. & sleeping == 1
summarize ttdur p3_offpeak_laundry if action ==2 & testsample == 1  & ttdur!=. & laundry == 1
summarize ttdur p3_offpeak_dishwashing if action ==2 & testsample == 1  & ttdur!=. & dishwashing == 1
summarize ttdur p3_offpeak_cooking if action ==2 & testsample == 1  & ttdur!=. & cooking == 1
summarize ttdur p3_offpeak_cleaning if action ==2 & testsample == 1  & ttdur!=. & cleaning == 1
summarize ttdur p3_offpeak_yardwork if action ==2 & testsample == 1  & ttdur!=. & yardwork == 1
summarize ttdur p3_offpeak_exercise if action ==2 & testsample == 1  & ttdur!=. & exercise == 1
summarize ttdur p3_offpeak_pooluse if action ==2 & testsample == 1  & ttdur!=. & pooluse == 1
summarize ttdur p3_offpeak_TVgaming if action ==2 & testsample == 1  & ttdur!=. & TVgaming == 1
summarize ttdur p3_offpeak_computeruse if action ==2 & testsample == 1  & ttdur!=. & computeruse == 1
summarize ttdur p3_offpeak_traveling if action ==2 & testsample == 1  & ttdur!=. & traveling == 1
summarize ttdur p3_offpeak_awayatwork if action ==2 & testsample == 1  & ttdur!=. & awayatwork == 1
summarize ttdur p3_offpeak_away if action ==2 & testsample == 1  & ttdur!=. & away == 1

gen diffsq3_offpeak_computeruse = (ttdur - p3_offpeak_computeruse)^2 if action ==2 & testsample==1  & ttdur!=. & computeruse == 1
gen diffsq3_offpeak_sleeping = (ttdur - p3_offpeak_sleeping)^2 if action ==2 & testsample==1  & ttdur!=. & sleeping == 1
gen diffsq3_offpeak_traveling = (ttdur - p3_offpeak_traveling)^2 if action ==2 & testsample==1  & ttdur!=. & traveling == 1
gen diffsq3_offpeak_cleaning = (ttdur - p3_offpeak_cleaning)^2 if action ==2 & testsample==1  & ttdur!=. & cleaning == 1
gen diffsq3_offpeak_dishwashing = (ttdur - p3_offpeak_dishwashing)^2 if action ==2 & testsample==1  & ttdur!=. & dishwashing == 1
gen diffsq3_offpeak_yardwork = (ttdur - p3_offpeak_yardwork)^2 if action ==2 & testsample==1  & ttdur!=. & yardwork == 1
gen diffsq3_offpeak_cooking = (ttdur - p3_offpeak_cooking)^2 if action ==2 & testsample==1  & ttdur!=. & cooking == 1
gen diffsq3_offpeak_pooluse = (ttdur - p3_offpeak_pooluse)^2 if action ==2 & testsample==1  & ttdur!=. & pooluse == 1
gen diffsq3_offpeak_TVgaming = (ttdur - p3_offpeak_TVgaming)^2 if action ==2 & testsample==1  & ttdur!=. & TVgaming == 1
gen diffsq3_offpeak_exercise = (ttdur - p3_offpeak_exercise)^2 if action ==2 & testsample==1  & ttdur!=. & exercise == 1
gen diffsq3_offpeak_laundry = (ttdur - p3_offpeak_laundry)^2 if action ==2 & testsample==1  & ttdur!=. & laundry == 1
gen diffsq3_offpeak_justhome = (ttdur - p3_offpeak_justhome)^2 if action ==2 & testsample==1  & ttdur!=. & justhome == 1
gen diffsq3_offpeak_away = (ttdur - p3_offpeak_away)^2 if action ==2 & testsample==1  & ttdur!=. & away == 1
gen diffsq3_offpeak_awayatwork = (ttdur - p3_offpeak_awayatwork)^2 if action ==2 & testsample==1  & ttdur!=. & awayatwork == 1

summarize diffsq3_offpeak_justhome diffsq3_offpeak_sleeping diffsq3_offpeak_laundry diffsq3_offpeak_dishwashing diffsq3_offpeak_cooking diffsq3_offpeak_cleaning diffsq3_offpeak_yardwork diffsq3_offpeak_exercise diffsq3_offpeak_pooluse diffsq3_offpeak_TVgaming diffsq3_offpeak_computeruse diffsq3_offpeak_traveling diffsq3_offpeak_awayatwork diffsq3_offpeak_away, sep(0)

esttab reg3_offpeak reg3_offpeak_justhome reg3_offpeak_sleeping reg3_offpeak_laundry reg3_offpeak_dishwashing reg3_offpeak_cooking reg3_offpeak_cleaning  reg3_offpeak_yardwork reg3_offpeak_exercise reg3_offpeak_pooluse reg3_offpeak_TVgaming reg3_offpeak_computeruse reg3_offpeak_traveling reg3_offpeak_awayatwork reg3_offpeak_away using duroffpeakslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during off peak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

reg3_offpeak_computeruse reg3_offpeak_sleeping reg3_offpeak_traveling reg3_offpeak_cleaning reg3_offpeak_dishwashing reg3_offpeak_yardwork reg3_offpeak_cooking reg3_offpeak_pooluse reg3_offpeak_TVgaming reg3_offpeak_exercise reg3_offpeak_laundry reg3_offpeak_justhome reg3_offpeak_away reg3_offpeak_awayatwork

_est_reg3_offpeak_computeruse _est_reg3_offpeak_sleeping _est_reg3_offpeak_traveling _est_reg3_offpeak_cleaning _est_reg3_offpeak_dishwashing _est_reg3_offpeak_yardwork _est_reg3_offpeak_cooking _est_reg3_offpeak_pooluse _est_reg3_offpeak_TVgaming _est_reg3_offpeak_exercise _est_reg3_offpeak_laundry _est_reg3_offpeak_justhome _est_reg3_offpeak_away _est_reg3_offpeak_awayatwork

p3_offpeak_computeruse p3_offpeak_sleeping p3_offpeak_traveling p3_offpeak_cleaning p3_offpeak_dishwashing p3_offpeak_yardwork p3_offpeak_cooking p3_offpeak_pooluse p3_offpeak_TVgaming p3_offpeak_exercise p3_offpeak_laundry p3_offpeak_justhome p3_offpeak_away p3_offpeak_awayatwork

. summarize ttdur p3_offpeak_justhome if action ==2 & testsample == 1  & ttdur!=. & justhome == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        643     34.1493    33.33741          1        240
p3_offpea~me |        604    34.80925    6.684691   20.26349   60.05974

. 
. summarize ttdur p3_offpeak_sleeping if action ==2 & testsample == 1  & ttdur!=. & sleeping == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,448    147.2604     75.6946          1        420
p3_offp~ping |      1,344    146.4775      13.749   114.7724   191.1462

. 
. summarize ttdur p3_offpeak_laundry if action ==2 & testsample == 1  & ttdur!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         26    26.88462    21.76479          1         85
p3_offpea~ry |         24    22.08248    9.123744   10.43812   39.60404

. 
. summarize ttdur p3_offpeak_dishwashing if action ==2 & testsample == 1  & ttdur!=. & dishwashin
> g == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         32    20.40625    20.20038          1        110
p3_offp~hing |         28    16.28586    2.899406   10.14874   22.46249

. 
. summarize ttdur p3_offpeak_cooking if action ==2 & testsample == 1  & ttdur!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        289    16.85813    14.44736          1        120
p3_offp~king |        268    16.67455    4.224193   6.545441   31.29852

. 
. summarize ttdur p3_offpeak_cleaning if action ==2 & testsample == 1  & ttdur!=. & cleaning == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        760       34.45    19.47642          1        120
p3_offp~ning |        706    33.39803    5.405137   17.88074   46.45293

. 
. summarize ttdur p3_offpeak_yardwork if action ==2 & testsample == 1  & ttdur!=. & yardwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |          2        37.5    31.81981         15         60
p3_off~dwork |          1    30.92767           .   30.92767   30.92767

. 
. summarize ttdur p3_offpeak_exercise if action ==2 & testsample == 1  & ttdur!=. & exercise == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         55    44.03636    24.00846          5        120
p3_offpe~ise |         52    47.42771    7.412961    33.2622   65.89999

. 
. summarize ttdur p3_offpeak_pooluse if action ==2 & testsample == 1  & ttdur!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |          0
p3_offp~luse |          0

. 
. summarize ttdur p3_offpeak_TVgaming if action ==2 & testsample == 1  & ttdur!=. & TVgaming == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        137    57.14599     44.3314          5        240
p3_offp~ming |        120    59.44675    18.36367   26.96734   145.4093

. 
. summarize ttdur p3_offpeak_computeruse if action ==2 & testsample == 1  & ttdur!=. & computerus
> e == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         17    61.52941    79.40255         10        345
p3_offp~ruse |         15    52.06583    25.95263   15.54815   100.6058

. 
. summarize ttdur p3_offpeak_traveling if action ==2 & testsample == 1  & ttdur!=. & traveling ==
>  1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        419    26.50358    23.01605          1        230
p3_offp~ling |        388    25.61314    3.508231   11.46487   44.22464

. 
. summarize ttdur p3_offpeak_awayatwork if action ==2 & testsample == 1  & ttdur!=. & awayatwork 
> == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         64    87.85938    107.5323          2        405
p3_off~twork |         61    93.15082    20.98493   40.71269   152.7424

. 
. summarize ttdur p3_offpeak_away if action ==2 & testsample == 1  & ttdur!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        125      28.488    32.74427          1        180
p3_offpea~ay |        115    29.35359    8.878641   13.57029   53.99426

*peak periods

gen peak = 1 if action ==3 | action ==5

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0, beta
est sto reg3_peak
predict p3_peak if peak ==1 & testsample == 1  & ttdur!=.

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & computeruse == 1, beta
est sto reg3_peak_computeruse
predict p3_peak_computeruse if peak ==1 & testsample == 1  & ttdur!=. & computeruse == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & sleeping == 1, beta
est sto reg3_peak_sleeping
predict p3_peak_sleeping if peak ==1 & testsample == 1  & ttdur!=. & sleeping == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & traveling == 1, beta
est sto reg3_peak_traveling
predict p3_peak_traveling if peak ==1 & testsample == 1  & ttdur!=. & traveling == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & cleaning == 1, beta
est sto reg3_peak_cleaning
predict p3_peak_cleaning if peak ==1 & testsample == 1  & ttdur!=. & cleaning == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & dishwashing == 1, beta
est sto reg3_peak_dishwashing
predict p3_peak_dishwashing if peak ==1 & testsample == 1  & ttdur!=. & dishwashing == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & yardwork == 1, beta
est sto reg3_peak_yardwork
predict p3_peak_yardwork if peak ==1 & testsample == 1  & ttdur!=. & yardwork == 1
    
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & cooking == 1, beta
est sto reg3_peak_cooking
predict p3_peak_cooking if peak ==1 & testsample == 1  & ttdur!=. & cooking == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & pooluse == 1, beta
est sto reg3_peak_pooluse
predict p3_peak_pooluse if peak ==1 & testsample == 1  & ttdur!=. & pooluse == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & TVgaming == 1, beta
est sto reg3_peak_TVgaming
predict p3_peak_TVgaming if peak ==1 & testsample == 1  & ttdur!=. & TVgaming == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & exercise == 1, beta
est sto reg3_peak_exercise
predict p3_peak_exercise if peak ==1 & testsample == 1  & ttdur!=. & exercise == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & laundry == 1, beta
est sto reg3_peak_laundry
predict p3_peak_laundry if peak ==1 & testsample == 1  & ttdur!=. & laundry == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & justhome == 1, beta
est sto reg3_peak_justhome
predict p3_peak_justhome if peak ==1 & testsample == 1  & ttdur!=. & justhome == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & away == 1, beta
est sto reg3_peak_away
predict p3_peak_away if peak ==1 & testsample == 1  & ttdur!=. & away == 1

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & awayatwork == 1, beta
est sto reg3_peak_awayatwork
predict p3_peak_awayatwork if peak ==1 & testsample == 1  & ttdur!=. & awayatwork == 1

* Now compare results for peak period
summarize ttdur p3_peak_justhome if peak ==1 & testsample == 1  & ttdur!=. & justhome == 1
summarize ttdur p3_peak_sleeping if peak ==1 & testsample == 1  & ttdur!=. & sleeping == 1
summarize ttdur p3_peak_laundry if peak ==1 & testsample == 1  & ttdur!=. & laundry == 1
summarize ttdur p3_peak_dishwashing if peak ==1 & testsample == 1  & ttdur!=. & dishwashing == 1
summarize ttdur p3_peak_cooking if peak ==1 & testsample == 1  & ttdur!=. & cooking == 1
summarize ttdur p3_peak_cleaning if peak ==1 & testsample == 1  & ttdur!=. & cleaning == 1
summarize ttdur p3_peak_yardwork if peak ==1 & testsample == 1  & ttdur!=. & yardwork == 1
summarize ttdur p3_peak_exercise if peak ==1 & testsample == 1  & ttdur!=. & exercise == 1
summarize ttdur p3_peak_pooluse if peak ==1 & testsample == 1  & ttdur!=. & pooluse == 1
summarize ttdur p3_peak_TVgaming if peak ==1 & testsample == 1  & ttdur!=. & TVgaming == 1
summarize ttdur p3_peak_computeruse if peak ==1 & testsample == 1  & ttdur!=. & computeruse == 1
summarize ttdur p3_peak_traveling if peak ==1 & testsample == 1  & ttdur!=. & traveling == 1
summarize ttdur p3_peak_awayatwork if peak ==1 & testsample == 1  & ttdur!=. & awayatwork == 1
summarize ttdur p3_peak_away if peak ==1 & testsample == 1  & ttdur!=. & away == 1

gen diffsq3_peak_computeruse = (ttdur - p3_peak_computeruse)^2 if peak ==1 & testsample==1  & ttdur!=. & computeruse == 1
gen diffsq3_peak_sleeping = (ttdur - p3_peak_sleeping)^2 if peak ==1 & testsample==1  & ttdur!=. & sleeping == 1
gen diffsq3_peak_traveling = (ttdur - p3_peak_traveling)^2 if peak ==1 & testsample==1  & ttdur!=. & traveling == 1
gen diffsq3_peak_cleaning = (ttdur - p3_peak_cleaning)^2 if peak ==1 & testsample==1  & ttdur!=. & cleaning == 1
gen diffsq3_peak_dishwashing = (ttdur - p3_peak_dishwashing)^2 if peak ==1 & testsample==1  & ttdur!=. & dishwashing == 1
gen diffsq3_peak_yardwork = (ttdur - p3_peak_yardwork)^2 if peak ==1 & testsample==1  & ttdur!=. & yardwork == 1
gen diffsq3_peak_cooking = (ttdur - p3_peak_cooking)^2 if peak ==1 & testsample==1  & ttdur!=. & cooking == 1
gen diffsq3_peak_pooluse = (ttdur - p3_peak_pooluse)^2 if peak ==1 & testsample==1  & ttdur!=. & pooluse == 1
gen diffsq3_peak_TVgaming = (ttdur - p3_peak_TVgaming)^2 if peak ==1 & testsample==1  & ttdur!=. & TVgaming == 1
gen diffsq3_peak_exercise = (ttdur - p3_peak_exercise)^2 if peak ==1 & testsample==1  & ttdur!=. & exercise == 1
gen diffsq3_peak_laundry = (ttdur - p3_peak_laundry)^2 if peak ==1 & testsample==1  & ttdur!=. & laundry == 1
gen diffsq3_peak_justhome = (ttdur - p3_peak_justhome)^2 if peak ==1 & testsample==1  & ttdur!=. & justhome == 1
gen diffsq3_peak_away = (ttdur - p3_peak_away)^2 if peak ==1 & testsample==1  & ttdur!=. & away == 1
gen diffsq3_peak_awayatwork = (ttdur - p3_peak_awayatwork)^2 if peak ==1 & testsample==1  & ttdur!=. & awayatwork == 1

summarize diffsq3_peak_justhome diffsq3_peak_sleeping diffsq3_peak_laundry diffsq3_peak_dishwashing diffsq3_peak_cooking diffsq3_peak_cleaning diffsq3_peak_yardwork diffsq3_peak_exercise diffsq3_peak_pooluse diffsq3_peak_TVgaming diffsq3_peak_computeruse diffsq3_peak_traveling diffsq3_peak_awayatwork diffsq3_peak_away, sep(0)

esttab reg3_peak reg3_peak_justhome reg3_peak_sleeping reg3_peak_laundry reg3_peak_dishwashing reg3_peak_cooking reg3_peak_cleaning  reg3_peak_yardwork reg3_peak_exercise reg3_peak_pooluse reg3_peak_TVgaming reg3_peak_computeruse reg3_peak_traveling reg3_peak_awayatwork reg3_peak_away using durpeakslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during peak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

reg3_peak_computeruse reg3_peak_sleeping reg3_peak_traveling reg3_peak_cleaning reg3_peak_dishwashing reg3_peak_yardwork reg3_peak_cooking reg3_peak_pooluse reg3_peak_TVgaming reg3_peak_exercise reg3_peak_laundry reg3_peak_justhome reg3_peak_away reg3_peak_awayatwork

_est_reg3_peak_computeruse _est_reg3_peak_sleeping _est_reg3_peak_traveling _est_reg3_peak_cleaning _est_reg3_peak_dishwashing _est_reg3_peak_yardwork _est_reg3_peak_cooking _est_reg3_peak_pooluse _est_reg3_peak_TVgaming _est_reg3_peak_exercise _est_reg3_peak_laundry _est_reg3_peak_justhome _est_reg3_peak_away _est_reg3_peak_awayatwork

p3_peak_computeruse p3_peak_sleeping p3_peak_traveling p3_peak_cleaning p3_peak_dishwashing p3_peak_yardwork p3_peak_cooking p3_peak_pooluse p3_peak_TVgaming p3_peak_exercise p3_peak_laundry p3_peak_justhome p3_peak_away p3_peak_awayatwork

. summarize ttdur p3_peak_justhome if peak ==1 & testsample == 1  & ttdur!=. & justhome == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      2,692    87.63596     78.4856          1        975
p3_peak_ju~e |      2,514    86.32344    14.42056   46.69845   131.6938

. 
. summarize ttdur p3_peak_sleeping if peak ==1 & testsample == 1  & ttdur!=. & sleeping == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,823    326.2715    91.07823         10       1070
p3_peak_sl~g |      1,703     328.577    15.50306   284.2182   387.6237

. 
. summarize ttdur p3_peak_laundry if peak ==1 & testsample == 1  & ttdur!=. & laundry == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        278    46.01079     43.6262          2        270
p3_peak_la~y |        269    43.55959    14.04268   17.18848   105.8238

. 
. summarize ttdur p3_peak_dishwashing if peak ==1 & testsample == 1  & ttdur!=. & dishwashing == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        402    24.39552    16.34251          5        102
p3_peak_di~g |        369    25.92902     3.76026   15.66488   37.99515

. 
. summarize ttdur p3_peak_cooking if peak ==1 & testsample == 1  & ttdur!=. & cooking == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        690    28.17391     32.3393          1        320
p3_peak_co~g |        648     29.6433    6.855026   17.53583   56.41525

. 
. summarize ttdur p3_peak_cleaning if peak ==1 & testsample == 1  & ttdur!=. & cleaning == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,814    43.26075    44.35519          1        420
p3_peak_cl~g |      1,687    42.52966    11.62155   13.96963   87.00777

. 
. summarize ttdur p3_peak_yardwork if peak ==1 & testsample == 1  & ttdur!=. & yardwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |         88    74.09091    66.96193          5        390
p3_peak_ya~k |         77    85.33073    24.39649   41.05884   144.6208

. 
. summarize ttdur p3_peak_exercise if peak ==1 & testsample == 1  & ttdur!=. & exercise == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        188    73.94149    65.66551          2        345
p3_peak_ex~e |        177    78.05896    12.14509   49.54457   116.5413

. 
. summarize ttdur p3_peak_pooluse if peak ==1 & testsample == 1  & ttdur!=. & pooluse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |          6          55    27.92848         30        105
p3_peak_po~e |          5    57.91372    13.03378   36.22133   68.87032

. 
. summarize ttdur p3_peak_TVgaming if peak ==1 & testsample == 1  & ttdur!=. & TVgaming == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,671     109.471    74.26805          3        740
p3_peak_TV~g |      1,546    107.2271    20.29177   54.93755   177.6346

. 
. summarize ttdur p3_peak_computeruse if peak ==1 & testsample == 1  & ttdur!=. & computeruse == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        219     72.2968    62.99446          5        458
p3_peak_co~e |        212    69.05301    17.16102   31.55319   120.1561

. 
. summarize ttdur p3_peak_traveling if peak ==1 & testsample == 1  & ttdur!=. & traveling == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      2,125    36.36282    33.37277          1        360
p3_peak_tr~g |      1,987    36.45314    4.913668   24.55678   52.97673

. 
. summarize ttdur p3_peak_awayatwork if peak ==1 & testsample == 1  & ttdur!=. & awayatwork == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |        774    228.6899    110.7466          2        765
p3_peak_aw~k |        723    232.6543     12.9019   128.4002   269.2268

. 
. summarize ttdur p3_peak_away if peak ==1 & testsample == 1  & ttdur!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
       ttdur |      1,391    82.36089    90.49431          1       1050
p3_peak_away |      1,298    84.71349    26.17617   27.30376   184.2649


drop diffsq3_cripeak_justhome diffsq3_cripeak_sleeping diffsq3_cripeak_laundry diffsq3_cripeak_dishwashing diffsq3_cripeak_cooking diffsq3_cripeak_cleaning diffsq3_cripeak_yardwork diffsq3_cripeak_exercise diffsq3_cripeak_pooluse diffsq3_cripeak_TVgaming diffsq3_cripeak_computeruse diffsq3_cripeak_traveling diffsq3_cripeak_awayatwork diffsq3_cripeak_away diffsq3_offpeak_justhome diffsq3_offpeak_sleeping diffsq3_offpeak_laundry diffsq3_offpeak_dishwashing diffsq3_offpeak_cooking diffsq3_offpeak_cleaning diffsq3_offpeak_yardwork diffsq3_offpeak_exercise diffsq3_offpeak_pooluse diffsq3_offpeak_TVgaming diffsq3_offpeak_computeruse diffsq3_offpeak_traveling diffsq3_offpeak_awayatwork diffsq3_offpeak_away diffsq3_peak_justhome diffsq3_peak_sleeping diffsq3_peak_laundry diffsq3_peak_dishwashing diffsq3_peak_cooking diffsq3_peak_cleaning diffsq3_peak_yardwork diffsq3_peak_exercise diffsq3_peak_pooluse diffsq3_peak_TVgaming diffsq3_peak_computeruse diffsq3_peak_traveling diffsq3_peak_awayatwork diffsq3_peak_away

save "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusallmodels.dta", replace

*weekend periods
regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0, beta
est sto reg3_wknd
predict p3_wknd if action ==1 & testsample == 1  & ttdurday!=.

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & computeruse == 1, beta
est sto reg3_wknd_computeruse
predict p3_wknd_computeruse if action ==1 & testsample == 1  & ttdurday!=. & computeruse == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & sleeping == 1, beta
est sto reg3_wknd_sleeping
predict p3_wknd_sleeping if action ==1 & testsample == 1  & ttdurday!=. & sleeping == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & traveling == 1, beta
est sto reg3_wknd_traveling
predict p3_wknd_traveling if action ==1 & testsample == 1  & ttdurday!=. & traveling == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & cleaning == 1, beta
est sto reg3_wknd_cleaning
predict p3_wknd_cleaning if action ==1 & testsample == 1  & ttdurday!=. & cleaning == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & dishwashing == 1, beta
est sto reg3_wknd_dishwashing
predict p3_wknd_dishwashing if action ==1 & testsample == 1  & ttdurday!=. & dishwashing == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & yardwork == 1, beta
est sto reg3_wknd_yardwork
predict p3_wknd_yardwork if action ==1 & testsample == 1  & ttdurday!=. & yardwork == 1
    
regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & cooking == 1, beta
est sto reg3_wknd_cooking
predict p3_wknd_cooking if action ==1 & testsample == 1  & ttdurday!=. & cooking == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & pooluse == 1, beta
est sto reg3_wknd_pooluse
predict p3_wknd_pooluse if action ==1 & testsample == 1  & ttdurday!=. & pooluse == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & TVgaming == 1, beta
est sto reg3_wknd_TVgaming
predict p3_wknd_TVgaming if action ==1 & testsample == 1  & ttdurday!=. & TVgaming == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & exercise == 1, beta
est sto reg3_wknd_exercise
predict p3_wknd_exercise if action ==1 & testsample == 1  & ttdurday!=. & exercise == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & laundry == 1, beta
est sto reg3_wknd_laundry
predict p3_wknd_laundry if action ==1 & testsample == 1  & ttdurday!=. & laundry == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & justhome == 1, beta
est sto reg3_wknd_justhome
predict p3_wknd_justhome if action ==1 & testsample == 1  & ttdurday!=. & justhome == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & away == 1, beta
est sto reg3_wknd_away
predict p3_wknd_away if action ==1 & testsample == 1  & ttdurday!=. & away == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & awayatwork == 1, beta
est sto reg3_wknd_awayatwork
predict p3_wknd_awayatwork if action ==1 & testsample == 1  & ttdurday!=. & awayatwork == 1

* Now compare results for weekend
summarize ttdurday p3_wknd_justhome if action ==1 & testsample == 1  & ttdurday!=. & justhome == 1
summarize ttdurday p3_wknd_sleeping if action ==1 & testsample == 1  & ttdurday!=. & sleeping == 1
summarize ttdurday p3_wknd_laundry if action ==1 & testsample == 1  & ttdurday!=. & laundry == 1
summarize ttdurday p3_wknd_dishwashing if action ==1 & testsample == 1  & ttdurday!=. & dishwashing == 1
summarize ttdurday p3_wknd_cooking if action ==1 & testsample == 1  & ttdurday!=. & cooking == 1
summarize ttdurday p3_wknd_cleaning if action ==1 & testsample == 1  & ttdurday!=. & cleaning == 1
summarize ttdurday p3_wknd_yardwork if action ==1 & testsample == 1  & ttdurday!=. & yardwork == 1
summarize ttdurday p3_wknd_exercise if action ==1 & testsample == 1  & ttdurday!=. & exercise == 1
summarize ttdurday p3_wknd_pooluse if action ==1 & testsample == 1  & ttdurday!=. & pooluse == 1
summarize ttdurday p3_wknd_TVgaming if action ==1 & testsample == 1  & ttdurday!=. & TVgaming == 1
summarize ttdurday p3_wknd_computeruse if action ==1 & testsample == 1  & ttdurday!=. & computeruse == 1
summarize ttdurday p3_wknd_traveling if action ==1 & testsample == 1  & ttdurday!=. & traveling == 1
summarize ttdurday p3_wknd_awayatwork if action ==1 & testsample == 1  & ttdurday!=. & awayatwork == 1
summarize ttdurday p3_wknd_away if action ==1 & testsample == 1  & ttdurday!=. & away == 1

gen diffsq3_wknd_computeruse = (ttdurday - p3_wknd_computeruse)^2 if action ==1 & testsample==1  & ttdurday!=. & computeruse == 1
gen diffsq3_wknd_sleeping = (ttdurday - p3_wknd_sleeping)^2 if action ==1 & testsample==1  & ttdurday!=. & sleeping == 1
gen diffsq3_wknd_traveling = (ttdurday - p3_wknd_traveling)^2 if action ==1 & testsample==1  & ttdurday!=. & traveling == 1
gen diffsq3_wknd_cleaning = (ttdurday - p3_wknd_cleaning)^2 if action ==1 & testsample==1  & ttdurday!=. & cleaning == 1
gen diffsq3_wknd_dishwashing = (ttdurday - p3_wknd_dishwashing)^2 if action ==1 & testsample==1  & ttdurday!=. & dishwashing == 1
gen diffsq3_wknd_yardwork = (ttdurday - p3_wknd_yardwork)^2 if action ==1 & testsample==1  & ttdurday!=. & yardwork == 1
gen diffsq3_wknd_cooking = (ttdurday - p3_wknd_cooking)^2 if action ==1 & testsample==1  & ttdurday!=. & cooking == 1
gen diffsq3_wknd_pooluse = (ttdurday - p3_wknd_pooluse)^2 if action ==1 & testsample==1  & ttdurday!=. & pooluse == 1
gen diffsq3_wknd_TVgaming = (ttdurday - p3_wknd_TVgaming)^2 if action ==1 & testsample==1  & ttdurday!=. & TVgaming == 1
gen diffsq3_wknd_exercise = (ttdurday - p3_wknd_exercise)^2 if action ==1 & testsample==1  & ttdurday!=. & exercise == 1
gen diffsq3_wknd_laundry = (ttdurday - p3_wknd_laundry)^2 if action ==1 & testsample==1  & ttdurday!=. & laundry == 1
gen diffsq3_wknd_justhome = (ttdurday - p3_wknd_justhome)^2 if action ==1 & testsample==1  & ttdurday!=. & justhome == 1
gen diffsq3_wknd_away = (ttdurday - p3_wknd_away)^2 if action ==1 & testsample==1  & ttdurday!=. & away == 1
gen diffsq3_wknd_awayatwork = (ttdurday - p3_wknd_awayatwork)^2 if action ==1 & testsample==1  & ttdurday!=. & awayatwork == 1

summarize diffsq3_wknd_justhome diffsq3_wknd_sleeping diffsq3_wknd_laundry diffsq3_wknd_dishwashing diffsq3_wknd_cooking diffsq3_wknd_cleaning diffsq3_wknd_yardwork diffsq3_wknd_exercise diffsq3_wknd_pooluse diffsq3_wknd_TVgaming diffsq3_wknd_computeruse diffsq3_wknd_traveling diffsq3_wknd_awayatwork diffsq3_wknd_away, sep(0)

esttab reg3_wknd reg3_wknd_justhome reg3_wknd_sleeping reg3_wknd_laundry reg3_wknd_dishwashing reg3_wknd_cooking reg3_wknd_cleaning  reg3_wknd_yardwork reg3_wknd_exercise reg3_wknd_pooluse reg3_wknd_TVgaming reg3_wknd_computeruse reg3_wknd_traveling reg3_wknd_awayatwork reg3_wknd_away using durwkndslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during weekend") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

reg3_wknd_computeruse reg3_wknd_sleeping reg3_wknd_traveling reg3_wknd_cleaning reg3_wknd_dishwashing reg3_wknd_yardwork reg3_wknd_cooking reg3_wknd_pooluse reg3_wknd_TVgaming reg3_wknd_exercise reg3_wknd_laundry reg3_wknd_justhome reg3_wknd_away reg3_wknd_awayatwork

_est_reg3_wknd_computeruse _est_reg3_wknd_sleeping _est_reg3_wknd_traveling _est_reg3_wknd_cleaning _est_reg3_wknd_dishwashing _est_reg3_wknd_yardwork _est_reg3_wknd_cooking _est_reg3_wknd_pooluse _est_reg3_wknd_TVgaming _est_reg3_wknd_exercise _est_reg3_wknd_laundry _est_reg3_wknd_justhome _est_reg3_wknd_away _est_reg3_wknd_awayatwork

p3_wknd_computeruse p3_wknd_sleeping p3_wknd_traveling p3_wknd_cleaning p3_wknd_dishwashing p3_wknd_yardwork p3_wknd_cooking p3_wknd_pooluse p3_wknd_TVgaming p3_wknd_exercise p3_wknd_laundry p3_wknd_justhome p3_wknd_away p3_wknd_awayatwork


. summarize ttdurday p3_wknd_justhome if action ==1 & testsample == 1  & ttdurday!=. & justhome =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,988    262.5885    187.2859          3       1080
p3_wknd_ju~e |      1,840    267.9318     43.7097   114.5997   421.4465

. 
. summarize ttdurday p3_wknd_sleeping if action ==1 & testsample == 1  & ttdurday!=. & sleeping =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      2,058    556.7653     132.272         25       1260
p3_wknd_sl~g |      1,907    553.2651    39.17235   432.4953    693.744

. 
. summarize ttdurday p3_wknd_laundry if action ==1 & testsample == 1  & ttdurday!=. & laundry == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        454    73.44934    77.47791          1        810
p3_wknd_la~y |        419    72.80983    15.55365   40.18605   120.4631

. 
. summarize ttdurday p3_wknd_dishwashing if action ==1 & testsample == 1  & ttdurday!=. & dishwas
> hing == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        456    36.55482    28.64227          2        240
p3_wknd_di~g |        423    36.33528    5.335904    22.9431   56.68465

. 
. summarize ttdurday p3_wknd_cooking if action ==1 & testsample == 1  & ttdurday!=. & cooking == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,121    59.38537    56.59413          1        450
p3_wknd_co~g |      1,040    60.79836    11.76955   34.01963   106.6262

. 
. summarize ttdurday p3_wknd_cleaning if action ==1 & testsample == 1  & ttdurday!=. & cleaning =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,686    86.52017    77.12789          2       1080
p3_wknd_cl~g |      1,565    86.51382     19.1721   19.98526   151.5146

. 
. summarize ttdurday p3_wknd_yardwork if action ==1 & testsample == 1  & ttdurday!=. & yardwork =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        191    135.4398    102.7141          5        480
p3_wknd_ya~k |        174    133.5699    29.36007   56.96285   202.0744

. 
. summarize ttdurday p3_wknd_exercise if action ==1 & testsample == 1  & ttdurday!=. & exercise =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        271    145.5646    148.1629         10        715
p3_wknd_ex~e |        258    153.8077    43.49536   40.44194   267.0864

. 
. summarize ttdurday p3_wknd_pooluse if action ==1 & testsample == 1  & ttdurday!=. & pooluse == 
> 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |          7    71.71429    72.01091         10        192
p3_wknd_po~e |          7    72.39758    23.57015   47.26873   120.4496

. 
. summarize ttdurday p3_wknd_TVgaming if action ==1 & testsample == 1  & ttdurday!=. & TVgaming =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,693    249.9025    180.2698          1       1075
p3_wknd_TV~g |      1,574       239.1    78.05679    34.7634   533.0328

. 
. summarize ttdurday p3_wknd_computeruse if action ==1 & testsample == 1  & ttdurday!=. & compute
> ruse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        221    86.96833    78.92116          5        506
p3_wknd_co~e |        206     92.6371    31.08061   33.96278    215.065

. 
. summarize ttdurday p3_wknd_traveling if action ==1 & testsample == 1  & ttdurday!=. & traveling
>  == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,729    89.89994    94.86181          1       1145
p3_wknd_tr~g |      1,610    89.20159    16.32425   34.11744   169.4551

. 
. summarize ttdurday p3_wknd_awayatwork if action ==1 & testsample == 1  & ttdurday!=. & awayatwo
> rk == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        240    456.6125     233.712          2       1310
p3_wknd_aw~k |        225    430.8188     75.6093   135.2837   603.0828

. 
. summarize ttdurday p3_wknd_away if action ==1 & testsample == 1  & ttdurday!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,530    193.6157    158.1143          1       1075
p3_wknd_away |      1,422    200.1603     38.1984   75.39054   404.4783



drop diffsq3_wknd_justhome diffsq3_wknd_sleeping diffsq3_wknd_laundry diffsq3_wknd_dishwashing diffsq3_wknd_cooking diffsq3_wknd_cleaning diffsq3_wknd_yardwork diffsq3_wknd_exercise diffsq3_wknd_pooluse diffsq3_wknd_TVgaming diffsq3_wknd_computeruse diffsq3_wknd_traveling diffsq3_wknd_awayatwork diffsq3_wknd_away

save "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusallmodels.dta", replace

*weekday periods
regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0, beta
est sto reg3_wkday
predict p3_wkday if weekend ==0 & testsample == 1  & ttdurday!=.

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & computeruse == 1, beta
est sto reg3_wkday_computeruse
predict p3_wkday_computeruse if weekend ==0 & testsample == 1  & ttdurday!=. & computeruse == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & sleeping == 1, beta
est sto reg3_wkday_sleeping
predict p3_wkday_sleeping if weekend ==0 & testsample == 1  & ttdurday!=. & sleeping == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & traveling == 1, beta
est sto reg3_wkday_traveling
predict p3_wkday_traveling if weekend ==0 & testsample == 1  & ttdurday!=. & traveling == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & cleaning == 1, beta
est sto reg3_wkday_cleaning
predict p3_wkday_cleaning if weekend ==0 & testsample == 1  & ttdurday!=. & cleaning == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & dishwashing == 1, beta
est sto reg3_wkday_dishwashing
predict p3_wkday_dishwashing if weekend ==0 & testsample == 1  & ttdurday!=. & dishwashing == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & yardwork == 1, beta
est sto reg3_wkday_yardwork
predict p3_wkday_yardwork if weekend ==0 & testsample == 1  & ttdurday!=. & yardwork == 1
    
regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & cooking == 1, beta
est sto reg3_wkday_cooking
predict p3_wkday_cooking if weekend ==0 & testsample == 1  & ttdurday!=. & cooking == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & pooluse == 1, beta
est sto reg3_wkday_pooluse
predict p3_wkday_pooluse if weekend ==0 & testsample == 1  & ttdurday!=. & pooluse == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & TVgaming == 1, beta
est sto reg3_wkday_TVgaming
predict p3_wkday_TVgaming if weekend ==0 & testsample == 1  & ttdurday!=. & TVgaming == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & exercise == 1, beta
est sto reg3_wkday_exercise
predict p3_wkday_exercise if weekend ==0 & testsample == 1  & ttdurday!=. & exercise == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & laundry == 1, beta
est sto reg3_wkday_laundry
predict p3_wkday_laundry if weekend ==0 & testsample == 1  & ttdurday!=. & laundry == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & justhome == 1, beta
est sto reg3_wkday_justhome
predict p3_wkday_justhome if weekend ==0 & testsample == 1  & ttdurday!=. & justhome == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & away == 1, beta
est sto reg3_wkday_away
predict p3_wkday_away if weekend ==0 & testsample == 1  & ttdurday!=. & away == 1

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & awayatwork == 1, beta
est sto reg3_wkday_awayatwork
predict p3_wkday_awayatwork if weekend ==0 & testsample == 1  & ttdurday!=. & awayatwork == 1

* Now compare results for weekend
summarize ttdurday p3_wkday_justhome if weekend ==0 & testsample == 1  & ttdurday!=. & justhome == 1
summarize ttdurday p3_wkday_sleeping if weekend ==0 & testsample == 1  & ttdurday!=. & sleeping == 1
summarize ttdurday p3_wkday_laundry if weekend ==0 & testsample == 1  & ttdurday!=. & laundry == 1
summarize ttdurday p3_wkday_dishwashing if weekend ==0 & testsample == 1  & ttdurday!=. & dishwashing == 1
summarize ttdurday p3_wkday_cooking if weekend ==0 & testsample == 1  & ttdurday!=. & cooking == 1
summarize ttdurday p3_wkday_cleaning if weekend ==0 & testsample == 1  & ttdurday!=. & cleaning == 1
summarize ttdurday p3_wkday_yardwork if weekend ==0 & testsample == 1  & ttdurday!=. & yardwork == 1
summarize ttdurday p3_wkday_exercise if weekend ==0 & testsample == 1  & ttdurday!=. & exercise == 1
summarize ttdurday p3_wkday_pooluse if weekend ==0 & testsample == 1  & ttdurday!=. & pooluse == 1
summarize ttdurday p3_wkday_TVgaming if weekend ==0 & testsample == 1  & ttdurday!=. & TVgaming == 1
summarize ttdurday p3_wkday_computeruse if weekend ==0 & testsample == 1  & ttdurday!=. & computeruse == 1
summarize ttdurday p3_wkday_traveling if weekend ==0 & testsample == 1  & ttdurday!=. & traveling == 1
summarize ttdurday p3_wkday_awayatwork if weekend ==0 & testsample == 1  & ttdurday!=. & awayatwork == 1
summarize ttdurday p3_wkday_away if weekend ==0 & testsample == 1  & ttdurday!=. & away == 1

gen diffsq3_wkday_computeruse = (ttdurday - p3_wkday_computeruse)^2 if weekend ==0 & testsample==1  & ttdurday!=. & computeruse == 1
gen diffsq3_wkday_sleeping = (ttdurday - p3_wkday_sleeping)^2 if weekend ==0 & testsample==1  & ttdurday!=. & sleeping == 1
gen diffsq3_wkday_traveling = (ttdurday - p3_wkday_traveling)^2 if weekend ==0 & testsample==1  & ttdurday!=. & traveling == 1
gen diffsq3_wkday_cleaning = (ttdurday - p3_wkday_cleaning)^2 if weekend ==0 & testsample==1  & ttdurday!=. & cleaning == 1
gen diffsq3_wkday_dishwashing = (ttdurday - p3_wkday_dishwashing)^2 if weekend ==0 & testsample==1  & ttdurday!=. & dishwashing == 1
gen diffsq3_wkday_yardwork = (ttdurday - p3_wkday_yardwork)^2 if weekend ==0 & testsample==1  & ttdurday!=. & yardwork == 1
gen diffsq3_wkday_cooking = (ttdurday - p3_wkday_cooking)^2 if weekend ==0 & testsample==1  & ttdurday!=. & cooking == 1
gen diffsq3_wkday_pooluse = (ttdurday - p3_wkday_pooluse)^2 if weekend ==0 & testsample==1  & ttdurday!=. & pooluse == 1
gen diffsq3_wkday_TVgaming = (ttdurday - p3_wkday_TVgaming)^2 if weekend ==0 & testsample==1  & ttdurday!=. & TVgaming == 1
gen diffsq3_wkday_exercise = (ttdurday - p3_wkday_exercise)^2 if weekend ==0 & testsample==1  & ttdurday!=. & exercise == 1
gen diffsq3_wkday_laundry = (ttdurday - p3_wkday_laundry)^2 if weekend ==0 & testsample==1  & ttdurday!=. & laundry == 1
gen diffsq3_wkday_justhome = (ttdurday - p3_wkday_justhome)^2 if weekend ==0 & testsample==1  & ttdurday!=. & justhome == 1
gen diffsq3_wkday_away = (ttdurday - p3_wkday_away)^2 if weekend ==0 & testsample==1  & ttdurday!=. & away == 1
gen diffsq3_wkday_awayatwork = (ttdurday - p3_wkday_awayatwork)^2 if weekend ==0 & testsample==1  & ttdurday!=. & awayatwork == 1

summarize diffsq3_wkday_justhome diffsq3_wkday_sleeping diffsq3_wkday_laundry diffsq3_wkday_dishwashing diffsq3_wkday_cooking diffsq3_wkday_cleaning diffsq3_wkday_yardwork diffsq3_wkday_exercise diffsq3_wkday_pooluse diffsq3_wkday_TVgaming diffsq3_wkday_computeruse diffsq3_wkday_traveling diffsq3_wkday_awayatwork diffsq3_wkday_away, sep(0)

esttab reg3_wkday reg3_wkday_justhome reg3_wkday_sleeping reg3_wkday_laundry reg3_wkday_dishwashing reg3_wkday_cooking reg3_wkday_cleaning  reg3_wkday_yardwork reg3_wkday_exercise reg3_wkday_pooluse reg3_wkday_TVgaming reg3_wkday_computeruse reg3_wkday_traveling reg3_wkday_awayatwork reg3_wkday_away using durwkdayslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during weekday") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

reg3_wkday_computeruse reg3_wkday_sleeping reg3_wkday_traveling reg3_wkday_cleaning reg3_wkday_dishwashing reg3_wkday_yardwork reg3_wkday_cooking reg3_wkday_pooluse reg3_wkday_TVgaming reg3_wkday_exercise reg3_wkday_laundry reg3_wkday_justhome reg3_wkday_away reg3_wkday_awayatwork

_est_reg3_wkday_computeruse _est_reg3_wkday_sleeping _est_reg3_wkday_traveling _est_reg3_wkday_cleaning _est_reg3_wkday_dishwashing _est_reg3_wkday_yardwork _est_reg3_wkday_cooking _est_reg3_wkday_pooluse _est_reg3_wkday_TVgaming _est_reg3_wkday_exercise _est_reg3_wkday_laundry _est_reg3_wkday_justhome _est_reg3_wkday_away _est_reg3_wkday_awayatwork

p3_wkday_computeruse p3_wkday_sleeping p3_wkday_traveling p3_wkday_cleaning p3_wkday_dishwashing p3_wkday_yardwork p3_wkday_cooking p3_wkday_pooluse p3_wkday_TVgaming p3_wkday_exercise p3_wkday_laundry p3_wkday_justhome p3_wkday_away p3_wkday_awayatwork

. summarize ttdurday p3_wkday_justhome if weekend ==0 & testsample == 1  & ttdurday!=. & justhome
>  == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      2,088    235.9042    196.5376          2       1220
p3_wkday_j~e |      1,935     235.392    64.03656   70.47454   422.2747

. 
. summarize ttdurday p3_wkday_sleeping if weekend ==0 & testsample == 1  & ttdurday!=. & sleeping
>  == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      2,163    499.2141    129.5145         20       1370
p3_wkday_s~g |      2,008    495.8511    44.54278   373.4799   676.0416

. 
. summarize ttdurday p3_wkday_laundry if weekend ==0 & testsample == 1  & ttdurday!=. & laundry =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        393    62.93639    73.23734          2        745
p3_wkday_l~y |        380    54.96849    18.36805   8.592669   150.4291

. 
. summarize ttdurday p3_wkday_dishwashing if weekend ==0 & testsample == 1  & ttdurday!=. & dishw
> ashing == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        582    30.09966    20.68717          5        120
p3_wkday_d~g |        535    30.62237    6.444862   13.10565   57.06728

. 
. summarize ttdurday p3_wkday_cooking if weekend ==0 & testsample == 1  & ttdurday!=. & cooking =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,252    48.84345    55.10942          1        570
p3_wkda~king |      1,165    49.95383    15.24814    7.79746   99.79839

. 
. summarize ttdurday p3_wkday_cleaning if weekend ==0 & testsample == 1  & ttdurday!=. & cleaning
>  == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,899    74.17378    70.13127          1        922
p3_wkda~ning |      1,765    72.86265    20.70455   25.37167   147.8311

. 
. summarize ttdurday p3_wkday_yardwork if weekend ==0 & testsample == 1  & ttdurday!=. & yardwork
>  == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        167    97.76048    92.61081          4        570
p3_wkday_y~k |        151    105.3395    30.65752   36.60802    190.682

. 
. summarize ttdurday p3_wkday_exercise if weekend ==0 & testsample == 1  & ttdurday!=. & exercise
>  == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        287    110.7561    129.1961         10        870
p3_wkday_e~e |        272    120.8046    34.72141    40.4645   251.9498

. 
. summarize ttdurday p3_wkday_pooluse if weekend ==0 & testsample == 1  & ttdurday!=. & pooluse =
> = 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |          8        47.5    27.51623         20        105
p3_wkday_p~e |          7     42.6033     22.6686   16.62834   85.81493

. 
. summarize ttdurday p3_wkday_TVgaming if weekend ==0 & testsample == 1  & ttdurday!=. & TVgaming
>  == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,778    200.3695    168.5097          3       1150
p3_wkday_T~g |      1,650    195.8812    90.57967  -13.95791   494.6587

. 
. summarize ttdurday p3_wkday_computeruse if weekend ==0 & testsample == 1  & ttdurday!=. & compu
> teruse == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        293    99.78157    117.2294          5        880
p3_wkday_c~e |        282    90.37703    31.77001   29.20497   193.1474

. 
. summarize ttdurday p3_wkday_traveling if weekend ==0 & testsample == 1  & ttdurday!=. & traveli
> ng == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,888    87.37235    68.55361          2        855
p3_wkday_t~g |      1,757    87.70248    9.112023   62.73766   129.3906

. 
. summarize ttdurday p3_wkday_awayatwork if weekend ==0 & testsample == 1  & ttdurday!=. & awayat
> work == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |        998    489.9238    157.0961          2       1230
p3_wkday_a~k |        927    498.5217    61.92949   165.4394   642.6401

. 
. summarize ttdurday p3_wkday_away if weekend ==0 & testsample == 1  & ttdurday!=. & away == 1

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    ttdurday |      1,586    153.2093    159.2879          1       1230
p3_wkday_a~y |      1,477    160.5829    57.07596  -4.429065   406.3563

drop diffsq3_wkday_justhome diffsq3_wkday_sleeping diffsq3_wkday_laundry diffsq3_wkday_dishwashing diffsq3_wkday_cooking diffsq3_wkday_cleaning diffsq3_wkday_yardwork diffsq3_wkday_exercise diffsq3_wkday_pooluse diffsq3_wkday_TVgaming diffsq3_wkday_computeruse diffsq3_wkday_traveling diffsq3_wkday_awayatwork diffsq3_wkday_away

save "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusallmodels.dta", replace

* Under parallel run
* choice model during critical period
gen cripeak = 1 if ttdur!=. & action==4

mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if cripeak == 1 & testsample == 0, baseoutcome(2) iter(20)
est sto mlogit_cripeak
predict p_cripeak* if testsample == 1 & cripeak ==1 
// egen pred_cripeakmax = rowmax(p_cripeak*)
// g pred_cripeakchoice = .
// forv i=1/14 {
// 	replace pred_cripeakchoice = `i' if (pred_permax == p_period`i')
// }
// local choice_cripeaklab: value label choice
// label values pred_cripeakchoice `choice_cripeaklab'
summarize p_cripeak* i.choice if testsample == 1 & cripeak == 1, separator(14)



* iteration idea for "not concave" response for logit models
* choice model during offpeak period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & action==2 & testsample == 0, baseoutcome(2) iter(20)
est sto mlogit_offpeak
predict p_offpeak* if testsample == 1 & action==2 & ttdur!=.
// egen pred_offpeakmax = rowmax(p_offpeak*) if testsample == 1 & action==2 & ttdur!=.
// g pred_offpeakchoice = . if testsample == 1 & action==2 & ttdur!=.
// forv i=1/14 {
// 	replace pred_offpeakchoice = `i' if (pred_offpeakmax == p_offpeak`i')
// }
// local choice_offpeaklab: value label choice
// label values pred_offpeakchoice `choice_offpeaklab'
// tab pred_offpeakchoice choice
summarize p_offpeak* i.choice if testsample == 1 & action==2 & ttdur!=., separator(14)

* peak period choice model
gen peak = 1 if action ==3 | action ==5

mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & peak == 1 & testsample == 0, baseoutcome(2) iter(20)
est sto mlogit_peak
predict p_peak* if testsample == 1 & peak ==1 & ttdur!=.
summarize p_peak* i.choice if testsample == 1 & peak ==1 & ttdur!=., separator(14)

* choice model during weekend period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & action==1 & testsample == 0, baseoutcome(2) iter(20)
est sto mlogit_wknd
predict p_wknd* if testsample == 1 & action==1 & ttdurday!=.
summarize p_wknd* i.choice if testsample == 1 & action==1 & ttdurday!=., separator(14)

* choice model during weekday period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & weekend==0 & testsample == 0, baseoutcome(2) iter(20) 
est sto mlogit_wkday
predict p_wkday* if testsample == 1 & weekend==0 & ttdurday!=.
summarize p_wkday* i.choice if testsample == 1 & weekend==0 & ttdurday!=., separator(14)

* choice model for day
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & testsample == 0, baseoutcome(2) iter(20) 
est sto mlogit_typday
predict p_day* if testsample == 1 & ttdurday!=.
summarize p_day* i.choice if testsample == 1 & ttdurday!=., separator(14)

* choice model for periods
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & testsample == 0, baseoutcome(2) iter(20) 
est sto mlogit_period
predict p_period* if testsample == 1 & ttdur!=.
summarize p_period* i.choice if testsample == 1 & ttdur!=., separator(14)

* choice model for instances
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if tuactdur24!=. & testsample == 0, baseoutcome(2) iter(20) 
est sto mlogit_inst
predict p_inst* if testsample == 1 & tuactdur24!=.
summarize p_inst* if testsample == 1 & tuactdur24!=., sep(14)

esttab mlogit_typday mlogit_period mlogit_inst using compchoicemodels1.html, eform se aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to being away") mtitle("Typical day" "Any period" "Single instance")

esttab mlogit_wkday mlogit_wknd using compchoiceweekday.html, se aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to sleeping") mtitle("Weekday" "Weekend")



* Lasso inference model for energy using activities at home during any period
dsregress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure if location == 1, controls(tuyear i.season i.tudiaryday i.trholiday i.gereg) selection(cv) rseed(1234)
estimates store dscv_homeper17

dsregress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure if location == 1 & cripeak == 1, controls(tuyear i.season i.tudiaryday i.trholiday i.gereg) selection(cv) rseed(1234)
estimates store dscv_homecripeak17

dsregress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure, controls(tuyear i.season i.tudiaryday i.trholiday i.gereg) selection(cv) rseed(1234)
est sto dscvper_allcorrect

esttab dscvper_allcorrect using dscvallcorrectperiod.html, se aic obslast scalar(F) bic r2 label nonumber title("Lasso inference model using cross-validation selection method for duration of any activity during all periods")
* Completed publication May15/16 2021
distinct tucaseid if gestfips ==6
distinct tucaseid if gestfips ==8
distinct tucaseid if gestfips ==56
save "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusallmodels.dta", replace
dsregress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure, controls(tuyear i.season i.tudiaryday i.trholiday i.gereg) selection(cv) rseed(1234)
est sto dscvper_allcorrect
esttab dscvper_allcorrect using dscvallcorrectperiod.html, se aic obslast scalar(F) bic r2 label nonumber title("Lasso inference model using cross-validation selection method for duration of any activity during all periods")
lassoinfo

distinct hubus tucaseid tesex hetelhhd trhhchild  teage trnumhou trtalone trchildnum incomelevl telfs peeduca ptdtrace prcitshp pehspnon hehousut hrhtype hetenure

distinct tucaseid if hubus!=.
distinct tucaseid if incomelevl!=.
disctint tucase if hetenure!=.

201,151

*Paper publishing April 28th, 2021

*Whole ATUS population
summarize i.choice if ttdurday!=., sep(0)
summarize i.choice if ttdur!=., sep(0)
summarize i.choice if tuactdur24!=., sep(0)

table choice if ttdurday<., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if ttdur<., contents(N tucaseid mean ttdur sd ttdur) 
table choice if tuactdur24<., contents(N tucaseid mean tuactdur24 sd tuactdur24) 

*Model population 
summarize i.choice if testsample ==0 & ttdurday!=., sep(0)
summarize i.choice if testsample == 0 & ttdur!=., sep(0)
summarize i.choice if testsample ==0 & tuactdur24!=., sep(0)

table choice if testsample ==0 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if testsample ==0 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 
table choice if testsample ==0 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24) 

*Test population
summarize i.choice if testsample ==1 & ttdurday!=., sep(0)
summarize i.choice if testsample == 1 & ttdur!=., separator(0)
summarize i.choice if testsample ==1 & tuactdur24!=., sep(0)

table choice if testsample ==1 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if testsample ==1 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 
table choice if testsample ==1 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24) 

* Different states
label define labelgestfips 1 "AL" 2 "AK" 4 "AZ" 5 "AR" 6 "CA" 8 "CO" 9 "CT" 10 "DE" 11 "DC" 12 "FL" 13 "GA" 15 "HI" 16 "ID" 17 "IL" 18 "IN" 19 "IA" 20 "KS" 21 "KY" 22 "LA" 23 "ME" 24 "MD" 25 "MA" 26 "MI" 27 "MN" 28 "MS" 29 "MO" 30 "MT" 31 "NE" 32 "NV" 33 "NH" 34 "NJ" 35 "NM" 36 "NY" 37 "NC" 38 "ND" 39 "OH" 40 "OK" 41 "OR" 42 "PA" 44 "RI" 45 "SC" 46 "SD" 47 "TN" 48 "TX" 49 "UT" 50 "VT" 51 "VA" 53 "WA" 54 "WV" 55 "WI" 56 "WY" 
* Colorado
distinct tucaseid if gestfips ==8 
summarize i.choice if gestfips ==8 & ttdurday!=., sep(0)
summarize i.choice if gestfips == 8 & ttdur!=., separator(0)
summarize i.choice if gestfips ==8 & tuactdur24!=., sep(0)

table choice if gestfips ==8 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if gestfips ==8 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 
table choice if gestfips ==8 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24) 

* California
distinct tucaseid if gestfips ==6 
summarize i.choice if gestfips ==6 & ttdurday!=., sep(0)
summarize i.choice if gestfips == 6 & ttdur!=., separator(0)
summarize i.choice if gestfips ==6 & tuactdur24!=., sep(0)

table choice if gestfips ==6 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if gestfips ==6 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 
table choice if gestfips ==6 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24)

* Wyoming
distinct tucaseid if gestfips ==56 
summarize i.choice if gestfips ==56 & ttdurday!=., sep(0)
summarize i.choice if gestfips ==56 & ttdur!=., separator(0)
summarize i.choice if gestfips ==56 & tuactdur24!=., sep(0)

table choice if gestfips ==56 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if gestfips ==56 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 
table choice if gestfips ==56 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24)

*seasons
by season, sort : summarize i.choice if ttdurday!=., separator(0)
by season, sort : table choice if ttdurday<., contents(N tucaseid mean ttdurday sd ttdurday) 

by season, sort : summarize i.choice if ttdur!=., sep(0)
by season, sort : table choice if ttdur<., contents(N tucaseid mean ttdur sd ttdur) 

by season, sort : summarize i.choice if tuactdur24!=., sep(0)
by season, sort : table choice if tuactdur24<., contents(N tucaseid mean tuactdur24 sd tuactdur24)

*per periods
by action, sort : summarize i.choice if ttdur!=., sep(0)
by action, sort : table choice if ttdur<., contents(N tucaseid mean ttdur sd ttdur) 

*weekday versus weekend
summarize i.choice if ttdur!=. & weekend == 0, sep(0)
table choice if ttdur<. & weekend == 0, contents(N tucaseid mean ttdur sd ttdur)

summarize i.choice if ttdurday!=. & weekend == 1, sep(0)
table choice if ttdurday<. & weekend == 1, contents(N tucaseid mean ttdurday sd ttdurday)

summarize i.choice if ttdurday!=. & weekend == 0, sep(0)
table choice if ttdurday<. & weekend == 0, contents(N tucaseid mean ttdurday sd ttdurday)

*curious about changes through the years for being at home at any given period
by tuyear, sort : summarize 1.choice if ttdur!=., separator(0)
by tuyear, sort : table justhome if ttdur<., contents(N tucaseid mean ttdur sd ttdur) 

by tuyear, sort : summarize 2.choice if ttdur!=., separator(0)
by tuyear, sort : table sleeping if ttdur<., contents(N tucaseid mean ttdur sd ttdur)

by tuyear, sort : summarize 13.choice if ttdur!=., separator(0)
by tuyear, sort : table awayatwork if ttdur<., contents(N tucaseid mean ttdur sd ttdur)

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    203,558    .1806021    .3846891          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2004

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    138,532     .182817    .3865178          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2005

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    130,080    .1817497    .3856396          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2006

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    129,728    .1802618    .3844068          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2007

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    120,090    .1816804    .3855825          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2008

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    125,184    .1817964    .3856782          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2009

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    129,809    .1833694    .3869706          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2010

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    129,985    .1815209    .3854507          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2011

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    121,770    .1808574    .3849015          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2012

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    119,682    .1818569    .3857282          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2013

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    111,271    .1825992    .3863394          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2014

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    114,628    .1818055    .3856858          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2015

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    108,496    .1796287    .3838797          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2016

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    105,029    .1798837    .3840923          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2017

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |    100,374    .1797079    .3839459          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2018

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
  Just_home  |     94,040    .1802956    .3844355          0          1

ttdur  
-> tuyear = 2003

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     166,795     148.0816     171.6482
        1 |      36,763     137.4433     151.4541
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2004

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     113,206     146.8506     169.8493
        1 |      25,326     135.5037     151.3957
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2005

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     106,438     145.8145     169.3537
        1 |      23,642     134.4852      151.553
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2006

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     106,343     145.5342      169.897
        1 |      23,385     132.2778     148.9139
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2007

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      98,272     149.1134     172.4539
        1 |      21,818     133.4742     150.8058
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2008

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     102,426     148.6301     173.8327
        1 |      22,758     133.3378     149.8653
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2009

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     106,006     147.8503     173.0195
        1 |      23,803     133.1597     148.4042
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2010

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     106,390     148.9964     174.6964
        1 |      23,595     134.8068     151.2917
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2011

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      99,747     150.4014     174.4632
        1 |      22,023      132.628     149.6195
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2012

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      97,917     152.4358     176.0343
        1 |      21,765     135.0238     151.8693
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2013

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      90,953     149.8312      174.258
        1 |      20,318     133.4084     150.8947
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2014

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      93,788     148.5564     174.9918
        1 |      20,840     129.5198     147.4763
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2015

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      89,007     147.2228     173.4738
        1 |      19,489     130.2628     146.9662
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2016

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      86,136     146.8612     174.2657
        1 |      18,893     127.2732      143.446
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2017

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      82,336     149.3418     175.8459
        1 |      18,038     131.2881      148.563
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2018

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      77,085     149.4741     177.2679
        1 |      16,955     131.7909     149.8958
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2003

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    203,558    .1481936    .3552927          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2004

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    138,532    .1482618    .3553606          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2005

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    130,080    .1477706    .3548738          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2006

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    129,728    .1482332    .3553324          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2007

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    120,090    .1493796    .3564638          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2008

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    125,184    .1477825    .3548856          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2009

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    129,809    .1482563    .3553552          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2010

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    129,985    .1495326    .3566141          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2011

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    121,770    .1499877    .3570608          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2012

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    119,682    .1510419    .3580912          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2013

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    111,271    .1500301    .3571025          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2014

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    114,628    .1488118    .3559044          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2015

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    108,496    .1480608    .3551618          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2016

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    105,029    .1475307    .3546358          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2017

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |    100,374    .1492418    .3563285          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2018

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
   Sleeping  |     94,040    .1506061    .3576664          0          1


. 
. by tuyear, sort : table sleeping if ttdur<., contents(N tucaseid mean ttdur sd ttdur)

-------------------------------------------------------------------------------------------------
-> tuyear = 2003

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     173,392     109.0873     132.1596
        1 |      30,166     359.2533     193.0634
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2004

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     117,993     108.1526     130.8672
        1 |      20,539      355.172     192.4605
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2005

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     110,858     106.9278     129.6484
        1 |      19,222     356.1493     193.1823
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2006

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     110,498     106.3682     129.2283
        1 |      19,230     354.4659     195.9049
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2007

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     102,151     109.0165     132.5308
        1 |      17,939     358.4184     194.6718
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2008

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     106,684     108.2589     132.4753
        1 |      18,500     362.6268     197.0323
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2009

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     110,564     107.5246     131.4241
        1 |      19,245     361.3549     195.5581
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2010

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     110,548     108.4656     133.8082
        1 |      19,437     362.2905     195.9782
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2011

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     103,506     109.1137     133.5093
        1 |      18,264     362.9567     194.2887
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2012

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     101,605     110.6455     134.6849
        1 |      18,077     366.3615     196.0798
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2013

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      94,577      108.822     133.5778
        1 |      16,694     362.1743     194.3634
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2014

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      97,570       107.09     133.1446
        1 |      17,058     362.4824     195.9121
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2015

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      92,432     106.2073     131.5056
        1 |      16,064     362.6491     194.1562
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2016

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      89,534     105.5032     131.2109
        1 |      15,495     361.9544     196.8394
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2017

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      85,394     108.0286     134.5903
        1 |      14,980     363.1095     195.5477
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2018

-------------------------------------------------
RECODE of |
trtier2p  |
(Pooled   |
lexicon   |
tiers 1   |
and 2:    |
1st four  |
digits of |
6-digit   |
act       | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      79,877     107.7857     135.2857
        1 |      14,163     363.4204      198.765
-------------------------------------------------


-> tuyear = 2003

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    203,558    .0546773    .2273498          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2004

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    138,532    .0543124    .2266338          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2005

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    130,080    .0561885    .2302863          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2006

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    129,728    .0553003    .2285664          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2007

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    120,090     .057382     .232572          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2008

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    125,184    .0551189     .228213          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2009

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    129,809    .0518608    .2217468          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2010

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    129,985    .0494365    .2167784          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2011

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    121,770    .0529523    .2239392          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2012

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    119,682    .0513778    .2207681          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2013

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    111,271    .0497165    .2173595          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2014

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    114,628    .0499878    .2179207          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2015

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    108,496    .0490341    .2159402          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2016

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    105,029    .0494721    .2168525          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2017

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |    100,374    .0487676    .2153829          0          1

-------------------------------------------------------------------------------------------------
-> tuyear = 2018

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      choice |
Away_for_~k  |     94,040    .0479902    .2137467          0          1


. 
. by tuyear, sort : table awayatwork if ttdur<., contents(N tucaseid mean ttdur sd ttdur)

-------------------------------------------------------------------------------------------------
-> tuyear = 2003

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     192,428     138.6851     164.4365
        1 |      11,130     275.4003     180.1496
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2004

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     131,008     137.5758     163.4997
        1 |       7,524     270.1482      171.707
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2005

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     122,771     136.4132     163.2966
        1 |       7,309     267.0832     168.1444
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2006

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     122,554     135.8331     163.1565
        1 |       7,174     268.0466      171.364
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2007

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     113,199      138.416     165.3685
        1 |       6,891     275.3243     172.8278
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2008

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     118,284     138.3906      166.349
        1 |       6,900     273.7233     177.7581
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2009

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     123,077      138.295     165.8164
        1 |       6,732     270.6015     174.9534
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2010

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     123,559     139.3542     167.2464
        1 |       6,426     282.2961     180.7508
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2011

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     115,322     140.1563     167.3511
        1 |       6,448     272.9296     174.9453
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2012

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     113,533     142.3262     168.9732
        1 |       6,149     277.4637     177.4147
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2013

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     105,739     139.9569     167.1043
        1 |       5,532      278.252     178.2631
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2014

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     108,898     137.8801     166.5086
        1 |       5,730     282.2227      186.268
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2015

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |     103,176     137.1299     165.2677
        1 |       5,320     280.8331     184.7032
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2016

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      99,833     136.4724     165.9463
        1 |       5,196     275.2413     178.8503
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2017

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      95,479      139.036     167.7315
        1 |       4,895     283.8319     183.6584
-------------------------------------------------

-------------------------------------------------------------------------------------------------
-> tuyear = 2018

-------------------------------------------------
RECODE of |
choice    |
(Activity |
_choice)  | N(tucaseid)  mean(ttdur)    sd(ttdur)
----------+--------------------------------------
        0 |      89,527      139.638     169.7219
        1 |       4,513     278.1633     180.0515
-------------------------------------------------

*All the choice models
* choice model for day
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & testsample == 0, baseoutcome(2) iter(20) 
est sto mlogit_typday
predict p_day* if testsample == 1 & ttdurday!=.
summarize p_day* i.choice if testsample == 1 & ttdurday!=., separator(14)

* choice model for periods
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & testsample == 0, baseoutcome(2) iter(20) 
est sto mlogit_period
predict p_period* if testsample == 1 & ttdur!=.
summarize p_period* i.choice if testsample == 1 & ttdur!=., separator(14)

* choice model for instances
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if tuactdur24!=. & testsample == 0, baseoutcome(2) iter(20) 
est sto mlogit_inst
predict p_inst* if testsample == 1 & tuactdur24!=.
summarize p_inst* if testsample == 1 & tuactdur24!=., sep(14)

* choice model during weekend period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & action==1 & testsample == 0, baseoutcome(2) iter(20)
est sto mlogit_wknd
predict p_wknd* if testsample == 1 & action==1 & ttdurday!=.
summarize p_wknd* i.choice if testsample == 1 & action==1 & ttdurday!=., separator(14)

* choice model during weekday period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & weekend==0 & testsample == 0, baseoutcome(2) iter(20) 
est sto mlogit_wkday
predict p_wkday* if testsample == 1 & weekend==0 & ttdurday!=.
summarize p_wkday* i.choice if testsample == 1 & weekend==0 & ttdurday!=., separator(14)

* choice model during offpeak period
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & action==2 & testsample == 0, baseoutcome(2) iter(20)
est sto mlogit_offpeak
predict p_offpeak* if testsample == 1 & action==2 & ttdur!=.
summarize p_offpeak* i.choice if testsample == 1 & action==2 & ttdur!=., separator(14)

* peak period choice model
gen peak = 1 if action ==3 | action ==5

mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdur!=. & peak == 1 & testsample == 0, baseoutcome(2) iter(20)
est sto mlogit_peak
predict p_peak* if testsample == 1 & peak ==1 & ttdur!=.
summarize p_peak* i.choice if testsample == 1 & peak ==1 & ttdur!=., separator(14)

* choice model during critical period
gen cripeak = 1 if ttdur!=. & action==4

mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if cripeak == 1 & testsample == 0, baseoutcome(2) iter(20)
est sto mlogit_cripeak
predict p_cripeak* if testsample == 1 & cripeak ==1 

* Output the choice models
esttab mlogit_typday mlogit_period mlogit_inst using timescalechmodels.html, se aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to sleeping at different instance resolutions") mtitle("Typical day" "Any period" "Single instance")

esttab mlogit_wkday mlogit_wknd using daytypechmodels.html, se aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to sleeping during weekday or weekend") mtitle("Weekday" "Weekend")

esttab mlogit_offpeak mlogit_peak mlogit_cripeak using periodschmodels.html, se aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to sleeping during different periods") mtitle("Off peak" "Peak (morning & evening)" "Critical peak")

esttab mlogit_typday mlogit_period mlogit_inst mlogit_wkday mlogit_wknd mlogit_offpeak mlogit_peak mlogit_cripeak using allchmodels.html, se aic obslast scalar(F) bic r2 label nonumber title("All the decision models for choice of all considered activities with respect to sleeping") mtitle("Typical day" "Any period" "Single instance" "Weekday" "Weekend" "Off peak" "Peak (morning & evening)" "Critical peak")

* Output the choice models with eform
esttab mlogit_typday mlogit_period mlogit_inst using etimescalechmodels.html, eform se aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to sleeping at different instance resolutions") mtitle("Typical day" "Any period" "Single instance")

esttab mlogit_wkday mlogit_wknd using edaytypechmodels.html, eform se aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to sleeping during weekday or weekend") mtitle("Weekday" "Weekend")

esttab mlogit_offpeak mlogit_peak mlogit_cripeak using eperiodschmodels.html, eform se aic obslast scalar(F) bic r2 label nonumber title("Decision models for choice of all considered activities with respect to sleeping during different periods") mtitle("Off peak" "Peak (morning & evening)" "Critical peak")

esttab mlogit_typday mlogit_period mlogit_inst mlogit_wkday mlogit_wknd mlogit_offpeak mlogit_peak mlogit_cripeak using eallchmodels.html, eform se aic obslast scalar(F) bic r2 label nonumber title("All the decision models for choice of all considered activities with respect to sleeping") mtitle("Typical day" "Any period" "Single instance" "Weekday" "Weekend" "Off peak" "Peak (morning & evening)" "Critical peak")

* Output duration models
*weekday
esttab reg3_wkday reg3_wkday_justhome reg3_wkday_sleeping reg3_wkday_laundry reg3_wkday_dishwashing reg3_wkday_cooking reg3_wkday_cleaning  reg3_wkday_yardwork reg3_wkday_exercise reg3_wkday_pooluse reg3_wkday_TVgaming reg3_wkday_computeruse reg3_wkday_traveling reg3_wkday_awayatwork reg3_wkday_away using durwkdayslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during weekday") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*weekend
esttab reg3_wknd reg3_wknd_justhome reg3_wknd_sleeping reg3_wknd_laundry reg3_wknd_dishwashing reg3_wknd_cooking reg3_wknd_cleaning  reg3_wknd_yardwork reg3_wknd_exercise reg3_wknd_pooluse reg3_wknd_TVgaming reg3_wknd_computeruse reg3_wknd_traveling reg3_wknd_awayatwork reg3_wknd_away using durwkndslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during weekend") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*peak
esttab reg3_peak reg3_peak_justhome reg3_peak_sleeping reg3_peak_laundry reg3_peak_dishwashing reg3_peak_cooking reg3_peak_cleaning  reg3_peak_yardwork reg3_peak_exercise reg3_peak_pooluse reg3_peak_TVgaming reg3_peak_computeruse reg3_peak_traveling reg3_peak_awayatwork reg3_peak_away using durpeakslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during peak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*off peak
esttab reg3_offpeak reg3_offpeak_justhome reg3_offpeak_sleeping reg3_offpeak_laundry reg3_offpeak_dishwashing reg3_offpeak_cooking reg3_offpeak_cleaning  reg3_offpeak_yardwork reg3_offpeak_exercise reg3_offpeak_pooluse reg3_offpeak_TVgaming reg3_offpeak_computeruse reg3_offpeak_traveling reg3_offpeak_awayatwork reg3_offpeak_away using duroffpeakslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during off peak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*critical peak
esttab reg3_cripeak reg3_cripeak_justhome reg3_cripeak_sleeping reg3_cripeak_laundry reg3_cripeak_dishwashing reg3_cripeak_cooking reg3_cripeak_cleaning  reg3_cripeak_yardwork reg3_cripeak_exercise reg3_cripeak_pooluse reg3_cripeak_TVgaming reg3_cripeak_computeruse reg3_cripeak_traveling reg3_cripeak_awayatwork reg3_cripeak_away using durcripeakslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during critical peak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*an instance
esttab reg3_inst reg3_inst_justhome reg3_inst_sleeping reg3_inst_laundry reg3_inst_dishwashing reg3_inst_cooking reg3_inst_cleaning  reg3_inst_yardwork reg3_inst_exercise reg3_inst_pooluse reg3_inst_TVgaming reg3_inst_computeruse reg3_inst_traveling reg3_inst_awayatwork reg3_inst_away using durinstslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities in an instance") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*period
esttab reg3_period reg3_period_justhome reg3_period_sleeping reg3_period_laundry reg3_period_dishwashing reg3_period_cooking reg3_period_cleaning  reg3_period_yardwork reg3_period_exercise reg3_period_pooluse reg3_period_TVgaming reg3_period_computeruse reg3_period_traveling reg3_period_awayatwork reg3_period_away using durperiodslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during day") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*day
esttab reg3_day reg3_day_justhome reg3_day_sleeping reg3_day_laundry reg3_day_dishwashing reg3_day_cooking reg3_day_cleaning  reg3_day_yardwork reg3_day_exercise reg3_day_pooluse reg3_day_TVgaming reg3_day_computeruse reg3_day_traveling reg3_day_awayatwork reg3_day_away using durdayslide.html, se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during day") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

* Output duration models with beta coeffients
*weekday
esttab reg3_wkday reg3_wkday_justhome reg3_wkday_sleeping reg3_wkday_laundry reg3_wkday_dishwashing reg3_wkday_cooking reg3_wkday_cleaning  reg3_wkday_yardwork reg3_wkday_exercise reg3_wkday_pooluse reg3_wkday_TVgaming reg3_wkday_computeruse reg3_wkday_traveling reg3_wkday_awayatwork reg3_wkday_away using βdurwkdayslide.html, beta se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during weekday") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*weekend
esttab reg3_wknd reg3_wknd_justhome reg3_wknd_sleeping reg3_wknd_laundry reg3_wknd_dishwashing reg3_wknd_cooking reg3_wknd_cleaning  reg3_wknd_yardwork reg3_wknd_exercise reg3_wknd_pooluse reg3_wknd_TVgaming reg3_wknd_computeruse reg3_wknd_traveling reg3_wknd_awayatwork reg3_wknd_away using βdurwkndslide.html, beta se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during weekend") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*peak
esttab reg3_peak reg3_peak_justhome reg3_peak_sleeping reg3_peak_laundry reg3_peak_dishwashing reg3_peak_cooking reg3_peak_cleaning  reg3_peak_yardwork reg3_peak_exercise reg3_peak_pooluse reg3_peak_TVgaming reg3_peak_computeruse reg3_peak_traveling reg3_peak_awayatwork reg3_peak_away using βdurpeakslide.html, beta se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during peak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*off peak
esttab reg3_offpeak reg3_offpeak_justhome reg3_offpeak_sleeping reg3_offpeak_laundry reg3_offpeak_dishwashing reg3_offpeak_cooking reg3_offpeak_cleaning  reg3_offpeak_yardwork reg3_offpeak_exercise reg3_offpeak_pooluse reg3_offpeak_TVgaming reg3_offpeak_computeruse reg3_offpeak_traveling reg3_offpeak_awayatwork reg3_offpeak_away using βduroffpeakslide.html, beta se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during off peak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*critical peak
esttab reg3_cripeak reg3_cripeak_justhome reg3_cripeak_sleeping reg3_cripeak_laundry reg3_cripeak_dishwashing reg3_cripeak_cooking reg3_cripeak_cleaning  reg3_cripeak_yardwork reg3_cripeak_exercise reg3_cripeak_pooluse reg3_cripeak_TVgaming reg3_cripeak_computeruse reg3_cripeak_traveling reg3_cripeak_awayatwork reg3_cripeak_away using βdurcripeakslide.html, beta se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during critical peak") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*an instance
esttab reg3_inst reg3_inst_justhome reg3_inst_sleeping reg3_inst_laundry reg3_inst_dishwashing reg3_inst_cooking reg3_inst_cleaning  reg3_inst_yardwork reg3_inst_exercise reg3_inst_pooluse reg3_inst_TVgaming reg3_inst_computeruse reg3_inst_traveling reg3_inst_awayatwork reg3_inst_away using βdurinstslide.html, beta se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities in an instance") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*period
esttab reg3_period reg3_period_justhome reg3_period_sleeping reg3_period_laundry reg3_period_dishwashing reg3_period_cooking reg3_period_cleaning  reg3_period_yardwork reg3_period_exercise reg3_period_pooluse reg3_period_TVgaming reg3_period_computeruse reg3_period_traveling reg3_period_awayatwork reg3_period_away using βdurperiodslide.html, beta se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during day") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

*day
esttab reg3_day reg3_day_justhome reg3_day_sleeping reg3_day_laundry reg3_day_dishwashing reg3_day_cooking reg3_day_cleaning  reg3_day_yardwork reg3_day_exercise reg3_day_pooluse reg3_day_TVgaming reg3_day_computeruse reg3_day_traveling reg3_day_awayatwork reg3_day_away using βdurdayslide.html, beta se aic obslast scalar(F) bic r2 label nonumber title("Duration models for activities during day") mtitle("all activities" "justhome" "sleeping" "laundry" "dishwashing" "cooking" "cleaning" "yardwork" "exercise" "pooluse" "TVgaming"  "computeruse" "traveling" "awayatwork" "away" )

* Colorado
summarize i.choice if gestfips ==8 & ttdurday!=., sep(0)
summarize i.choice if gestfips == 8 & ttdur!=., separator(0)
summarize i.choice if gestfips ==8 & tuactdur24!=., sep(0)

table choice if gestfips ==8 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if gestfips ==8 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 
table choice if gestfips ==8 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24) 

* California
summarize i.choice if gestfips ==6 & ttdurday!=., sep(0)
summarize i.choice if gestfips == 6 & ttdur!=., separator(0)
summarize i.choice if gestfips ==6 & tuactdur24!=., sep(0)

table choice if gestfips ==6 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if gestfips ==6 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 
table choice if gestfips ==6 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24)

* Wyoming
summarize i.choice if gestfips ==56 & ttdurday!=., sep(0)
summarize i.choice if gestfips ==56 & ttdur!=., separator(0)
summarize i.choice if gestfips ==56 & tuactdur24!=., sep(0)

table choice if gestfips ==56 & ttdurday!=., contents(N tucaseid mean ttdurday sd ttdurday) 
table choice if gestfips ==56 & ttdur!=., contents(N tucaseid mean ttdur sd ttdur) 

* day
regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0 , beta
est sto reg3_day

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & computeruse == 1, beta
est sto reg3_day_computeruse

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & sleeping == 1, beta
est sto reg3_day_sleeping

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & traveling == 1, beta
est sto reg3_day_traveling

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cleaning == 1, beta
est sto reg3_day_cleaning

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & dishwashing == 1, beta
est sto reg3_day_dishwashing

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & yardwork == 1, beta
est sto reg3_day_yardwork

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cooking == 1, beta
est sto reg3_day_cooking

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & pooluse == 1, beta
est sto reg3_day_pooluse

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & TVgaming == 1, beta
est sto reg3_day_TVgaming

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & exercise == 1, beta
est sto reg3_day_exercise

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & laundry == 1, beta
est sto reg3_day_laundry

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & justhome == 1, beta
est sto reg3_day_justhome

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & away == 1, beta
est sto reg3_day_away

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & awayatwork == 1, beta
est sto reg3_day_awayatwork

* per period per activity
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0 , beta
est sto reg3_period

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & computeruse == 1, beta
est sto reg3_period_computeruse

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & sleeping == 1, beta
est sto reg3_period_sleeping

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & traveling == 1, beta
est sto reg3_period_traveling

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cleaning == 1, beta
est sto reg3_period_cleaning

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & dishwashing == 1, beta
est sto reg3_period_dishwashing

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & yardwork == 1, beta
est sto reg3_period_yardwork

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cooking == 1, beta
est sto reg3_period_cooking

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & pooluse == 1, beta
est sto reg3_period_pooluse

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & TVgaming == 1, beta
est sto reg3_period_TVgaming

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & exercise == 1, beta
est sto reg3_period_exercise

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & laundry == 1, beta
est sto reg3_period_laundry

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & justhome == 1, beta
est sto reg3_period_justhome

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & away == 1, beta
est sto reg3_period_away

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & awayatwork == 1, beta
est sto reg3_period_awayatwork

* single instances
regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0, beta
est sto reg3_inst

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & computeruse == 1, beta
est sto reg3_inst_computeruse

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & sleeping == 1, beta
est sto reg3_inst_sleeping

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & traveling == 1, beta
est sto reg3_inst_traveling

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cleaning == 1, beta
est sto reg3_inst_cleaning

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & dishwashing == 1, beta
est sto reg3_inst_dishwashing

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & yardwork == 1, beta
est sto reg3_inst_yardwork

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & cooking == 1, beta
est sto reg3_inst_cooking

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & pooluse == 1, beta
est sto reg3_inst_pooluse

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & TVgaming == 1, beta
est sto reg3_inst_TVgaming

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & exercise == 1, beta
est sto reg3_inst_exercise

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & laundry == 1, beta
est sto reg3_inst_laundry

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & justhome == 1, beta
est sto reg3_inst_justhome

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & away == 1, beta
est sto reg3_inst_away

regress tuactdur24 i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if testsample == 0  & awayatwork == 1, beta
est sto reg3_inst_awayatwork

*critical peak periods
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0, beta
est sto reg3_cripeak

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & computeruse == 1, beta
est sto reg3_cripeak_computeruse

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & sleeping == 1, beta
est sto reg3_cripeak_sleeping

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & traveling == 1, beta
est sto reg3_cripeak_traveling

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & cleaning == 1, beta
est sto reg3_cripeak_cleaning

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & dishwashing == 1, beta
est sto reg3_cripeak_dishwashing

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & yardwork == 1, beta
est sto reg3_cripeak_yardwork

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & cooking == 1, beta
est sto reg3_cripeak_cooking

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & pooluse == 1, beta
est sto reg3_cripeak_pooluse

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & TVgaming == 1, beta
est sto reg3_cripeak_TVgaming

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & exercise == 1, beta
est sto reg3_cripeak_exercise

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & laundry == 1, beta
est sto reg3_cripeak_laundry

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & justhome == 1, beta
est sto reg3_cripeak_justhome

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & away == 1, beta
est sto reg3_cripeak_away

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action == 4 & testsample == 0  & awayatwork == 1, beta
est sto reg3_cripeak_awayatwork

* off peak periods
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0, beta
est sto reg3_offpeak

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & computeruse == 1, beta
est sto reg3_offpeak_computeruse

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & sleeping == 1, beta
est sto reg3_offpeak_sleeping

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & traveling == 1, beta
est sto reg3_offpeak_traveling

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & cleaning == 1, beta
est sto reg3_offpeak_cleaning

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & dishwashing == 1, beta
est sto reg3_offpeak_dishwashing

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & yardwork == 1, beta
est sto reg3_offpeak_yardwork

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & cooking == 1, beta
est sto reg3_offpeak_cooking

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & pooluse == 1, beta
est sto reg3_offpeak_pooluse

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & TVgaming == 1, beta
est sto reg3_offpeak_TVgaming

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & exercise == 1, beta
est sto reg3_offpeak_exercise

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & laundry == 1, beta
est sto reg3_offpeak_laundry

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & justhome == 1, beta
est sto reg3_offpeak_justhome

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & away == 1, beta
est sto reg3_offpeak_away

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==2 & testsample == 0  & awayatwork == 1, beta
est sto reg3_offpeak_awayatwork

*peak periods
regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0, beta
est sto reg3_peak

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & computeruse == 1, beta
est sto reg3_peak_computeruse

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & sleeping == 1, beta
est sto reg3_peak_sleeping

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & traveling == 1, beta
est sto reg3_peak_traveling

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & cleaning == 1, beta
est sto reg3_peak_cleaning

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & dishwashing == 1, beta
est sto reg3_peak_dishwashing

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & yardwork == 1, beta
est sto reg3_peak_yardwork

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & cooking == 1, beta
est sto reg3_peak_cooking

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & pooluse == 1, beta
est sto reg3_peak_pooluse

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & TVgaming == 1, beta
est sto reg3_peak_TVgaming

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & exercise == 1, beta
est sto reg3_peak_exercise

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & laundry == 1, beta
est sto reg3_peak_laundry

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & justhome == 1, beta
est sto reg3_peak_justhome

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & away == 1, beta
est sto reg3_peak_away

regress ttdur i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if peak ==1 & testsample == 0  & awayatwork == 1, beta
est sto reg3_peak_awayatwork

*weekend periods
regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0, beta
est sto reg3_wknd

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & computeruse == 1, beta
est sto reg3_wknd_computeruse

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & sleeping == 1, beta
est sto reg3_wknd_sleeping

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & traveling == 1, beta
est sto reg3_wknd_traveling

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & cleaning == 1, beta
est sto reg3_wknd_cleaning

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & dishwashing == 1, beta
est sto reg3_wknd_dishwashing

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & yardwork == 1, beta
est sto reg3_wknd_yardwork

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & cooking == 1, beta
est sto reg3_wknd_cooking

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & pooluse == 1, beta
est sto reg3_wknd_pooluse

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & TVgaming == 1, beta
est sto reg3_wknd_TVgaming

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & exercise == 1, beta
est sto reg3_wknd_exercise

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & laundry == 1, beta
est sto reg3_wknd_laundry

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & justhome == 1, beta
est sto reg3_wknd_justhome

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & away == 1, beta
est sto reg3_wknd_away

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if action ==1 & testsample == 0  & awayatwork == 1, beta
est sto reg3_wknd_awayatwork

*weekday periods
regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0, beta
est sto reg3_wkday

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & computeruse == 1, beta
est sto reg3_wkday_computeruse

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & sleeping == 1, beta
est sto reg3_wkday_sleeping

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & traveling == 1, beta
est sto reg3_wkday_traveling

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & cleaning == 1, beta
est sto reg3_wkday_cleaning

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & dishwashing == 1, beta
est sto reg3_wkday_dishwashing

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & yardwork == 1, beta
est sto reg3_wkday_yardwork

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & cooking == 1, beta
est sto reg3_wkday_cooking

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & pooluse == 1, beta
est sto reg3_wkday_pooluse

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & TVgaming == 1, beta
est sto reg3_wkday_TVgaming

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & exercise == 1, beta
est sto reg3_wkday_exercise

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & laundry == 1, beta
est sto reg3_wkday_laundry

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & justhome == 1, beta
est sto reg3_wkday_justhome

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & away == 1, beta
est sto reg3_wkday_away

regress ttdurday i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if weekend ==0 & testsample == 0  & awayatwork == 1, beta
est sto reg3_wkday_awayatwork


table choice if gestfips ==56 & tuactdur24!=., contents(N tucaseid mean tuactdur24 sd tuactdur24)

*ANOVA May 12, 2021
use "C:\Users\wolawale\Documents\on PC mode\ATUS new codes\atusallmodels.dta"
label define labelsample 0 "Model sample" 1 "Test sample"
label values testsample labelsample
anova tuactdur24 testsample
anova ttdur testsample
anova ttdurday testsample
anova choice testsample if tuactdur24!=.
anova choice testsample if ttdur!=.
anova choice testsample if ttdurday!=.

anova choice p_wwknd* if testsample==1

tab choice choice
tab choice choice if testsample==1
tab choice choice if testsample==1 & ttdurday==1
tab choice choice if testsample==1 & ttdurday!=.

*choice model for day scale for model sample
mlogit choice i.tesex i.hetelhhd i.trhhchild i.hubus teage trnumhou trtalone trchildnum i.incomelevl i.telfs i.peeduca i.ptdtrace i.prcitshp i.pehspnon i.hehousut i.hrhtype i.hetenure tuyear i.season i.tudiaryday i.trholiday i.gereg if ttdurday!=. & testsample == 0, baseoutcome(2) iter(20)

* August 3, 2021
* retry this to find out the confusion matrix
egen pred_cripeakmax = rowmax(p_cripeak*)
g pred_cripeakhalfmax = pred_cripeakmax/2
g pred_cripeakchoice = .
forv i=1/14 { 
replace pred_cripeakchoice = `i' if (p_cripeak`i' > pred_cripeakhalfmax) 
}
local choice_cripeaklab: value label choice
label values pred_cripeakchoice `choice_cripeaklab'
tab choice pred_cripeakchoice if testsample==1

* Thought to compare the predicted mean probabilities with the unconditional probabilities directly
*Set directoryE
cd "E:\PhD Mines\ENGY 707\Data\ATUS"
import delimited "E:\PhD Mines\ENGY 707\Data\ATUS\prep_choice_predictions for ks_test.csv", encoding(UTF-8) clear 
label define Group 1 "Actual" 2 "Predicted"
label values group Group
summarize mean
ksmirnov mean, by(group) exact
ksmirnov mean if time == "Day", by(group) exact
ksmirnov mean if time == "Period", by(group) exact
ksmirnov mean if time == "Sing_inst", by(group) exact
ksmirnov mean if time == "Cripeak", by(group) exact
ksmirnov mean if time == "Offpeak" , by(group) exact
ksmirnov mean if time == "Peak", by(group) exact
ksmirnov mean if time == "Weekend", by(group) exact
ksmirnov mean if time == "Weekday", by(group) exact

kdensity mean if group ==1, plot (kdensity mean if group ==2) ///
	legend(label(1 "Actual") label(2 "Predicted") rows(1))
  
kdensity mean if group ==1 & time == "Day", plot (kdensity mean if group ==2 & time == "Day") legend(label(1 "Actual Day probs") label(2 "Predicted Day probs") rows(1))
kdensity mean if group ==1 & time == "Period", plot (kdensity mean if group ==2 & time == "Period") legend(label(1 "Actual period probs") label(2 "Predicted period probs") rows(1))
kdensity mean if group ==1 & time == "Sing_inst", plot (kdensity mean if group ==2 & time == "Sing_inst") legend(label(1 "Actual inst probs") label(2 "Predicted inst probs") rows(1))
kdensity mean if group ==1 & time == "Weekend", plot (kdensity mean if group ==2 & time == "Weekend") legend(label(1 "Actual weekend probs") label(2 "Predicted weekend probs") rows(1))
kdensity mean if group ==1 & time == "Weekday", plot (kdensity mean if group ==2 & time == "Weekday") legend(label(1 "Actual weekday probs") label(2 "Predicted weekday probs") rows(1))
kdensity mean if group ==1 & time == "Peak", plot (kdensity mean if group ==2 & time == "Peak") legend(label(1 "Actual peak probs") label(2 "Predicted peak probs") rows(1))
 
  
kdensity mean if group ==1, plot (kdensity mean if group ==2) legend(label(1 "Actual") label(2 "Predicted") rows(1))
  
kdensity mean if group ==1 & time == "Day", plot (kdensity mean if group ==2 & time == "Day") legend(label(1 "Actual Day") label(2 "Predicted Day") rows(1))
kdensity mean if group ==1 & time == "Period", plot (kdensity mean if group ==2 & time == "Period") legend(label(1 "Actual period") label(2 "Predicted period") rows(1))
kdensity mean if group ==1 & time == "Sing_inst", plot (kdensity mean if group ==2 & time == "Sing_inst") legend(label(1 "Actual inst") label(2 "Predicted inst") rows(1))
kdensity mean if group ==1 & time == "Weekend", plot (kdensity mean if group ==2 & time == "Weekend") legend(label(1 "Actual weekend") label(2 "Predicted weekend") rows(1))
kdensity mean if group ==1 & time == "Weekday", plot (kdensity mean if group ==2 & time == "Weekday") legend(label(1 "Actual weekday") label(2 "Predicted weekday") rows(1))
kdensity mean if group ==1 & time == "Peak", plot (kdensity mean if group ==2 & time == "Peak") legend(label(1 "Actual peak") label(2 "Predicted peak") rows(1))
 
 
