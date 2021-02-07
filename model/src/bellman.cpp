#include <bellman.h>
#include <boost_includes.h>
#include <interpolation.h>
#include <parameters.h>
#include <grids.h>
#include <functions.h>

using BellmanPtr = std::unique_ptr<BellmanImpl>;

namespace {
	struct ObjArgs {
		double x, gam, phi1, phi2, Rb, beta;

		arr3d::view<2> evalues;

		const std::vector<double>& sfgrid;

		const std::vector<double>& segrid;

		int n_sf, n_se;
	};

	double wrapper_cd_util(double c, double m, const ObjArgs& args);
}

class BellmanImpl {
	public:
		BellmanImpl(const Parameters& p_, const Grids& grids)
			: p(p_), grids(grids_),
				V(boost::extents[grids.nx][grids.nyP][grids.np]),
				EV(boost::extents[grids.n_sf][grids.n_se][grids.nyP])
		{
			nx = nx;
			n_sf = n_sf;
			n_se = n_se;
			n_re = n_re;
			nyP = nyP;
			nyT = nyT;
			np = np;
			xmax = grids.xmax;
			curv = grids.curv;
			t = p.T;
		}

		void compute_terminal_value();

		void update_EV();

		void compute_value_t();

		void solve_decisions(int ix, int iyP, int ip,
			const ObjArgs& args);

		const Parameters& p;

		const Grids& grids;

		arr3d V, EV;

		Income income;

		Grids grids;

		double xmax, curv;

		int t, nx, n_sf, n_se, n_re, nyP, nyT, np;
};

void BellmanImpl::compute_terminal_value()
{
	for (int ix=0; ix<nx; ++ix) {
		for (int iyP=0; iyP<nyP; ++iyP) {
			for (int ip=0; ip<np; ++ip) {
				V[ix][iyP][ip] = pow(grids.x[ix], 1.0 - p.gam);
			}
		}
	}
	--t;
}

void BellmanImpl::update_EV()
{
	// Computes continuation value as a function of sf, se, y.
	//
	// sf : Amount invested in safe assets, after interest
	// se : Amount invested in equity, before return

	double sf, se, xp;
	// boost::array<arr3d::index, 3> shape = {{ nx, ny, np }};

	std::vector<arr3d::view<1>> vviews(nyP * np);
	for (int iyP=0; iyP<nyP; ++iyP) {
		for (int ip=0; ip<np; ++ip) {
			vviews[iyP + nyP * ip] = V[ boost::indices[range()][iyP][ip] ];
		}
	}

	double evval;
	double xp;

	// Compute V' by interpolation
	double vp[n_y];
	for (int isf=0; isf<n_sf; ++isf) {
		sf = grids.sf[isf];
		for (int ise=0; ise<n_se; ++ise) {
			se = grids.se[ise];
			for (int iyP=0; iy<nyP; ++iyP) {
				EV[isf][ise][iyP] = val_EV(sf, se, iyP);
			}
		}
	}
}

double BellmanImpl::val_EV(double sf, double se, int iyP,
	const std::vector<arr3d::view<1>>& vviews) const
{
	double ev = 0.0;

	for (int iyT=0; iyT<nyT; ++iyT) {
		for (int ie=0; ie<n_re; ++ie) {
			xp = sf + se * grids.Re[ie] + grids.y[iyP + nyP * iyT];
			for (int ip=0; ip<np; ++ip) {
				for (int iyP2=0; iyP2<nyP; ++iyP2) {
					ev +=
						grids.lpref_dist[ip] * grids.Re_dist[ie]
						* grids.yP_trans[iyP + nyP * iyP2] * grids.yT_dist[iyT]
						* linterp1(grids.x, vviews[iyP2 + nyP * ip, nx, xp);
				}
			}
		}
	}
	return ev;
}

void BellmanImpl::compute_value_t()
{
	ObjArgs args;
	args.gam = p.gam;
	args.phi1 = p.phi1;
	args.phi2 = p.phi2;
	args.Rb = p.Rb;
	args.beta = p.beta;

	for (int ix=0; ix<nx; ++ix) {
		args.x = grids.x[ix];
		for (int iyP=0; iyP<nyP; ++iyP) {
			auto idx = boost::indices[range()][range()][iyP];
			arg->values = EV[idx];
			for (int ip=0; ip<np; ++ip) {
				solve_decisions(ix, iyP, ip, args);
			}
		}
	}
	--t;
}

void BellmanImpl::solve_decisions(int ix, int iyP,
	int ip, const ObjArgs& args)
{
	double x = grids.x[ix];
	double lprefshock = grids.lpref[ip];

	double z0[3];

	// s
	z0[0] = 0.5 * x;

	// q_b
	z0[1] = 0.3;

	// q_e
	z0[2] = 0.3;

	for (int isf=0; isf<n_sf; ++isf) {
		sf = grids.sf[isf];
		for (int ise=0; ise<n_se; ++ise) {
			se = grids.se[ise];
		}
	}
}

Bellman::Bellman(const Parameters& p, const Grids& grids)
{
	impl.reset(new BellmanImpl(p, grids));
}

void Bellman::solve()
{
	impl.compute_terminal_value();

	while (impl->t >= 0) {
		impl.update_EV();
		impl.compute_value_t();
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

namespace {
	double wrapper_cd_util(double c, double m, const ObjArgs& args)
	{
		return cd_util(c, m, args->gam, args->phi1, args->phi2);
	}
}