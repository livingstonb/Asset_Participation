#include <bellman.h>
#include <eigen_interface.h>
#include <boost_includes.h>
#include <interpolation.h>
#include <parameters.h>
#include <grids.h>
#include <functions.h>

class BellmanImpl {
	public:
		BellmanImpl(const Parameters& p)
			: V(boost::extents[p.nx][p.nyP][p.np]),
				EV(boost::extents[p.n_sf][p.n_se][p.nyP]) {}

		Income income;

		Grids grids;

		arr3d V, EV;
};

Bellman::Bellman()
{
	p.reset(new Parameters());
	impl.reset(new BellmanImpl(*p));
}

void Bellman::terminal_value()
{
	for (int ix=0; ix<p->nx; ++ix) {
		for (int iyP=0; iyP<p->nyP; ++iyP) {
			for (int ip=0; ip<p->np; ++ip) {
				impl->V[ix][iyP][ip] = pow(impl->grids.x[ix], 1.0 - p->gam);
			}
		}
	}
}

void Bellman::update_EV()
{
	// Computes continuation value as a function of sf, se, y.
	//
	// sf : Amount invested in safe assets, after interest
	// se : Amount invested in equity, before return

	double sf, se, xp;
	int n_sf, n_se, n_re, nyP, np;
	n_sf = p->n_sf;
	n_se = p->n_se;
	n_re = p->n_re;
	nyP = p->nyP;
	np = p->np;

	arr3d& evref = impl->EV;

	const Grids& grids = impl->grids;
	const Income& income = impl->income;

	boost::array<arr3d::index, 3> shape = {{ p->nx, ny, np }};

	// Compute V' by interpolation
	double vp[n_y];
	for (int isf=0; isf<n_sf; ++isf) {
		sf = grids.sf[isf];
		for (int ise=0; ise<n_se; ++ise) {
			se = grids.se[ise];
			for (int iyP=0; iy<nyP; ++iyP) {
				// Expectation of next period's value wrt returns process
				// and preference state
				vp[iyP] = 0;
				for (int ip=0; ip<np; ++ip) {
					arr3d::view<1> values =
						impl->V[ boost::indices[range()][iyP][ip] ];
					for (int ie=0; ie<n_re; ++ie) {
						for (int iyT=0; iyT<nyT; ++iyT) {
							// Next period's cash-on-hand
							xp = sf + se * grids.Re[ie] + grids.y(iyP, iyT);
							vp[iyP] += grids.lpref_dist[ip] * grids.Re_dist[ie]
								* linterp1(grids.x, values, p->nx, xp);
						}
					}
				}
			}

			// Take expectation over income
			for (int iyP=0; iyP<nyP; ++iyP) {
				evref[isf][ise][iyP] = 0.0;
				for (int iyP2=0; iyP2<nyP; ++iyP2) {
					evref[isf][ise][iyP] += income.yP_trans(iyP, iyP2) * vp[iyP2];
				}
				evref[isf][ise][iyP] *= p->beta;
			}
		}
	}
}

double Bellman::continuation_value(double sf, double se, int k) const
{
	// Interpolates EV
	arr3d::view<2> values = impl->EV[ boost::indices[range()][range()][iyP] ];
	return linterp2(impl->grids.sf, impl->grids.se, values,
		p->n_sf, p->n_se, sf, se);
}
