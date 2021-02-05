/* --- HEADER ---
This script computes various asset, earnings, and WFH statistics
for SIPP and outputs them to a spreadsheet.
*/

args sunit digit

adopath + "../ado"

// READ AND COMPUTE STATISTICS
use "build/output/annual_`sunit'.dta", clear

if `digit' == 5 {
	replace netliquid = netliquid * 3500 / 2100
	label variable netliquid "net liquid assets, scaled so median HH is $3500"
}

gen netliq_earnings_ratio = netliquid / earnings if (earnings > 1000)
label variable netliq_earnings_ratio "net liquid assets to earnings ratio for earnings > 1000"

gen earnwk = earnings / 52
label variable earnwk "Weekly earnings"

gen nla_lt_biweeklyearn = (netliquid < (2 * earnwk))
label variable nla_lt_biweeklyearn "Share with net liquid assets < 2 weeks earnings"

gen nla_lt_monthlyearn = (netliquid < (4 * earnwk))
label variable nla_lt_monthlyearn "Share with net liquid assets < 4 weeks earnings"

gen nla_lt_annearn = (netliquid < earnings)
label variable nla_lt_annearn "Share with net liquid assets < annual earnings"

gen whtm_biweeklyearn = (netliquid < (2 * earnwk)) * (netilliquid >= 5000)
label variable whtm_biweeklyearn "Share WHtM (NLIQ < 2 wks earnings and NILLIQ >= $5000)"

gen whtm_monthlyearn = (netliquid < (4 * earnwk)) * (netilliquid >= 5000)
label variable whtm_monthlyearn "Share WHtM (NLIQ < 4 wks earnings and NILLIQ >= $5000)"

gen whtm_annearn = (netliquid < earnings) * (netilliquid >= 5000)
label variable whtm_annearn "Share WHtM (NLIQ < annual earnings and NILLIQ >= $5000)"

gen phtm_biweeklyearn = (nla_lt_biweeklyearn == 1) * (whtm_biweeklyearn == 0)
replace phtm_biweeklyearn = . if missing(nla_lt_biweeklyearn, whtm_biweeklyearn)
label variable phtm_biweeklyearn "Share PHtM (NLIQ < 2 wks earnings and NILLIQ < $5000)"

gen phtm_monthlyearn = (nla_lt_monthlyearn == 1) * (whtm_monthlyearn == 0)
replace phtm_monthlyearn = . if missing(nla_lt_monthlyearn, whtm_monthlyearn)
label variable phtm_monthlyearn "Share PHtM (NLIQ < 4 wks earnings and NILLIQ < $5000)"

gen phtm_annearn = (nla_lt_annearn == 1) * (whtm_annearn == 0)
replace phtm_annearn = . if missing(nla_lt_annearn, whtm_annearn)
label variable phtm_annearn "Share PHtM (NLIQ < annual earnings and NILLIQ < $5000)"

#delimit ;
gen htm_biweeklyearn = whtm_biweeklyearn | phtm_biweeklyearn
	& !missing(whtm_biweeklyearn, phtm_biweeklyearn);
gen htm_monthlyearn = whtm_monthlyearn | phtm_monthlyearn
	& !missing(whtm_monthlyearn, phtm_monthlyearn);
gen htm_annearn = whtm_annearn | phtm_annearn
	& !missing(whtm_annearn, phtm_annearn);
#delimit cr

label variable htm_biweeklyearn "Share HTM (NLIQ < 2 wks earnings)"
label variable htm_monthlyearn "Share HTM (NLIQ < 4 wks earnings)"
label variable htm_annearn "Share HTM (NLIQ < annual earnings)"

foreach x of numlist 500 1000 2000 {
	gen nla_lt_`x'_nia_any = (netliquid < `x') if !missing(netliquid)
	label variable nla_lt_`x'_nia_any "Share with NLIQ < $`x'"
foreach y of numlist 1000 5000 {
	gen nla_lt_`x'_nia_gt_`y' = (netliquid < `x') * (netilliquid > `y')
	replace nla_lt_`x'_nia_gt_`y' = . if missing(netliquid, netilliquid)
	label variable nla_lt_`x'_nia_gt_`y' "Share with NLIQ < $`x' and NILLIQ > $`y'"
}
}

// MEAN AND MEDIAN VARIABLES FOR COLLAPSE
#delimit ;
local stats pdeposits pbonds pliqequity liquid_nocash liquid_wcash ccdebt earnings
	netliquid netliq_earnings_ratio netilliquid;
#delimit cr

label variable foodinsecure "Share who cut or skipped meals b/c not enough money"
label variable qualitative_h2m "Share who cut or skipped meals or couldn't pay utilities"

local meanstats
local medianstats
foreach var of local stats {
	local varlab: variable label `var'

	gen mean_`var' = `var'
	gen median_`var' = `var'
	label variable mean_`var' "Mean `varlab'"
	label variable median_`var' "Median `varlab'"
	local meanstats `meanstats' (mean) mean_`var'
	local medianstats `medianstats' (median) median_`var'
}

foreach var of varlist qualitative_h2m foodinsecure nla* whtm* phtm* htm* {
	local meanstats `meanstats' (mean) `var'
}

gen nworkers_unw = !missing(workfromhome)
label variable nworkers_unw "n, unwtd"

gen nworkers_wt = !missing(workfromhome)
label variable nworkers_wt "Total"

rename workfromhome pct_workfromhome
rename earnings meanwage

// CLEANING
* Sum of weights for each occupation
gen weights = 1
label variable weights "Sum of SIPP weights"

* Add blanks
local blanks "../occupations/build/output/soc`digit'dvalues2010.dta"
#delimit ;
appendblanks soc`digit'd2010 using "`blanks'",
	zeros(nworkers_wt nworkers_unw) ones(swgts)
	over1(sector) values1(0 1) rename(occ`digit'd2010);
#delimit cr

drop if missing(sector, occ`digit'd2010)

// Collapse by sector and occupation
preserve
varlabels, save

#delimit ;
collapse
	(sum) nworkers_wt (rawsum) nworkers_unw
	(mean) pct_workfromhome (mean) meanwage
	`meanstats' `medianstats' (sum) weights
	(min) blankobs
	[iw=swgts], by(sector occ`digit'd2010) fast;
#delimit cr

varlabels, restore

if `digit' == 3 {
	drop mean_earnings median_earnings weights
	gen source = "SIPP"
	label variable source "Dataset"

	drop blankobs
	save "stats/output/SIPP3d_`sunit'.dta", replace
}
else if `digit' == 5 {
	tempfile occ_and_sector
	save `occ_and_sector', replace
}
restore

// Collapse by occupation only (5-digit only)
if `digit' == 5 {
	varlabels, save

	drop if missing(sector, occ`digit'd2010)
	#delimit ;
	collapse
		(sum) nworkers_wt (rawsum) nworkers_unw
		(mean) pct_workfromhome (mean) meanwage
		`meanstats' `medianstats' (sum) weights
		(min) blankobs
		[iw=swgts], by(occ`digit'd2010) fast;
	#delimit cr
	gen sector = 2
	label define sector_lbl 2 "Pooled", modify

	varlabels, restore
	
	* Combine with occ-sector statistics
	append using `occ_and_sector'
	
	drop mean_earnings median_earnings
	
	if "`sunit'" == "person" {
	gen sunit = 0
	}
	else if "`sunit'" == "fam" {
		gen sunit = 1
	}
	else if "`sunit'" == "hh" {
		gen sunit = 2
	}
	label variable sunit "SIPP sampling unit"
	label define sunit_lbl 0 "Person"
	label define sunit_lbl 1 "Family", add
	label define sunit_lbl 2 "Household", add
	label values sunit sunit_lbl
	gen source = "SIPP"
	
	local varorder occ`digit'd2010 sector
	order `varorder'
	sort `varorder'

	drop blankobs
	save "stats/output/SIPP5d_`sunit'.dta", replace
}
