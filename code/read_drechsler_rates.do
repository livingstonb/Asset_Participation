import delimited "input/drechsler_rates.csv", clear
rename *date strdate

gen date = date(strdate, "MDY")
format %td date

gen quarter = quarter(date)
gen year = year(date)

gen period = yq(year, quarter)
format %tq period

drop date strdate

collapse saving fedfunds, by(period)

merge 1:1 period using "output/call_reports.dta", nogen
replace ratewatch_rate = ratewatch_rate * 100

keep if year(dofq(period)) >= 1987

gen year = year(dofq(period))

tsset period

reg saving ratewatch_rate L.ratewatch_rate year if year >= 2010
predict fitted, xb
replace saving = fitted if missing(saving)
rename saving savrate
drop fitted

gen depspread = fedfunds - savrate

keep period savrate fedfunds depspread

save "output/savrate.dta", replace