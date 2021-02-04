


// Determinants of holding stocks conditional on holding one or the other??
// Use liquid wealth as exclusion restriction

use "../output/savrate.dta", clear
gen year = year(dofq(period))
collapse savrate fedfunds depspread, by(year)

tempfile rates
save `rates'

use "build/output/SCF_89_19_cleaned", clear
replace finlit = . if year < 2016

local threshold 0

keep if networth >= 0
// keep if netlabinc > 0
keep if inrange(age, 20, 64)

gen hasearnings = (netlabinc > 0) if !missing(netlabinc)

gen lwealth = log(networth)
gen learnings = log(netlabinc)
gen hasbonds1 = gbmutf + notxbnd + govtbnd > `threshold'
gen hasbonds2 = gbmutf + notxbnd + govtbnd + mma + cds > `threshold'
gen sqage = age ^ 2
gen implic = Y1 - 10 * YY1
keep if implic == 1

gen earnq = .
gen wealthq = .
forvalues yr = 1989(3)2019 {
	xtile tempearnq = netlabinc [aw=wgt] if (year == `yr') & (netlabinc > 0), nquantiles(10)
	replace earnq = tempearnq if year == `yr'
	drop tempearnq
	
	xtile tempwealthq = networth [aw=wgt] if (year == `yr') & (networth >= 0), nquantiles(10)
	replace wealthq = tempwealthq if year == `yr'
	drop tempwealthq
}
replace earnq = 1 if (netlabinc <= 0)

gen nonretirfinwealth = liq + cds + nmmf + savbnd + stocks + bond
gen lnonretirfinwealth = log(nonretirfinwealth)
gen isliquid = nonretirfinwealth > 1000 if !missing(nonretirfinwealth)

merge m:1 year using `rates', nogen keep(3)

gen yr1989 = year - 1989
gen hasstocks = stocks + stmutf > `threshold'
gen finliter = finlit1 + finlit2 + finlit3
gen badcredit = (turndown == 1) | (turnfear == 1)
gen hasdebt = debt > 0

gen participant = (hasstocks == 1) | (hasbonds2 == 1)
gen bondsonly = (hasbonds2 == 1) & (hasstocks == 0)

label variable hasstocks "Stocks"
label variable hasbonds2 "Bonds"
label variable age "Age"
label variable sqage "Age squared"
label variable lwealth "Log wealth"
label variable learnings "Log earnings"
label variable educ "Education"
label variable yr1989 "Years after 1989"
label variable married "Married"
label variable homeowner "Homeowner"
label variable finrisktol "Risk tol"
label variable kids "Num children"
label variable budgeting_horizon "Planning horiz"
label variable badcredit "Denied credit"
label variable is_saving "Is saving"
label variable hbus "Owns business"
label variable depspread "(FFR) - (deposit rate)"
label variable fedfunds "FFR"
label variable exercisedstockoption "Recd stock option"
label variable hasdebt "Has debt"

replace finrisktol = 5 - finrisktol

// Condition on participation
// Key exclusion restriction is liquidity --> Participants much more likely to be liquid
// Dummy for zero liquid assets

// As wealth measure, use wealth / $10,000? Or use liquid wealth? Which must be positive

// For earnings, use percentile

// For liquidity variables, use:
// non-retirement financial assets divided by $10,000
// credit denial

#delimit ;
local xvars wealthq earnq hasearnings isliquid educ yr1989 age sqage married
	hasdebt homeowner kids hbus stableincome is_saving budgeting_horizon
	badcredit fedfunds depspread;
#delimit cr

#delimit ;
local xvars b0.isliquid#c.(wealthq earnq hasearnings educ yr1989 age sqage married
	hasdebt homeowner kids hbus stableincome is_saving budgeting_horizon
	badcredit fedfunds depspread);
#delimit cr

probit participant `xvars', robust
predict Z, xb
gen invmills = normalden(Z) / normal(Z)

#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome hasdebt
	invmills;
#delimit cr

#delimit ;
ivregress 2sls hasstocks `xvars' (exercisedstockoption = c.largefirm##c.(jobtenureh jobtenurep))
	if (participant == 1), robust;
#delimit cr
di "Adj-R2 = `e(r2_a)''"

reg hasstocks `xvars' exercisedstockoption if (participant == 1), robust
di "Adj-R2 = `e(r2_a)''"

// heckman hasstocks `xvars' 


// Condl on bond ownership?
#delimit ;
local xvars b0.isliquid#c.(wealthq earnq hasearnings educ yr1989 age sqage married
	hasdebt homeowner kids hbus stableincome is_saving budgeting_horizon
	badcredit fedfunds depspread);
#delimit cr

probit participant `xvars', robust
cap drop Z
cap drop invmills
predict Z, xb
gen invmills = normalden(Z) / normal(Z)

#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome hasdebt
	invmills;
#delimit cr

ivregress 2sls hasstocks `xvars' (exercisedstockoption = c.largefirm##c.(jobtenureh jobtenurep)) if (participant == 1), robust

// Participants who choose a 0% equity allocation
// What determines stock market non-participation among the financially literate?
#delimit ;
local xvars isliquid wealthq earnq hasearnings educ yr1989 age sqage married
	hasdebt homeowner kids hbus stableincome is_saving budgeting_horizon
	badcredit fedfunds depspread;
#delimit cr

probit participant `xvars', robust
cap drop Z
cap drop invmills
predict Z, xb
gen invmills = normalden(Z) / normal(Z)

#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome hasdebt
	invmills;
#delimit cr

ivregress 2sls bondsonly `xvars' (exercisedstockoption = c.largefirm##c.(jobtenureh jobtenurep)) if (participant == 1), robust


// reg hasstocks `xvars' if (hasbonds2 == 1), robust


