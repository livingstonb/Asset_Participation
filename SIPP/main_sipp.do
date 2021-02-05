clear

// PARSE COMMANDS
syntax [anything(name=commands)]

if "`commands'" == "" {
	local build = 1
	local stats = 1
}
else {
	local build = strpos("`commands'", "build") > 0
	local stats = strpos("`commands'", "stats") > 0
}

// BUILD
if `build' {
	clear all
	capture mkdir "build/temp"
	capture mkdir "build/output"

	* Combine waves
	do "build/code/combine_waves.do"

	* Clean monthly data
	do "build/code/clean_monthly.do"

	* Aggregate to annual
	local lvls person fam hh
	foreach lvl of local lvls {
		do "build/code/aggregate2annual.do" `lvl'
	}
}

// STATS
if `stats' {
	clear
	capture mkdir "stats/output"

	local digits 3 5
	local lvls person fam hh

	foreach digit of local digits {
	foreach lvl of local lvls {
		do "stats/code/collapse_by_occupation.do" `lvl' `digit'
	}
	}
}
