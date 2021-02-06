#include <bellman.h>
#include <eigen_interface.h>
#include <boost_includes.h>
#include <interpolation.h>
#include <parameters.h>
#include <grids.h>
#include <functions.h>

namespace {
	struct ObjArgs {
		double x, gam, phi1, phi2, Rb, beta;

		arr3d::view<2> evalues;

		const RVector& sfgrid;

		const RVector& segrid;

		int n_sf, n_se;
	};

	double wrapper_cd_util(double c, double m, const ObjArgs& args);
}

class BellmanImpl {
	public:
		BellmanImpl(const Parameters& p_)
			: p(p_), V(boost::extents[p_.nx][p_.nyP][p_.np]),
				EV(boost::extents[p_.n_sf][p_.n_se][p_.nyP])
		{
			t = p->T;
		}

		const Parameters& p;

		arr3d V, EV;

		Income income;

		Grids grids;

		int t;
};

Bellman::Bellman(const Parameters& p)
{
	impl.reset(new BellmanImpl(p));
}

void Bellman::solve()
{
	compute_terminal_value();

	while (impl->t > 0) {
		update_EV();
		compute_value_t();
	}
}

void Bellman::compute_terminal_value()
{
	const Parameters& p = impl->p;
	const Grids& grids = impl->grids;
	const arr3d& V = impl->V;

	for (int ix=0; ix<p.nx; ++ix) {
		for (int iyP=0; iyP<p.nyP; ++iyP) {
			for (int ip=0; ip<p.np; ++ip) {
				V[ix][iyP][ip] = pow(grids.x[ix], 1.0 - p.gam);
			}
		}
	}
	--(impl->t);
}

void Bellman::compute_value_t()
{
	const Parameters& p = impl->p;
	const Grids& grids = impl->grids;
	const arr3d& V = impl->V;

	ObjArgs args;
	args.gam = p.gam;
	args.phi1 = p.phi1;
	args.phi2 = p.phi2;
	args.Rb = p.Rb;
	args.beta = p.beta;

	for (int ix=0; ix<p.nx; ++ix) {
		args.x = grids.x[ix];
		for (int iyP=0; iyP<p.nyP; ++iyP) {
			auto idx = boost::indices[range()][range()][iyP];
			arg->values = impl->EV[idx];
			for (int ip=0; ip<p.np; ++ip) {
				solve_decisions(this, ix, iyP, ip, args);
			}
		}
	}
	--(impl->t);
}

void solve_decisions(BellmanImpl* impl, int ix, int iyP, int ip,
	ObjArgs& args)
{
	const Parameters& p = impl->p;
	const Grids& grids = impl->grids;
	double x = grids.x[ix];
	double lprefshock = grids.lpref[ip];

	double z0[3];

	// s
	z0[0] = 0.5 * x;

	// q_b
	z0[1] = 0.3;

	// q_e
	z0[2] = 0.3;

	for (int isf=0; isf<p.n_sf; ++isf) {
		sf = grids.sf[isf];
		for (int ise=0; ise<p.n_se; ++ise) {
			se = grids.se[ise];
		}
	}
}

void objective(z, void* args)
{
	const ObjArgs* args = (ObjArgs*) args;

	double c, s, q_b, q_e;
	s = z[0];
	q_b = z[1];
	q_e = z[2];
	c = args->x - s;

	double m, u, sf, se, ev;
	m = (1.0-q_b-q_e) * s;
	u = wrapper_cd_util(c, m, args);
	sf = m + q_b * s * args->Rb;
	se = q_e * s;

	// auto idx = boost::indices[range()][range()][iyP];
	// arr3d::view<2> values = impl->EV[idx];

	ev = linterp2(args->sfgrid, args->segrid, args->values,
		args->n_sf, args->n_se, sf, se);

	return u + args->beta * ev;
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

namespace {
	double wrapper_cd_util(double c, double m, const ObjArgs& args)
	{
		return cd_util(c, m, args->gam, args->phi1, args->phi2);
	}
}