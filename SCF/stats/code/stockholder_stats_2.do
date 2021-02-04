use build/output/SCF_89_19_cleaned.dta, clear
keep if inrange(age, 25, 55)

do stats/code/gen_portfolio_variables.do


tabstat has_stocks has_rf has_noncash_rf [fw=fwgt], by(year) statistics(mean)

gen lwealth = log(networth) if networth > 100 
gen has_install = install > 0
reg has_stocks educ age has_noncash_rf lwealth c.has_noncash_rf#c.lwealth homeowner finrisktol spendmorey, robust

* Poor households who own bonds are less likely to hold stock
* while wealthy households who own bonds are MORE likely to hold stock
* --> Just because wealthy households likely to know about both?
* --> Or can we identify what's going on with a panel?
* --> Participation costs greater for stock?
* --> Maybe beliefs are playing a role and poor households get bad information?
* Can we use portfolio allocations to infer beliefs rather than using them
* to calibrate preferences?
