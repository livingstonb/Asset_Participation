use build/output/SCF_89_19_cleaned.dta, clear

keep if inrange(age, 25, 55)
keep if inlist(year, 2016, 2019)

local byvariables x_labinc_quantile

foreach var of local byvariables {
	if "`var'" == "x_labinc_quantile" {
		local description "by earnings quintile"
		local fsuffix "earnings_quintile"
	}
	else if "`var'" == "budgeting_horizon" {
		local description "by budgeting horizon"
		local fsuffix "budget_horizon"
	}
	else if "`var'" == "x_networth_quantile" {
		local description "by net worth quintile"
		local fsuffix "net_worth_quintile"
	}

	#delimit ;
	graph bar (median) x_leverage (p75) midhighl=x_leverage (p90) highl=x_leverage [fw=fwgt] if (x_stocks > 0) & (x_labinc_quantile >= 3), over(`var')
		graphregion(color(white))
		ytitle("L")
		title("Median leverage `description'");
	#delimit cr
// 	graph export stats/output/figures/nostock_`fsuffix'.png, replace
// 	graph export stats/output/figures/current.png, replace
}

drop leverage
gen leverage = asset / networth if (networth > 0)
replace leverage = . if leverage > 20
tabstat x_risk_share [fw=fwgt] if (x_networth_quantile < 3), by(has_stocks) statistics(p10 p25 p50 p75 p90 variance)


* High leverage ratios are associated with low earnings
gen x_risk_leverage = x_risky / networthnc if networthnc > 0

keep if inrange(age, 25, 200) & !((anticipates_expenses == 1) & (saving_for_expense==1))
gen leverage = asset / networth if (networth > 0)
collapse (median) leverage (median) x_risk_share [fw=fwgt], by(age has_stocks)

local scatvar leverage
twoway (scatter `scatvar' age if has_stocks) (scatter `scatvar' age if !has_stocks), legend(label(1 "Stock owners") label(2 no stock))
