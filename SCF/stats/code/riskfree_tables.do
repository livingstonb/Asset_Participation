// use "../output/savrate.dta", clear
//
// gen year = year(dofq(period))
// collapse (mean) savrate, by(year)
//
// tempfile fsavrate
// save `fsavrate'

use "build/output/SCF_89_19_cleaned", clear
gen implic = Y1 - 10 * YY1
keep if implic == 1
keep if networth > 0
keep if inrange(age, 20, 64)

gen hasbonds = gbmutf + notxbnd + govtbnd > 0 
gen hasmma = mma > 0
gen hascds = cds > 0
gen hasany = gbmutf + notxbnd + govtbnd + mma + cds > 0

collapse hasbonds hasmma hascds hasany [fw=fwgt], by(year)

// merge 1:1 year using `fsavrate', nogen keep(1 3)
