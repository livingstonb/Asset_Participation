use "build/output/panel_cleaned", clear

local threshold 0

// keep if networth >= 0
// keep if wageinc > 0
keep if inrange(age, 20, 64)

sum wageinc [aw=wgt] if (wageinc > 0) & (year == 2007), detail
gen relwage = wageinc / r(p50) if (year == 2007)

sum wageinc [aw=wgt] if (wageinc > 0) & (year == 2009), detail
replace relwage = wageinc / r(p50) if (year == 2009)

gen lwealth = log(networth)
gen learnings = log(wageinc)
gen hasbonds = (cds > 0) | (bond > 0) | (hmma == 1)

gen sqage = age ^ 2
gen implic = impid - 10 * hhid
keep if implic == 1

tsset hhid period

gen hasstocks = hstocks
gen d2009 = (year == 2009)

gen participant = (hasbonds == 1) | (hasstocks == 1)

label variable hasstocks "Stocks"
label variable hasbonds "Bonds"
label variable age "Age"
label variable sqage "Age-squared"
label variable lwealth "Log wealth"
label variable learnings "Log earnings"
label variable educ "Education"
label variable married "Married"
label variable homeowner "Homeowner"
label variable finrisktol "Risk tol"
label variable kids "Children"
label variable budgeting_horizon "Planning Horiz"
label variable badcredit "Denied credit"
label variable hbus "Owns business"

replace finrisktol = 5 - finrisktol

// Asset participation and liquidity
gen lliquid = log(fliquid) if fliquid > 500

gen ptype = 0 if (participant == 0) & (L.participant == 0)
replace ptype = 1 if (participant == 0) & (L.participant == 1)
replace ptype = 2 if (participant == 1) & (L.participant == 0)
replace ptype = 3 if (participant == 1) & (L.participant == 1)

label define typelbl 0 "Out" 1 "Left" 2 "Entered" 3 "In"
label values ptype typelbl

// collapse (mean) D.lliquid [aw=wgt], by(ptype)

// gen liqfell = D.fliquid < 0 if !missing(D.fliquid)
// gen liqrose = D.fliquid > 0 if !missing(D.fliquid)

gen liqfell = D.fliquid < 0 if !missing(D.lliquid)
gen liqrose = D.fliquid > 0 if !missing(D.lliquid)

gen dliq = D.fliquid / L.fliquid if (L.fliquid > 500) & !missing(L.fliquid, fliquid) & (fliquid > 500)
gen posdliq = dliq > 0.3 if !missing(dliq)
gen negdliq = dliq < -0.3 if !missing(dliq)

keep if !missing(negdliq, posdliq, ptype)

collapse (mean) negdliq (mean) posdliq [aw=wgt], by(ptype)
gen net = posdliq - negdliq


sum D.lliquid if ()


// Regression condl on bond ownership
#delimit ;
local xvars lwealth relwage educ age sqage
	married homeowner finrisktol kids hbus
	budgeting_horizon badcredit;
#delimit cr

heckman hasstocks `xvars' if (year == 2009), select(hasbonds = `xvars' L.hasbonds) vce(robust)
// heckman hasstocks `xvars', select(L.participant = L.lwealth L.relwage L.educ L.age L.sqage L.married L.homeowner L.kids L.hbus) vce(robust)