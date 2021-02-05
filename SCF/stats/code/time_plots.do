
use "build/output/SCF_89_19_cleaned", clear
keep if inrange(age, 20, 80)

local threshold 0

keep if networth > 0 & !missing(networth)
keep if netlabinc > 0 & !missing(netlabinc)

gen hasbonds1 = gbmutf + notxbnd + govtbnd > `threshold'
gen hasbonds2 = gbmutf + notxbnd + govtbnd + mma + cds > `threshold'
gen implic = Y1 - 10 * YY1
keep if implic == 1

gen hasstocks = stocks + stmutf > `threshold'

gen participant = (hasbonds2 == 1) | (hasstocks == 1) if !missing(hasbonds2, hasstocks)

// By age, bond and stock ownership
collapse (mean) hasbonds2 (mean) hasstocks (mean) participant [fw=fwgt], by(age)

local scatopts , msize(small)

#delimit ;
twoway (scatter hasbonds2 age `scatopts') (scatter hasstocks age `scatopts')
	(scatter participant age `scatopts'),
	legend(label(1 "Bonds") label(2 "Stocks") label (3 "Either")
	region(color(white)) rows(1))
	graphregion(color(white)) xtitle("Age") ytitle("Participation")
	bgcolor(white) ylab(0.1(0.1)0.5, nogrid)
	xlab(20(10)80);
#delimit cr

graph export "stats/output/participation_by_age.png", replace

// Conditional on sufficient liquidity
gen nonretirfinwealth = liq + cds + nmmf + savbnd + stocks + bond
gen htm = nonretirfinwealth < netlabinc / 12 if (netlabinc > 0) & !missing(netlabinc)

#delimit ;
collapse (mean) hasbonds2 (mean) hasstocks (mean) participant if (htm == 0)
	[fw=fwgt], by(age);
#delimit cr

local scatopts , msize(small)

#delimit ;
twoway (scatter hasbonds2 age `scatopts') (scatter hasstocks age `scatopts')
	(scatter participant age `scatopts'),
	legend(label(1 "Bonds") label(2 "Stocks") label (3 "Either")
	region(color(white)) rows(1))
	graphregion(color(white)) xtitle("Age") ytitle("Participation")
	bgcolor(white) ylab(0.1(0.1)0.5, nogrid)
	xlab(20(10)80);
#delimit cr

graph export "stats/output/participation_by_age_nhtm.png", replace

// twoway 


// By education


// twoway scatter hasbonds2 learnings