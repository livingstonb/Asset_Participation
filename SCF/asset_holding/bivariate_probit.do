use "build/output/SCF_89_19_cleaned", clear

local threshold 0

keep if networth > 0
keep if netlabinc > 0
keep if inrange(age, 20, 64)

gen lwealth = log(networth)
gen learnings = log(netlabinc)
gen hasbonds1 = gbmutf + notxbnd + govtbnd > `threshold'
gen hasbonds2 = gbmutf + notxbnd + govtbnd + mma + cds > `threshold'
gen sqage = age ^ 2
gen implic = Y1 - 10 * YY1
keep if implic == 1

gen yr1989 = year - 1989
gen hasstocks = stocks + stmutf > `threshold'
gen finliter = finlit1 + finlit2 + finlit3
gen badcredit = (turndown == 1) | (turnfear == 1)

label variable hasstocks "Stocks"
label variable hasbonds1 "Bond-like"
label variable hasbonds2 "Bonds"
label variable age "Age"
label variable sqage "Age-squared"
label variable lwealth "Log wealth"
label variable learnings "Log earnings"
label variable educ "Education"
label variable yr1989 "Years after 1989"
label variable married "Married"
label variable homeowner "Homeowner"
label variable finrisktol "Risk tol"
label variable kids "Children"
label variable budgeting_horizon "Planning Horiz"
label variable badcredit "Denied credit"
label variable is_saving "Is saving"
label variable hbus "Owns business"

replace finrisktol = 5 - finrisktol

drop if (budgeting_horizon == -1) | (educ == -1)

#delimit ;
biprobit hasstocks hasbonds2
	lwealth learnings educ yr1989 age sqage b0.married b0.homeowner finrisktol
	kids budgeting_horizon b0.badcredit b0.is_saving b0.hbus, vce(robust);
#delimit cr


// Predicted marginal probabilities
predict biprob1, pmarg1
predict biprob2, pmarg2

// Predicted joint probabilities
predict biprob00, p00
predict biprob01, p01
predict biprob10, p10
predict biprob11, p11

// Summarize predicted values
sum hasstocks hasbonds2
sum biprob1 biprob2
sum biprob00 biprob01 biprob10 biprob11

// Marginal effects
margins, dydx(*) predict(p00)
margins, dydx(*) predict(p01)
margins, dydx(*) predict(p10)
margins, dydx(age) predict(p10) predict(p01) predict(p11)

margins educ

// Change education variable

// Use committed consumption

// Parent variables
X6032 X6132
X6033 X6133

// NOTE: Some estimates are only significant in predicting ownership of both!
// Avg treatment effect? ATE

// ARGUMENT FOR MODEL DEPENDENCE:
// Households aware of one market more likely to be aware of the other

// Marginal effect of finrisktol?


// Selection of positive wealth? Or liquidity?

// Pension wealth??
// LTV ratio??
// Income / Debt? Leverage interacted with homeownership?
// Exclude retired
// Ratio of liquid assets to income?
// Committed consumption
// Emergency funds? Access to family, etc.?
// Assets in addition to net worth?
// Total income instead of earnings?
// Retirement account?
// Full time? X4512 is full time tenure
// Also do conditional on being liquid?
// Do conditional on working full time--These households face consumption-savings problem

// STOCK OPTIONS GIVEN BY FIRM
X6797
X6798
gen recdstockoptions = 1 if (X6797 == 1) | (X6798 == 1)

 IF (10 <= 4-digit occ. code <=200) THEN occ. code=1;
                IF (220 <= 4-digit occ. code <=1530) THEN occ. code=1;
                IF (1600 <= 4-digit occ. code <=1860) THEN occ. code=1;
                IF (2000 <= 4-digit occ. code <=3650) THEN occ. code=1;
                ELSE IF (1540 <= 4-digit occ. code <=1560) THEN occ. code=2;
                ELSE IF (4700 <= 4-digit occ. code <=5930) THEN occ. code=2;
                ELSE IF (1900 <= 4-digit occ. code <=1960) THEN occ. code=2;
                ELSE IF (7900 <= 4-digit occ. code <=7900) THEN occ. code=2;
                ELSE IF (3700 <= 4-digit occ. code <=4320) THEN occ. code=3;
                ELSE IF (4400 <= 4-digit occ. code <=4400) THEN occ. code=3;
                ELSE IF (4420 <= 4-digit occ. code <=4650) THEN occ. code=3;
                ELSE IF (9800 <= 4-digit occ. code <=9840) THEN occ. code=3;
                ELSE IF (6200 <= 4-digit occ. code <=7850) THEN occ. code=4;
                ELSE IF (8330 <= 4-digit occ. code <=8330) THEN occ. code=4;
                ELSE IF (8350 <= 4-digit occ. code <=8350) THEN occ. code=4;
                ELSE IF (8440 <= 4-digit occ. code <=8630) THEN occ. code=4;
                ELSE IF (8740 <= 4-digit occ. code <=8760) THEN occ. code=4;
                ELSE IF (8810 <= 4-digit occ. code <=8810) THEN occ. code=4;
                ELSE IF (4410 <= 4-digit occ. code <=4410) THEN occ. code=5;
                ELSE IF (7920 <= 4-digit occ. code <=8320) THEN occ. code=5;
                ELSE IF (8340 <= 4-digit occ. code <=8340) THEN occ. code=5;
                ELSE IF (8360 <= 4-digit occ. code <=8430) THEN occ. code=5;
                ELSE IF (8640 <= 4-digit occ. code <=8730) THEN occ. code=5;
                ELSE IF (8800 <= 4-digit occ. code <=8800) THEN occ. code=5;
                ELSE IF (8830 <= 4-digit occ. code <=9750) THEN occ. code=5;
                ELSE IF (210 <= 4-digit occ. code <=210) THEN occ. code=6;
                ELSE IF (4340 <= 4-digit occ. code <=4350) THEN occ. code=6;
                ELSE IF (6000 <= 4-digit occ. code <=6130) THEN occ. code=6;

