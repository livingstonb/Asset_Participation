

use "../output/savrate.dta", clear
gen year = year(dofq(period))
collapse savrate fedfunds depspread, by(year)

tempfile rates
save `rates'

use "build/output/SCF_89_19_cleaned", clear
replace finlit = . if year < 2016


local threshold 0

keep if networth > 0
keep if netlabinc > 0
keep if inrange(age, 20, 64)

gen lwealth = log(networth)
gen learnings = log(netlabinc)
gen hasbonds1 = gbmutf + notxbnd + govtbnd > `threshold'
gen hasbonds2 = gbmutf + notxbnd + govtbnd + mma + cds > `threshold'
gen sqage = age ^ 2
gen implic = Y1 - 10 * YY1
keep if implic == 1

gen nonretirfinwealth = liq + cds + nmmf + savbnd + stocks + bond
gen lnonretirfinwealth = log(nonretirfinwealth)

merge m:1 year using `rates', nogen keep(3)

gen yr1989 = year - 1989
gen hasstocks = stocks + stmutf > `threshold'
gen finliter = finlit1 + finlit2 + finlit3
gen badcredit = (turndown == 1) | (turnfear == 1)
gen hasdebt = debt > 0

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

gen participant = (hasstocks == 1) | (hasbonds2 == 1)

#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage
	married homeowner kids hbus stableincome
	hasdebt budgeting_horizon badcredit is_saving;
#delimit cr

probit hasbonds2 `xvars' depspread fedfunds, robust
predict fitted

ivregress 2sls hasstocks fitted `xvars' finrisktol (exercisedstockoption = largetenured), robust
// drop fitted

gen adjusted = hasstocks - 1.522 * fitted
ivregress 2sls adjusted `xvars' finrisktol (exercisedstockoption = largetenured), robust

// ivregress 2sls hasstocks `xvars' (hasbonds2 exercisedstockoption = largetenured depspread fedfunds), robust
// reg hasstocks `xvars' exercisedstockoption if (participant == 1), robust

// heckman hasstocks `xvar's exercisedstockoption

// reg3 (hasstocks )

probit participation `xvars' depspread 