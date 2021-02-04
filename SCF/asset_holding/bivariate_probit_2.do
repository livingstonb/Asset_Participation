
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

gen nonretirfinwealth = liq + cds + nmmf + savbnd + stocks + bond + stmutf
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

// #delimit ;
// biprobit hasstocks hasbonds2 lwealth learnings educ yr1989 age sqage married
// 	homeowner finrisktol kids budgeting_horizon badcredit is_saving hbus
// 	exercisedstockoption depspread fedfunds, vce(robust);
// #delimit cr


#delimit ;
local xvars lwealth learnings educ yr1989 age sqage married homeowner finrisktol
	kids hbus exercisedstockoption stableincome;
#delimit cr

#delimit ;
reg hasstocks `xvars', robust;
#delimit cr

#delimit ;
local sel
	participant = `xvars' budgeting_horizon badcredit is_saving 
	hasdebt lnonretirfinwealth fedfunds depspread;
#delimit ;

#delimit ;
heckman hasstocks `xvars', robust  select(`sel');
#delimit cr

#delimit ;
local sel
	hasbonds2 = `xvars' budgeting_horizon badcredit is_saving 
	hasdebt lnonretirfinwealth fedfunds depspread;
#delimit ;


gen nobonds = (hasbonds2 == 0)
#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage
	married homeowner c.finrisktol##b0.exercisedstockoption kids hbus stableincome
	hasdebt budgeting_horizon badcredit is_saving;
#delimit cr

#delimit ;
local sel
	nobonds = `xvars' fedfunds depspread;
#delimit ;

#delimit ;
heckman hasstocks `xvars', robust  select(`sel');
#delimit cr

#delimit ;
heckman hasbonds2 `xvars' depspread, robust  select(`sel');
#delimit cr

// Interaction with bondholding
#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage
	married homeowner finrisktol exercisedstockoption kids hbus stableincome
	hasdebt budgeting_horizon badcredit is_saving;
#delimit cr

reg hasstocks b0.hasbonds2#c.(`xvars'), robust


#delimit ;
local xvars lwealth lnonretirfinwealth learnings yr1989 age sqage
	married exercisedstockoption kids hbus stableincome
	hasdebt budgeting_horizon badcredit is_saving;
#delimit cr

reg hasstocks `xvars' b0.hasbonds2#c.(educ finrisktol homeowner stableincome), robust

// With expectations?

// Recursive bivariate probit
#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome is_saving budgeting_horizon hasdebt
	badcredit;
#delimit cr

#delimit ;
biprobit (hasstocks = `xvars' exercisedstockoption hasbonds2)
	(hasbonds2 = `xvars' fedfunds depspread), vce(robust);
#delimit cr

// IV
#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome is_saving budgeting_horizon hasdebt
	badcredit;
#delimit cr

#delimit ;
ivregress 2sls hasstocks `xvars' exercisedstockoption
	(hasbonds2 = fedfunds depspread), vce(robust) first;
#delimit cr


eststo EST1: reg hasstocks lwealth learnings educ yr1989 age sqage married homeowner finrisktol kids budgeting_horizon badcredit is_saving hbus, robust
estimates title: "Stocks"
eststo EST2: reg hasbonds2 lwealth learnings educ yr1989 age sqage married homeowner finrisktol kids budgeting_horizon badcredit is_saving hbus, robust
estimates title: "Bonds"

if `threshold' > 0 {
    local thresh "_thresh"
}
else {
	local thresh ""
}

#delimit ;
esttab EST1 EST2 using "stats/output/estimates_table`thresh'.tex",
	se ar2 label replace wide nonumbers;
#delimit cr


// Share estimation
// hbrok
