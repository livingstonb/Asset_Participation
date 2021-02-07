#ifndef PARAMETERS_HEADER
#define PARAMETERS_HEADER

class Parameters {
	public:
		int T = 10;

		// Coeff of relative risk aversion
		double gam = 1.1;

		// Liquidity preference coeffs
		double phi1 = 0.2;
		double phi2 = 0.5;

		double beta = 0.98;
		double sgridcurv = 0.2;

		double Rb = 1.005;

};

#endif