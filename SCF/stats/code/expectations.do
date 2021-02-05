

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




gen onlycompanystock = (owncompanystock == 1) & (numstocks == 1) if !missing(owncompanystock, numstocks)

gen xonlycompanystock = onlycompanystock
replace xonlycompanystock = 1 if inrange(valcompanystock / stocks, 0.8, 1.0)

gen xhasstocks = (hasstocks == 1) & (xonlycompanystock == 0) if !missing(onlycompanystock, hasstocks)

sum hasstocks xhasstocks [fw=fwgt]

// collapse (mean) hasstocks (mean) hasbonds2 [fw=fwgt], by(tradedstocks)

sum hasstocks [aw=wgt] if (tradedstocks == 1)

gen exthasstocks = (hasstocks == 1) | (monthlytrades >= 0.2) if !missing(hasstocks, monthlytrades)
sum exthasstocks [aw=wgt]



// Identify non-participants who experiment by the inability to explain their
// transition out of stockholding. That is, the shock driving them into participation
// is transitory and unrelated to other factors.

// NO evidence that the accumulation of investing knowledge is endogenous.

// In each period, non-investors receive a tip






// has_brokerage

// num_stock_trades X3928 

// 15% of stockholders basically just own company stock

// how many only have stock because of bequest?

exercisedstockoption
owncompanystock
numstocks


// valcompanystock











reg hasstocks lwealth learnings educ yr1989 age sqage married homeowner finrisktol kids budgeting_horizon badcredit is_saving hbus, robust

// Effect of expectations on conditional equity share?
// Or conditional equity share for different educ or fin lit or liquidity levels
gen nonretirfinwealth = liq + cds + nmmf + savbnd + stocks + bond + stmutf
gen eqshare = (stocks + stmutf) / nonretirfinwealth if nonretirfinwealth > 100

gen isliquid = nonretirfinwealth >= (netlabinc / 12)

histogram eqshare [fw=fwgt] if (eqshare > 0), bin(20)
histogram eqshare [fw=fwgt] if (eqshare > 0) & (isliquid == 0), bin(20)


reg hasstocks lwealth learnings educ yr1989 age sqage married homeowner finrisktol kids budgeting_horizon badcredit is_saving hbus if (econexp == 2), robust

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

// #delimit ;
// esttab EST1 EST2 using "stats/output/estimates_table`thresh'.tex",
// 	se ar2 label replace wide nonumbers;
// #delimit cr