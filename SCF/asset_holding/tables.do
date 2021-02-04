clear
tempfile tables
save `tables', emptyok

use "build/output/SCF_89_19_cleaned", clear
gen implic = Y1 - 10 * YY1
keep if implic == 1
keep if networth > 0
keep if inrange(age, 20, 64)

gen hasbonds = gbmutf + notxbnd + govtbnd + mma + cds > 0
gen hasstocks = stocks + stmutf > 0

gen hasboth = (hasbonds == 1) & (hasstocks == 1)
gen haseither = (hasbonds == 1) | (hasstocks == 1)

local variables hasbonds hasstocks hasboth haseither

// Aggregate
preserve
collapse `variables' [fw=fwgt]
gen category = "Total"

append using `tables'
save `tables', replace
restore

// Education
preserve
gen educvar = 1 if inrange(educ, 1, 8)
replace educvar = 2 if educ == 12
replace educvar = 3 if inrange(educ, 13, 15)

collapse `variables' [fw=fwgt], by(educvar)
drop if missing(educvar)

gen category = "High school or less" if educvar == 1
replace category = "Bachelor's degree" if educvar == 2
replace category = "Graduate or professional degree" if educvar == 3
drop educvar

append using `tables'
save `tables', replace
restore

// Homeowner
preserve

collapse `variables' [fw=fwgt], by(homeowner)
drop if missing(homeowner)

gen category = "Homeowner" if homeowner == 1
replace category = "Renter" if homeowner == 0
drop homeowner

append using `tables'
save `tables', replace
restore

// Married
preserve

collapse `variables' [fw=fwgt], by(married)
drop if missing(married)

gen category = "Married" if married == 1
replace category = "Not married" if married == 0
drop married

append using `tables'
save `tables', replace
restore

// Employment status
preserve

collapse `variables' [fw=fwgt], by(emphh)
drop if missing(emphh)

gen category = "Employed" if emphh == 1
replace category = "Unemployed or NILF" if emphh == 0
drop emphh

append using `tables'
save `tables', replace
restore

// Health insurance
preserve

collapse `variables' [fw=fwgt], by(healthinsured)
drop if missing(healthinsured)

gen category = "All members insured" if healthinsured == 1
replace category = "At least one member uninsured" if healthinsured == 0
drop healthinsured

append using `tables'
save `tables', replace
restore

// Budgeting horizon
preserve

gen horizon = 1 if budgeting_horizon == 1
replace horizon = 2 if inlist(budgeting_horizon, 2, 3)
replace horizon = 3 if inlist(budgeting_horizon, 4, 5)

collapse `variables' [fw=fwgt], by(horizon)
drop if missing(horizon)

gen category = "Next few months" if horizon == 1
replace category = "Next year or next few years" if horizon == 2
replace category = "Next 5+ years" if horizon == 3
drop horizon

append using `tables'
save `tables', replace
restore

// Stable income
preserve

collapse `variables' [fw=fwgt], by(stableincome)
drop if missing(stableincome)

gen category = "Usually predictable" if stableincome == 1
replace category = "Not usually predictable" if stableincome  == 0
drop stableincome

append using `tables'
save `tables', replace
restore

// Restore tables
use `tables', clear