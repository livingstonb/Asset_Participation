
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

// gen choice = 1 if (hasstocks == 0) & (hasbonds2 == 0)
// replace choice = 2 if (hasstocks == 1) & (hasbonds2 == 0)
// replace choice = 3 if (hasstocks == 0) & (hasbonds2 == 1)
// replace choice = 4 if (hasstocks == 1) & (hasbonds2 == 1)

gen caseid = _n
expand 3

bysort caseid: gen kchoice = _n

gen participate = inlist(kchoice, 2, 3)

gen buystocks = (kchoice == 3)
gen chosen = (participant == participate) & (hasstocks == buystocks)

nlogitgen decision = kchoice(dontparticipate: 1, participate: 2|3)

// gen chosen = (kchoice == choice)
// drop choice
nlogittree kchoice decision, choice(chosen)

// Estimation
#delimit ;
local xvars lwealth learnings age sqage married homeowner finrisktol
	budgeting_horizon is_saving hbus fedfunds badcredit;
#delimit cr



#delimit ;
nlogit chosen
	|| decision: `xvars', base(dontparticipate)|| kchoice: exercisedstockoption,
	vce(robust) case(caseid);
#delimit cr














// Choose to buy bonds or not
gen caseid = _n

expand 2

bysort caseid: gen buybonds = _n
replace buybonds = buybonds - 1

// Did not buy bonds, choose to buy stocks or not
expand 2 if (buybonds == 0)
bysort caseid: gen nobonds_buystocks = _n if (buybonds == 0)
replace nobonds_buystocks = nobonds_buystocks - 1

// Did buy bonds, choose to buy stocks or not
expand 2 if (buybonds == 1)
bysort caseid: gen yesbonds_buystocks = _n if (buybonds == 1)
replace yesbonds_buystocks = yesbonds_buystocks - 1



gen choice = 1 if (hasstocks == 0) & (hasbonds2 == 0)
replace choice = 2 if (hasstocks == 1) & (hasbonds2 == 0)
replace choice = 3 if (hasstocks == 0) & (hasbonds2 == 1)
replace choice = 4 if (hasstocks == 1) & (hasbonds2 == 1)

nlogitgen response = choice(hasbonds2: )


expand 3 if (participate == 1)

bysort caseid: gen 

nlogitgen response = choice(noparticipate: 1, participate: 2|3|4)
nlogittree choice response

#delimit ;
local xvars lwealth lnonretirfinwealth learnings educ yr1989 age sqage married
	homeowner finrisktol kids hbus stableincome is_saving budgeting_horizon hasdebt
	badcredit;
#delimit cr

#delimit ;
nlogit choice `xvars' || 
#delimit cr

