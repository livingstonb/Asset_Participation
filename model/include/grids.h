#ifndef GRIDS_HEADER
#define GRIDS_HEADER

#include<vector>

class Parameters;

class Grids {
	public:
		Grids();

		void create_income_dist();

		void create_saving_grids();

		void create_returns_dist();

		void create_pref_dist();

		int n_sf = 100;
		int n_se = 100;
		int n_re = 5;
		int nyP = 2;
		int nyT = 1;
		int np = 1;

		int nx = 100;
		double xmax = 200;
		double curv = 0.2;
		double ymin;

		std::vector<double> x, se, sf, Re, Re_dist, yP, yP_dist, y_dist;

		std::vector<double> yT, yT_dist, y, lpref, lpref_dist, yP_trans;
};

#endif