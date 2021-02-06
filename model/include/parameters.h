#ifndef PARAMETERS_HEADER
#define PARAMETERS_HEADER

class Parameters {
	public:
		int nx = 50;
		int n_sf = 50;
		int n_se = 50;
		int n_re = 5;
		int np = 1;
		int nyP = 5;
		int nyT = 1;
		int T = 10;

		// Coeff of relative risk aversion
		double gam = 1.0;

		// Liquidity preference coeffs
		double phi1 = 0.2;
		double phi2 = 0.5;

		double beta = 0.95;
		double xmax = 200.0;
		double sgridcurv = 0.2;

		double Rb = 1.005;

};

#endif