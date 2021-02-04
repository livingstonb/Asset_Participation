use build/output/SCF_89_19_cleaned.dta, clear

keep if inrange(age, 25, 55)
keep if inlist(year, 2016, 2019)
// keep if (x_labinc_quantile == 5)

gen white = (race == 1)
gen lincome = log(labinc) if labinc > 10000
probit has_stocks educyears finlit age white lincome married, vce(robust)






gen retir_value = retirself_value + retirsp_value + retirfam_value
gen retir_stocks = retirself_stocks + retirsp_stocks + retirfam_stocks


gen has_home = houses > 0
collapse (mean) has_stocks has_home [fw=fwgt], by(year)

scatter has_stocks year




sum trusts [fw=fwgt], detail

xtile x_networth_quantile = networthnc [fw=fwgt], nquantiles(5)
keep if (x_networth_quantile == 5)

collapse (median) maxirate [fw=fwgt], by(has_stocks)

gen has_house = houses > 0 & !missing(houses)
collapse has_stocks [fw=fwgt], by(married)
