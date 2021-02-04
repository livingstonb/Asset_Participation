

use build/output/SCF_89_19_cleaned.dta, clear

keep if inrange(age, 30, 40)
keep if inlist(year, 2016, 2019)
gen fwgt = round(wgt)
gen x_not_constrained = (x_liquid >= labinc * 3 / 12) & !missing(labinc, x_liquid)
gen x_budgeting_horizon = budgeting_horizon
label define xbh_lbl 1 "Few months" 2 "One Year" 3 "Few years" 4 "5-10 years" 5 ">10 years"
label values x_budgeting_horizon xbh_lbl

* Quantiles of labor income
xtile x_labinc_quantile = labinc [fw=fwgt], nquantiles(5)
label variable x_labinc_quantile "Labor income quantile"

xtile x_networth_quantile = networthnc [fw=fwgt], nquantiles(5)

************************************************
* Check dependence of stock exposure on income


* Appears to be a boundary condition where people choose no stock exposure
* Does this vary by demographics or education?
* What role does stock aversion have on the distribution of wealth? On HtM behavior?
* Need a risky asset and a safe asset

// #delimit ;
// histogram x_stockexp [fw=fwgt] if x_liquid > 10000, fraction
// 	graphregion(color(white));
// #delimit cr
// gen x_cond_stockexp = (x_stockexp > 0) & !missing(x_stockexp)

* STOCK AVERSE HOUSEHOLDS BY VARIABLE
gen stock_averse = (x_stocks == 0) if !missing(x_stocks)
label variable stock_averse "Stock averse"

count if !missing(stock_averse)

local byvariables x_labinc_quantile x_budgeting_horizon x_networth_quantile

foreach var of local byvariables {
	if "`var'" == "x_labinc_quantile" {
		local description "by earnings quintile"
		local fsuffix "earnings_quintile"
	}
	else if "`var'" == "x_budgeting_horizon" {
		local description "by budgeting horizon"
		local fsuffix "budget_horizon"
	}
	else if "`var'" == "x_networth_quantile" {
		local description "by net worth quintile"
		local fsuffix "net_worth_quintile"
	}

	#delimit ;
	graph bar (mean) stock_averse [fw=fwgt], over(`var')
		graphregion(color(white))
		ytitle("Share of no-stock households")
		title("No-stock households, `description'");
	#delimit cr
	graph export stats/output/figures/nostock_`fsuffix'.png, replace
}

* RISK SHARES
gen x_risk_share = x_risky / x_total if (x_total > 1000)
gen x_safe_share = x_safe / x_total if (x_total > 0)
gen x_stockexp = x_stocks / x_liquid
gen x_liquid_share = x_liquid / x_total if x_total > 1000
gen x_stock_share = x_stocks / x_total if x_total > 1000
gen x_leverage = x_total / networthnc

#delimit ;
histogram x_risk_share [fw=fwgt] if x_stock_share > 0.2,
	graphregion(color(white));
#delimit cr

* LIQUID SHARES


#delimit ;
histogram x_liquid_share [fw=fwgt] if x_stock_share > 0.5,
	graphregion(color(white));
#delimit cr

* Are households with stock less likely to be overburdened by liquid assets?
* Indeed, households with stock exposure are less likely to wind up on the
* extremes of the distribution of (liquid / total) -> hypothesis being that they
* can more easily adjust their exposure to risky assets
* Why would lack of a liquid risky asset push household to boundary conditions?
gen x_liquid_stock_share = x_stocks / x_liquid if x_total > 0
#delimit ;
histogram x_liquid_stock_share [fw=fwgt],
	graphregion(color(white));
#delimit cr

#delimit ;
histogram x_liquid_share [fw=fwgt] if x_stock_share > 0,
	graphregion(color(white));
#delimit cr

* LEVERAGE
* EXCESS SAFETY AMONG LIQUID HH's
use build/output/SCF_89_19_cleaned.dta, clear

keep if inrange(age, 30, 40)
keep if inlist(year, 2016, 2019)
gen fwgt = round(wgt)
gen x_not_constrained = (x_liquid >= labinc * 3 / 12) & !missing(labinc, x_liquid)
gen x_budgeting_horizon = budgeting_horizon
label define xbh_lbl 1 "Few months" 2 "One Year" 3 "Few years" 4 "5-10 years" 5 ">10 years"
label values x_budgeting_horizon xbh_lbl

gen x_risk_share = x_risky / x_total if (x_total > 1000)
gen x_safe_share = x_safe / x_total if (x_total > 0)
gen x_stockexp = x_stocks / x_liquid
gen x_liquid_share = x_liquid / x_total if x_total > 1000
gen x_stock_share = x_stocks / x_total if x_total > 1000
gen x_leverage = x_total / networth

gen is_liquid = x_liquid > (labinc / 24) if labinc > 10000 & !missing(labinc)
gen excess_safety = (x_safe_share > 0.5) & !missing(x_safe_share)

// gen is_htm = x_liquid <= (labinc / 12) if labinc > 10000 & !missing(labinc)
// gen is_whtm = is_htm & (networthnc - x_liquid > 0)

gen h2m = netbrliq >=0 & (netbrliq <= labinc / (12 * 4))
gen wh2m = (h2m == 1) & (netbrilliqnc > 0)
gen wh2m2 = (h2m == 1) & (netbrilliqnc > labinc / 12)

gen has_stocks = (x_stocks > 0)

// collapse (sum) wh2m [fw=fwgt], by(has_stocks)
// local var = wh2m[2] / (wh2m[1] + wh2m[2])
// di "`var'"

* Renters vs homeowners
gen homeowner = (houses > 0) & !missing(houses)

gen stock_cat = 0 if (x_stocks == 0)
gen stock_cat = 1 if inrange(x_stock_share, 0.1, 0.5)
bysort has_stocks: sum x_leverage [fw=fwgt] if (finlit == 3) & (networthnc > 0), detail

gen byratio = netbrliq / labinc if (labinc > 1000)
tabstat x_leverage [fw=fwgt] if (networthnc > 0) & (x_leverage < 50) & (x_labinc_quantile == 5), by(has_stocks) statistics(mean median variance)

sum excess_safety [fw=fwgt] if (x_stocks == 0) & is_liquid, detail
sum excess_safety [fw=fwgt] if (x_stocks > 0) & is_liquid, detail

* WHO ARE THE STOCK-AVERSE HOUSEHOLDS?
gen stock_averse = (x_stockexp == 0) if !missing(x_stockexp) & x_not_constrained

#delimit ;
graph bar (mean) stock_averse [fw=fwgt], over(`byvariable')
	ytitle("Share of stock averse households")
	title("Stock aversion");
#delimit cr



