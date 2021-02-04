

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

gen yr1989 = year - 1989
gen hasstocks = stocks + stmutf > `threshold'
gen finliter = finlit1 + finlit2 + finlit3
gen badcredit = (turndown == 1) | (turnfear == 1)

label variable hasstocks "Stocks"
label variable hasbonds1 "Bond-like"
label variable hasbonds2 "Bonds"
label variable age "Age"
label variable sqage "Age-squared"
label variable lwealth "Log wealth"
label variable learnings "Log earnings"
label variable educ "Education"
label variable yr1989 "Years after 1989"
label variable married "Married"
label variable homeowner "Homeowner"
label variable finrisktol "Risk tol"
label variable kids "Children"
label variable budgeting_horizon "Planning Horiz"
label variable badcredit "Denied credit"
label variable is_saving "Is saving"
label variable hbus "Owns business"

replace finrisktol = 5 - finrisktol

eststo EST1: reg hasstocks lwealth learnings educ yr1989 age sqage married homeowner finrisktol kids budgeting_horizon badcredit is_saving hbus, robust
estimates title: "Stocks"
eststo EST2: reg hasbonds2 lwealth learnings educ yr1989 age sqage married homeowner finrisktol kids budgeting_horizon badcredit is_saving hbus, robust
estimates title: "Bond-like"
eststo EST3: reg hasbonds1 lwealth learnings educ yr1989 age sqage married homeowner finrisktol kids budgeting_horizon badcredit is_saving hbus, robust
estimates title: "Bond-like"

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
