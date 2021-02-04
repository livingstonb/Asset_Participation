#include <bellman.h>
#include <eigen_interface.h>
#include <interpolation.h>
#include <parameters.h>
#include <grids.h>

class BellmanImpl {
	public:
		BellmanImpl() {}

		Income income;

		Grids grids;

		RMatrix EV, V;
};

Bellman::Bellman()
{
	p.reset(new Parameters());
	impl.reset(new BellmanImpl());
}

void Bellman::update_EV()
{
	// Computes continuation value as a function of sf, se, y.
	//
	// sf : Amount invested in safe assets, after interest
	// se : Amount invested in equity, before return

	double sf, se, xp;
	int n_sf, n_se, n_re, n_y;
	n_sf = p->n_sf;
	n_se = p->n_se;
	n_re = p->n_re;
	n_y = p->n_y;

	RMatrix& evref = impl->EV;
	evref = RMatrix::Zero(n_sf * n_se, n_y);

	const Grids& grids = impl->grids;
	const Income& income = impl->income;

	// Compute V' by interpolation
	double vp[n_y];
	for (int isf=0; isf<n_sf; ++isf) {
		sf = grids.sf[isf];
		for (int ise=0; ise<n_se; ++ise) {
			se = grids.se[ise];
			for (int iy=0; iy<n_y; ++iy) {
				// Expectation of next period's value wrt returns process
				vp[iy] = 0;
				for (int ie=0; ie<n_re; ++ie) {
					// Next period's cash-on-hand
					xp = sf + se * grids.returns[ie] + income.values[iy];
					vp[iy] += grids.preturns[ie]
						* linterp1(V.col(iy), grids.x, xp);
				}
			}

			// Take expectation over income
			for (int iy=0; iy<n_y; ++iy) {
				evref(isf + n_sf * ise, iy) = 0;
				for (int iy2=0; iy2<n_y; ++iy2) {
					evref(isf + n_sf * ise, iy)
						+= income.ytrans(iy,iy2) * vp[iy2];
				}
			}
		}
	}
	evref *= p->beta;
}

double Bellman::continuation_value(double sf, double se, int k) const
{
	// Interpolates EV
	return linterp2(
		impl->EV.col(k), impl->grids.sf, impl->grids.se, sf, se);
}
