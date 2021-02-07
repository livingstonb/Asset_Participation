#ifndef GRIDS_HEADER
#define GRIDS_HEADER

#include<vector>

class Grids {
	public:
		template<typename P>
		Grids(const P& p);

		void create_saving_grids();

		void create_returns_dist();

		void create_income_dist();

		void create_pref_dist();

		int n_sf, n_se, n_re, nyP, nyT, np;

		double xmax, curv;

		std::vector<double> se, sf, Re, Re_dist, yP, yP_dist, y_dist;

		std::vector<double> yT, yT_dist, y, lpref, lpref_dist, yP_trans;
};

template<typename P>
Grids::Grids(const P& p)
{
	n_sf = p.n_sf;
	n_se = p.n_se;
	n_re = p.n_re;
	curv = p.sgridcurv;
	nyP = p.nyP;
	nyT = p.nyT;
	np = p.np;
	xmax = p.xmax;

	create_saving_grids();

	create_returns_dist();

	create_income_dist();

	create_pref_dist();
}

#endif