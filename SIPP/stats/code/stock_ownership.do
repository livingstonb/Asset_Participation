*** Read ***
use "build/output/annual_hh.dta", clear

gen istocks = val_st + val_mf
gen ihas_stocks = (istocks > 0) if !missing(istocks)

bysort ssuid swave: egen stocks = total(istocks), missing
bysort ssuid swave: egen has_stocks = total(ihas_stocks), missing
duplicates drop ssuid swave, force

tsset ssuid swave
by ssuid: egen yrstocks = total(has_stocks)
by ssuid: egen nyrs = count(has_stocks)
gen always_in = (yrstocks == nyrs)

gen entered = (L.has_stocks == 0) & (has_stocks == 1)
gen exited = (L.has_stocks == 1) & (has_stocks == 0)

*** Collapse to 2-year
gen tperiod = 1 if swave == 1
replace tperiod = 2 if (swave == 4)
drop if missing(tperiod)

keep if inrange(tage, 25, 55)
collapse (max) has_stocks (sum) swgts, by(tperiod ssuid)

tsset ssuid tperiod
gen entered = (L.has_stocks == 0) & (has_stocks == 1) if !missing(has_stocks, L.has_stocks)
gen exited = (L.has_stocks == 1) & (has_stocks == 0) if !missing(has_stocks, L.has_stocks)


collapse (mean) has_stocks entered exited [aw=swgts], by(tperiod)
br
