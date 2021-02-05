

use "build/output/SCF_89_19_cleaned", clear
keep if inrange(age, 20, 64)

local threshold 0

// keep if networth > 0 & !missing(networth)
// keep if netlabinc > 0 & !missing(netlabinc)

gen hasbonds1 = gbmutf + notxbnd + govtbnd > `threshold'
gen hasbonds2 = gbmutf + notxbnd + govtbnd + mma + cds > `threshold'
gen nonretirfinwealth = liq + cds + nmmf + savbnd + stocks + bond + stmutf
gen implic = Y1 - 10 * YY1
keep if implic == 1

gen hasstocks = stocks + stmutf > `threshold'

gen participant = (hasbonds2 == 1) | (hasstocks == 1) if !missing(hasbonds2, hasstocks)

// Equity share of liquid assets
gen equity_share = (stocks + stmutf) / nonretirfinwealth

replace equity_share = . if (equity_share > 0) & (equity_share < 0.05)

#delimit ;
histogram equity_share [fw=fwgt] if (participant == 1),
	width(0.05) start(0) fraction xtitle("Equity Share of Liquid Wealth, All Participants")
	graphregion(color(white)) bgcolor(white) color(none) fcolor(gs5) barwidth(0.04);
#delimit cr

graph export "stats/output/condl_equity_share_liq.png", replace

// Equity share of total financial assets
cap drop equity_share
gen equity_share = (stocks + stmutf) / fin

replace equity_share = . if (equity_share > 0) & (equity_share < 0.05)

#delimit ;
histogram equity_share [fw=fwgt] if (participant == 1),
	width(0.05) start(0) fraction xtitle("Equity Share of Financial Wealth, All Participants")
	graphregion(color(white)) bgcolor(white) color(none) fcolor(gs5) barwidth(0.04);
#delimit cr

graph export "stats/output/condl_equity_share_totfin.png", replace
