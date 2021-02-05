use "build/output/panel_cleaned", clear

local threshold 0

keep if networth >= 0
// keep if wageinc > 0
keep if inrange(age, 20, 64)

// Wage relative to median
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

gen ptype = 1 if (participant == 0) & (L.participant == 0)
replace ptype = 2 if (participant == 0) & (L.participant == 1)
replace ptype = 3 if (participant == 1) & (L.participant == 0)
replace ptype = 4 if (participant == 1) & (L.participant == 1)

label define plbl 1 "Non-participant"
label define plbl 2 "Leaver", add
label define plbl 3 "Entrant", add
label define plbl 4 "Holder", add
label values ptype plbl

// Show that transitions are highly related to HtM, or liquidity
// Variables for liquidity
// Variables for background risk
// Variables for educ, etc
// What share of households leaving the stock market is simultanously becoming HtM?
// What share entering is becoming NHtM?

sum badcredit [aw=wgt] if (year == 2009) & (ptype == 1)

sum D.badcredit [aw=wgt] if (year == 2009) & (ptype == 2)

sum D.badcredit [aw=wgt] if (year == 2009) & (ptype == 3)

sum badcredit [aw=wgt] if (year == 2009) & (ptype == 3)

// collapse (mean) badcredit [aw=wgt], by(ptype)

// Check what share of switchers faced large expenses or large income shocks
#delimit ;
gen explained =
	(largepurchase == 1) | (incfell == 1) | (committedexp == 1) | (L.committedexp == 1)
	if !missing(largepurchase, incfell, committedexp, L.committedexp);
#delimit cr

gen left = (participant == 0) if (L.participant == 1)

gen liqratio = fliquid / neededfunds if (neededfunds > 100)

gen isliquid = fliquid > neededfunds if !missing(neededfunds)


// reg left badcredit c.(D.learnings)##c.(L.isliquid) age educ, robust
//

#delimit ;
reg left badcredit L.isliquid largepurchase committedexp L.committedexp
	L.learnings incfell, robust;
#delimit cr

#delimit ;
heckman left badcredit L.isliquid largepurchase committedexp L.committedexp
	L.learnings incfell,
	select(L.participant = L.isliquid L.largepurchase educ L.budgeting_horizon)
	vce(robust);
#delimit cr

// collapse (mean) incfell [aw=wgt] if (networth > 10000) & (L.wageinc > 5000), by(left)
// drop if missing(left)

// Check change in liquid assets among switchers
// Liquid wealth and total wealth tends to go down when HH's exit fin market
// Tend to go up when HH's enter, but less clear
gen logliq = log(fliquid) if fliquid > 500
gen dlogliq = D.logliq
histogram dlogliq if (participant == 0) & (L.participant == 1)
histogram dlogliq if (participant == 1) & (L.participant == 0)
gen logfin = log(fin) if fin > 500
gen dlogfin = D.logfin
histogram dlogfin if (participant == 0) & (L.participant == 1)
histogram dlogfin if (participant == 1) & (L.participant == 0)

// Point is that liquidity plays a role
// Can it explain a LARGE share of transitions??

// Switching summary stats
gen stexit = (hasstocks == 0) if (L.hasstocks == 1)
gen stentry = (hasstocks == 1) if (L.hasstocks == 0)
gen stonly2safe = (hasstocks == 0) if (L.hasstocks == 1) & (L.hasbonds == 0)
gen bondexit = (hasbonds == 0) if (L.hasbonds == 1)
gen bond2stock = (hasstocks == 1) & (hasbonds == 0) if (L.hasbonds == 1)
gen bondentry = (hasbonds == 1) if (L.hasbonds == 0)
gen bondonly2nothing = (hasbonds == 0) & (hasstocks == 0) if (L.hasbonds == 1) & (L.hasstocks == 0)
gen sophexit = (participant == 0) if (L.participant == 1)
gen sophentry = (participant == 1) if (L.participant == 0)

// Bond transitions conditional on no-stockholding
gen nostock = (hasstocks == 0) & (L.hasstocks == 0)
sum bondexit [aw=wgt] if (hasstocks > L.hasstocks)
sum bondexit [aw=wgt] if (hasstocks == 0) & (L.hasstocks == 0)
sum bondexit [aw=wgt] if (fliquid / L.fliquid > 1) & !missing(fliquid, L.fliquid) & (nostock == 1)
sum bondentry [aw=wgt] if (nostock == 0)

// Transitions for participants
gen part_stexit = (hasstocks == 0) if (L.hasstocks == 1) & (participant == 1) & (L.participant == 1)
gen part_bondexit = (hasbonds == 0) if (L.hasbonds == 1)


// Are households switching in and out of bonds simply switching in and out of participation?
gen switcher_bond = (hasbonds != L.hasbonds)
gen switcher_stock = (hasstocks != L.hasstocks)

// Do households leaving stocks tend to switch to bonds?

// Share of leavers which owned stocks, owned bonds, owned both

gen leave_stocks = (L.hasstocks == 1) & (L.hasbonds == 0) if (participant == 0) & (L.participant == 1)
gen leave_bonds = (L.hasbonds == 1) & (L.hasstocks == 0) if (participant == 0) & (L.participant == 1)
gen leave_both = (L.hasstocks == 1) & (L.hasbonds == 1) if (participant == 0) & (L.participant == 1)

#delimit ;
collapse (mean) leave_stocks (mean) leave_bonds (mean) leave_both [aw=wgt] if (networth >= 100000) & (year == 2009) & (fliquid > 10000);
#delimit cr

// Transition matrix


// Bond turnover vs stock turnover
// How much of turnover is total turnover?
// Look at switching between bonds and stocks? From one-only to both?

// For 07-08, decline in bond ownership could come from fall in interest rates...
// Rise in home purchasing

// Bond premium is household-specific? Low/high values?
// Stock return belief also?
// Could simply use idiosyncratic shock to stock return belief...


// Bondholder turnover for non-stockholders cannot be explained by beliefs, but can be explained by
// low bond premium...

// Become sophisticated temporarily or permanently?
// Allow random ability to gamble

// LARGE PURCHASES!!!
// HOW MUCH OF TRANSITIONS ARE EXPLAINED BY LARGE PURCHASES?

#delimit ;
collapse (mean) hasstocks (mean) stentry (mean) stexit
	(mean) stonly2safe
	(mean) hasbonds (mean) bondentry (mean) bondexit
	(mean) bond2st (mean) bondonly2nothing
	(mean) participant (mean) sophentry (mean) sophexit
	 (mean) part_stexit (mean) part_bondexit
	[aw=wgt] if (networth >= 100000) & (year == 2009) & (fliquid > 10000);
#delimit cr

#delimit ;
collapse (mean) hasstocks (mean) hasbonds (mean) participant [aw=wgt], by(year);
#delimit cr

gen hbboth = (hasbonds == 1) & (L.hasbonds == 1)
gen hsboth = (hasstocks == 1) & (L.hasstocks == 1)
gen hpboth = (participant == 1) & (L.participant == 1)

#delimit ;
collapse (mean) hbboth (mean) hsboth (mean) hpboth [aw=wgt]
	if (year == 2009);
#delimit cr
