use build/output/SCF_89_19_cleaned.dta, clear

keep if inrange(age, 25, 65)
keep if inlist(year, 2013, 2016, 2019)

drop x_labinc_quantile
gen x_labinc_quantile = .
forvalues yr = 2013(3)2019 {
	xtile xtemp=labinc [fw=fwgt] if year == `yr', nquantiles(5)
	replace x_labinc_quantile = xtemp if year == `yr'
	drop xtemp
}
keep if x_labinc_quantile == 5

// collapse (mean) x_risk_share [fw=fwgt], by(age has_stocks)

gen leverage = asset / networth if networth > 1000
collapse (median) leverage [fw=fwgt], by(age has_stocks)
sort has_stocks age

twoway (scatter leverage age if !has_stocks) (scatter leverage age if has_stocks), legend(label(1 "No stocks") label(2 "Has stocks"))

* Capital adequacy ratio = risk-weighted assets / capital
