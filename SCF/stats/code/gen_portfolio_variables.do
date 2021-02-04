
// STOCKS
gen x_stocks = stmutf + comutf + stocks
gen x_liquid = liq + x_stocks + bond + (nmmf - stmutf - comutf)
gen x_safe = liq + bond + cds + (nmmf - stmutf - comutf) + savbnd + bond
gen x_risky = x_stocks + nfin + retqliq
replace x_risky = x_risky - vehic if (nfin - vehic) > 0
gen x_total = x_safe + x_risky

gen x_risk_share = x_risky / x_total if (x_total > 0)
gen x_safe_share = x_safe / x_total if (x_total > 0)
gen x_risk_share_of_liquid = x_risky / x_liquid if (x_liquid > 0)
gen x_liquid_share = x_liquid / x_total if x_total > 0
gen x_stock_share = x_stocks / x_total if x_total > 0
gen x_stock_share_of_liquid  = x_stocks / x_liquid if (x_liquid > 0)
gen x_stock_share_of_risky = x_stocks / x_risky if x_risky > 0
gen x_leverage = x_total / networthnc if networthnc > 1000
gen x_riskleverage = x_risky / networthnc if networthnc > 1000
gen sleverage = asset / networth if networth > 0

label define xbh_lbl 1 "Few months" 2 "One Year" 3 "Few years" 4 "5-10 years" 5 ">10 years"
label values budgeting_horizon xbh_lbl

// gen x_labinc_quantile = .
// gen x_networth_quantile = .
// levelsof year, local(yrs)
// foreach yr of local yrs {
// 	xtile temp1 = labinc [fw=fwgt] if (year == `yr'), nquantiles(5)
// 	xtile temp2 = networthnc [fw=fwgt] if (year == `yr'), nquantiles(5)
// 	replace x_labinc_quantile = temp1 if (year == `yr')
// 	replace x_networth_quantile = temp2 if (year == `yr')
// 	drop temp1 temp2
// }

// label variable x_labinc_quantile "Labor income quantile"
// label define xlabincqlbl 1 "Bottom" 5 "Top"
// label values x_labinc_quantile xlabincqlbl
//
// label define xnwqlbl 1 "Bottom" 5 "Top"
// label values x_networth_quantile xnwqlbl

gen has_stocks = (x_stocks > 0)

// BONDS
gen allbonds = tfbmutf + gbmutf + obmutf + savbnd + bond
gen rf_all = liq + cds + allbonds
gen rf_noncash = mma + call + prepaid + cds + allbonds
gen has_rf = rf_all > 0
gen has_noncash_rf = rf_noncash > 0
