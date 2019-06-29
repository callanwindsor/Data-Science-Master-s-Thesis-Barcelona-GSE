******************************************
********* THESIS LDA REGRESSIONS *********
******************************************

* Callan Windsor:
* For: 20 Years of Central Bank Research

******************************************
********* RESHAPE DATS & SAVE USE ********
******************************************


*Clear data and matrices. Set maximum memory and change directory clear

/*
set more off 
clear all
set matsize 800, perm

import delimited "/Users/Callan/Desktop/thesis/analysis/data_to_stata_clean.csv"

*Create long file with vector of all topic weights

*reshape long
qui reshape long ms ext ps mm hs im fin cs fs bs, i(id) j(topic)

gen topic_weight = 0
foreach var of varlist ms ext ps mm hs im fin cs fs bs {
replace topic_weight = `var' if `var' !=. 
}

gen topic_name = "topic"
replace topic_name = "ms" if ms!=.
replace topic_name = "ext" if ext!=.
replace topic_name = "ps" if ps!=.
replace topic_name = "mm" if mm!=.
replace topic_name = "hs" if hs!=.
replace topic_name = "im" if im!=.
replace topic_name = "fin" if fin!=.
replace topic_name = "cs" if cs!=.
replace topic_name = "fs" if fs!=.
replace topic_name = "bs" if bs!=.

foreach var of varlist ms ext ps mm hs im fin cs fs bs { 
qui replace `var' = 0 if `var' == .
qui replace `var' = 1 if `var' !=0
}

save "/Users/Callan/Desktop/thesis/analysis/topics_long.csv", replace
*/

******************************************
********* USE LONG FILE ******************
******************************************

******************************************
********* TOPIC MODELLING ****************
******************************************


set more off 
clear all
set matsize 800, perm

use "/Users/Callan/Desktop/thesis/analysis/topics_long.csv"

gen post_crisis = 0
replace post_crisis = 1 if year>2008
gen fed = 0
replace fed = 1 if central_bank== "US"
gen other = 0 
replace other = 1 if fed==0

eststo clear
eststo: reg topic_weight ibn.topic post_crisis#ibn.topic, nocons ro
eststo: reg topic_weight ibn.topic post_crisis#ibn.topic if other==1, nocons ro
eststo: reg topic_weight ibn.topic post_crisis#ibn.topic if fed==1, nocons ro

* Save table the latex

esttab using "/Users/Callan/Desktop/thesis/analysis/LDA_reg.tex", ///
replace label b(2) ///
coeflabels(1.topic "ms" 2.topic "ext" 3.topic "ps" 4.topic "mm" 5.topic ///
 "hs" 6.topic "im" 7.topic "fin" 8.topic "cs" 9.topic "fs" 10.topic "bs") ///
booktabs title([INSERT TITLE]) ///
width(1\hsize) r2 nonumbers ///
star(* 0.10 ** 0.05 *** 0.01) keep() not
eststo clear 

******************************************
********* TOPIC RDD ESTIMATION ***********
******************************************

set more off 
clear all
set matsize 800, perm

use "/Users/Callan/Desktop/thesis/analysis/topics_long.csv"

gen post_crisis = 0
replace post_crisis = 1 if year>2007

foreach x in ms im mm bs hs ext {

// qui cmogram topic_weight year if topic_name=="`x'" & year!=2008 & year!=2009 & year!=2010, ///
// cut(2010) scatter line(2010)  lfitci ///
// graphopts(ytitle("Topic weight") title("`x'") ylabel(, nolabels) yla(, tlength(0)) )
// graph save "rdd_`x'", replace

gen `x'0  = 2007 in 1
gen `x'1  = 2011 in 1

lpoly topic_weight year if post_crisis == 0 & topic_name=="`x'", ///
nograph kernel(triangle) gen(pre_`x') at(`x'0) bwidth(0.1)

lpoly topic_weight year if post_crisis == 1 & topic_name=="`x'", ///
nograph kernel(triangle) gen(post_`x') at(`x'1) bwidth(0.1)

gen dif_`x' = post_`x' - pre_`x'
list pre_`x' post_`x' dif_`x' in 1/1
}

grstyle init
set scheme s1mono

qui cmogram topic_weight year if topic_name=="ms" & year!=2008 & year!=2009 & year!=2010, ///
cut(2010) scatter line(2010)  lfitci lfitopts( level(95)) ///
graphopts(ytitle("Topic weight") title("Monetary policy settings") ylabel(, nolabels) yla(, tlength(0)) )
graph save "rdd_ms", replace

qui cmogram topic_weight year if topic_name=="im" & year!=2008 & year!=2009 & year!=2010, ///
cut(2010) scatter line(2010)  lfitci lfitopts( level(95)) ///
graphopts(ytitle("Topic weight") title("Inflation modelling") ylabel(, nolabels) yla(, tlength(0)) )
graph save "rdd_im", replace

qui cmogram topic_weight year if topic_name=="mm" & year!=2008 & year!=2009 & year!=2010, ///
cut(2010) scatter line(2010)  lfitci lfitopts( level(95)) ///
graphopts(ytitle("Topic weight") title("Macro modelling") ylabel(, nolabels) yla(, tlength(0)) )
graph save "rdd_mm", replace

qui cmogram topic_weight year if topic_name=="bs" & year!=2008 & year!=2009 & year!=2010, ///
cut(2010) scatter line(2010)  lfitci lfitopts( level(95)) ///
graphopts(ytitle("Topic weight") title("Banking sector") ylabel(, nolabels) yla(, tlength(0)) )
graph save "rdd_bs", replace

qui cmogram topic_weight year if topic_name=="hs" & year!=2008 & year!=2009 & year!=2010, ///
cut(2010) scatter line(2010)  lfitci lfitopts( level(95)) ///
graphopts(ytitle("Topic weight") title("Household sector") ylabel(, nolabels) yla(, tlength(0)) )
graph save "rdd_hs", replace

// qui cmogram topic_weight year if topic_name=="ext" & year!=2008 & year!=2009 & year!=2010, ///
// cut(2010) scatter line(2010)  lfitci  lfitopts( level(90)) ///
// graphopts(ytitle("Topic weight") title("External sector") ylabel(, nolabels) yla(, tlength(0)) )
// graph save "rdd_ext", replace


gr combine "rdd_ms.gph" ///
"rdd_im.gph" ///
"rdd_bs.gph" ///
"rdd_mm.gph" ///
"rdd_hs.gph" 
graph export "/Users/Callan/Desktop/thesis/thesis/rdd.pdf", replace

******************************************
********* LSA MODELLING ******************
******************************************

set more off 
clear all
set matsize 800, perm

import delimited "/Users/Callan/Desktop/thesis/analysis/cosine_to_stata.csv"

rename v1 id
rename v2 match
rename v3 distance

gen cb_id = 0
replace cb_id = 1 if cb == "US"
replace cb_id = 2 if cb == "ECB"
replace cb_id = 3 if cb == "BoE"
replace cb_id = 4 if cb == "BoC"
replace cb_id = 5 if cb == "BoJ"
replace cb_id = 6 if cb == "RBA"
replace cb_id = 7 if cb == "RBNZ"
replace cb_id = 8 if cb == "Norges"
replace cb_id = 9 if cb == "Riksbank"

gen post_crisis = 0
replace post_crisis = 1 if year>2009

eststo clear

eststo: reg distance_std ibn.cb_id ibn.cb_id#post_crisis, nocons ro

esttab using "/Users/Callan/Desktop/thesis/analysis/LSA_reg.tex", ///
replace label b(2) ///
coeflabels(1.cb_id "Fed" 2.cb_id "ECB" 3.cb_id "BoE" 4.cb_id "BoC" 5.cb_id ///
 "BoJ" 6.cb_id "RBA" 7.cb_id "RBNZ" 8.cb_id "Norges" 9.cb_id "Riksbank") ///
booktabs title([INSERT TITLE]) ///
width(1\hsize) r2 nonumbers ///
star(* 0.10 ** 0.05 *** 0.01) keep() not
eststo clear 

******************************************
********* LSA DiD MODELLING **************
******************************************

set more off 
clear all
set matsize 800, perm

import delimited "/Users/Callan/Desktop/thesis/analysis/combined_cosine_to_stata.csv"

rename v1 id
rename v2 match
rename v3 distance

gen post_crisis = 0
replace post_crisis = 1 if year>2009

gen did = post_crisis*paper_indicator

reg distance_std post_crisis paper_indicator did, r

esttab using "/Users/Callan/Desktop/thesis/analysis/DiD_reg.tex", ///
replace label b(2) ///
booktabs title([INSERT TITLE]) ///
width(1\hsize) r2 nonumbers ///
star(* 0.10 ** 0.05 *** 0.01) keep() not
eststo clear 






