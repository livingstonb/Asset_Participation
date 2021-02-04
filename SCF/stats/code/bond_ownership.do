use build/output/SCF_89_19_cleaned.dta, clear

* Total liquid assets
gen safeliq = liq + cds + nmmf + savbnd + stocks + bond

* Bond ownership variables
gen cashlike = saving + checking
label variable cashlike "Bank deposits only"

gen bondslike1 = gbmutf + savbnd + notxbnd + govtbnd
label variable bondslike1 "Government bonds only"

gen has_bonds1 = bondslike1 > 0
label variable has_bonds1 "Has government bonds"

gen bondslike2 = bondslike1 + mma
label variable bondslike2 "Government bonds and other safe non-cash assets"

gen has_bonds2 = bondslike2 > 0
label variable has_bonds2 "Has non-cash safe assets"

* Stock ownership
gen has_stocks = stocks + stmutf > 0

* Combinations
gen has_both = (has_stocks == 1) & (has_bonds1 == 1)

gen has_st_no_bonds = (has_stocks == 1) & (has_bonds1 == 0)

gen has_bd_no_st = (has_stocks == 0) & (has_bonds1 == 1)

* Correlation
// local bondvar safenoncash1
//
// gen has_bonds = `bondvar' > 0 if !missing(`bondvar')
// corr has_stocks has_bonds if safeliq > 0 [fw=fwgt]
// corr has_bonds if safeliq > 0 [fw=fwgt]
// drop has_bonds

* Annual stats
collapse has_both has_stocks has_bonds1 has_bonds2 has_st_no_bonds has_bd_no_st if liq > 500 [fw=fwgt], by(year)
