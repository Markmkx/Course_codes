*** This is the coding solution for Project 2 Case 2 Q3 (FIN 3080) ***

** This script constructs and tests P/B-based portfolios. Figures are plotted with case2_fig_plotting.R **


*** 0. Set program options and specify raw data path ***

set more off  // Set this option off to enable consecutive screen outputs
set excelxlsxlargefile on // Set this option on to enable Stata to import large excel files

* Change the following path to your own path to raw data * 
global path_to_data ="/Users/sjwang222/Desktop/FIN3080/Solution/project2/data_code"


*** 1. Form long-short portfolio using past P/B ratio ***

use $path_to_data/case2_merged_stock_return, clear

* Merge PB ratio data derived in Project 1 to the stock data *
merge 1:1 stock_code year_mon using $path_to_data/market_with_fundamental
keep if _merge == 3
drop _merge

** Following steps are same as in case2_q1, except for switching 'cap_quantile' to 'pb_quantile' **

egen stock_id = group(stock_code)
xtset stock_id year_mon

gen l_pb = l.pb
drop if l_pb == .

gen l_market_cap = l.market_cap
drop if l_market_cap == .


bys year_mon: egen pb_quantile = xtile(l_pb), p(10(10)90)

* Equal-weighted mean monthly return *
forvalue i=1/10{
bys year_mon: egen equal_ret_pb_q`i' = mean(cond(pb_quantile == `i', stock_ret, .))
}

gen equal_ret_pb_q1_q10 = equal_ret_pb_q1 - equal_ret_pb_q10


* Value-weighted mean montly return *
gen ret_cap = stock_ret * l_market_cap
forvalue j=1/10{
bys year_mon: egen total_ret_pb_q`j' = total(cond(pb_quantile == `j',ret_cap, .))
bys year_mon: egen total_market_pb_q`j' = total(cond(pb_quantile==`j', l_market_cap, .))
gen value_ret_pb_q`j' = total_ret_pb_q`j'/total_market_pb_q`j'
}
gen value_ret_pb_q1_q10 = value_ret_pb_q1 -  value_ret_pb_q10




save $path_to_data/case2_q3_data_for_regression, replace

* Calculate monthly within-group returns and save data for plotting with R *

bys year_mon pb_quantile: egen ew_monthly_ret_pb = mean(stock_ret)
bys year_mon pb_quantile: egen total_ret_cap = total(ret_cap)
bys year_mon pb_quantile: egen total_market_cap = total(l_market_cap)
gen vw_monthly_ret_pb = total_ret_cap/total_market_cap

bys pb_quantile: egen ew_ret = mean(ew_monthly_ret_pb)
bys pb_quantile: egen vw_ret = mean(vw_monthly_ret_pb)
bys pb_quantile: gen dup = cond(_N==1,0,_n)
drop if dup > 1
drop dup

gen year = year(dofm(year_mon))
gen month = month(dofm(year_mon))
gen date = mdy(month,1,year)
format date %td
rename pb_quantile group
keep date group ew_ret vw_ret

save $path_to_data/case2_q3_data_for_plotting, replace



* Go back to previous data set data and zip data to monthly time-series *
use $path_to_data/case2_q3_data_for_regression, clear
bys year_mon: gen dup = cond(_N==1,0,_n)
drop if dup > 1
drop dup



*** 2. Evaluate portfolio mean return ***

est clear
forvalue k=1/10{
	eststo: reg equal_ret_pb_q`k'
		estimates store f`k'
}
eststo: reg equal_ret_pb_q1_q10
	estimates store f11
	
esttab f* using $path_to_data/case2_q3_mean.tex, label stats(r2 N, fmt(3 0) labels(`"\(R^{2}\)"' `"Observations"')) compress t nogap b(%6.3f) noomitted drop ( ) star(* 0.1 ** 0.05 *** 0.01)  nonote  title() obslast replace


*** 3. Evaluate the CAPM Alpha ***


* Generate CAPM-related elements *
rename market_ret r_m
rename risk_free r_f
gen rm_rf = r_m - r_f

* Test CAPM alpha for equal-weighted monthly return * 
gen ew_pb_q1q10_rf = equal_ret_pb_q1_q10 - r_f
est clear

forvalue k =1/10{
gen ew_pb_q`k'_rf = equal_ret_pb_q`k' - r_f
eststo: reg ew_pb_q`k'_rf rm_rf
	estimates store f`k'
}


eststo: reg equal_ret_pb_q1_q10 rm_rf
	estimates store f11
	
/*

* Refine the regression with Newey-west standard errors *


tsset year_mon
eststo: newey equal_ret_pb_q1_q10 rm_rf , lag(12)
	estimates store f4


* Test CAPM alpha for value-weighted monthly return * 
gen vw_pb_q1q10_rf = value_ret_pb_q1_q10 - r_f
gen vw_pb_q1_rf = value_ret_pb_q1 - r_f
gen vw_pb_q10_rf = value_ret_pb_q10 - r_f

eststo: reg vw_pb_q1_rf rm_rf
	estimates store f5
eststo: reg vw_pb_q10_rf rm_rf
	estimates store f6
eststo: reg value_ret_pb_q1_q10 rm_rf
	estimates store f7
eststo: newey value_ret_pb_q1_q10 rm_rf , lag(12)
	estimates store f8

	
	*/
esttab f* using $path_to_data/case2_q3_capm.tex, label stats(r2 N, fmt(3 0) labels(`"\(R^{2}\)"' `"Observations"')) compress t nogap b(%6.3f) noomitted drop ( ) star(* 0.1 ** 0.05 *** 0.01)  nonote  title() obslast replace

