
use "../output/savrate.dta", clear
gen year = year(dofq(period))
collapse savrate fedfunds depspread, by(year)

tempfile rates
save `rates'

use "build/output/SCF_89_19_cleaned", clear


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

gen participant = (hasstocks == 1) | (hasbonds2 == 1)

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

#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome is_saving budgeting_horizon hasdebt
	badcredit;
#delimit cr

#delimit ;
biprobit (hasstocks = `xvars' exercisedstockoption hasbonds2 econexp)
	(hasbonds2 = `xvars' fedfunds depspread), vce(robust);
#delimit cr

// STOCKS BUT NO BONDS
// gen onlystocks = (hasstocks == 1) & (hasbonds2 == 0)
// gen nobonds = (hasbonds2 == 0)
#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome is_saving budgeting_horizon hasdebt
	badcredit;
#delimit cr
heckman hasstocks `xvars', robust select(participant = `xvars' depspread fedfunds)

#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome is_saving budgeting_horizon hasdebt
	badcredit;
#delimit cr
reg hasstocks `xvars', robust



#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome is_saving budgeting_horizon hasdebt
	badcredit;
#delimit cr

#delimit ;
biprobit (hasstocks = `xvars' exercisedstockoption econexp)
	(hasbonds2 = `xvars' fedfunds depspread) if (participant == 1), vce(robust);
#delimit cr
