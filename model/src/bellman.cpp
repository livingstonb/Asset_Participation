#include <bellman.h>
#include <boost_includes.h>
#include <interpolation.h>
#include <parameters.h>
#include <grids.h>
#include <functions.h>
#include <optimization.h>
#include <iostream>
#include <fstream>
#include <functional>
#include <memory>

namespace {
	struct ObjArgs {
		ObjArgs(const std::vector<double>& sfgrid_,
			const std::vector<double>& segrid_)
			: sfgrid(sfgrid_), segrid(segrid_)
		{
			n_sf = sfgrid.size();
			n_se = segrid.size();
		}

		double x, gam, phi1, phi2, Rb, beta, xmax;

		arr3d::array_view<2>::type* evalues = nullptr;

		const std::vector<double>& sfgrid;

		const std::vector<double>& segrid;

		int n_sf, n_se;

		double lb[3];

		double ub[3];
	};

	struct OptResults {
		void set(double v_, double* z) {
			v = v_;
			s = z[0];
			q_b = z[1] * z[2];
			q_e = z[1] * (1 - z[2]);
		}

		double v, s, c, q_b, q_e;
	};

	double wrapper_cd_util(double c, double m, const ObjArgs& args);

	double value_fn(const double* z, void* vargs, bool m0, bool b0, bool e0);
}

class BellmanImpl {
	public:
		BellmanImpl(const Parameters& p_, const Grids& grids_)
			: p(p_), grids(grids_),
				V(boost::extents[grids.nx][grids.nyP][grids.np]),
				EV(boost::extents[grids.n_sf][grids.n_se][grids.nyP]),
				c(boost::extents[grids.nx][grids.nyP][grids.np]),
				s(boost::extents[grids.nx][grids.nyP][grids.np]),
				q_b(boost::extents[grids.nx][grids.nyP][grids.np]),
				q_e(boost::extents[grids.nx][grids.nyP][grids.np])
		{
			nx = grids.nx;
			n_sf = grids.n_sf;
			n_se = grids.n_se;
			n_re = grids.n_re;
			nyP = grids.nyP;
			nyT = grids.nyT;
			np = grids.np;
			xmax = grids.xmax;
			curv = grids.curv;
			t = p.T;
		}

		void compute_terminal_value();

		void update_EV();

		void compute_value_t();

		void solve_decisions(int ix, int iyP, int ip,
			const ObjArgs& args);

		double val_EV(double sf, double se, int iyP,
			const std::vector<arr3d::array_view<1>::type>& vviews) const;

		const Parameters& p;

		const Grids& grids;

		arr3d V, EV, c, s, q_b, q_e;

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

	
	// boost::array<arr3d::index, 3> shape = {{ nx, ny, np }};

	std::vector<arr3d::array_view<1>::type> vviews;
	vviews.reserve(nyP * np);
	for (int ip=0; ip<np; ++ip) {
		for (int iyP=0; iyP<nyP; ++iyP) {
			vviews.push_back(V[ boost::indices[range()][iyP][ip] ]);
		}
	}

	double sf, se;

	// Compute V' by interpolation
	for (int isf=0; isf<n_sf; ++isf) {
		sf = grids.sf[isf];
		for (int ise=0; ise<n_se; ++ise) {
			se = grids.se[ise];
			for (int iyP=0; iyP<nyP; ++iyP) {
				EV[isf][ise][iyP] = val_EV(sf, se, iyP, vviews);
			}
		}
	}
}

double BellmanImpl::val_EV(double sf, double se, int iyP,
	const std::vector<arr3d::array_view<1>::type>& vviews) const
{
	double xp, ev = 0.0;

	for (int iyT=0; iyT<nyT; ++iyT) {
		for (int ie=0; ie<n_re; ++ie) {
			xp = sf + se * grids.Re[ie] + grids.y[iyP + nyP * iyT];
			for (int ip=0; ip<np; ++ip) {
				for (int iyP2=0; iyP2<nyP; ++iyP2) {
					ev +=
						grids.lpref_dist[ip] * grids.Re_dist[ie]
						* grids.yP_trans[iyP + nyP * iyP2] * grids.yT_dist[iyT]
						* linterp1(grids.x, vviews[iyP2 + nyP * ip], nx, xp);
				}
			}
		}
	}
	return ev;
}

void BellmanImpl::compute_value_t()
{
	ObjArgs args(grids.sf, grids.se);
	args.gam = p.gam;
	args.phi1 = p.phi1;
	args.phi2 = p.phi2;
	args.Rb = p.Rb;
	args.beta = p.beta;
	args.xmax = grids.xmax;

	// s
	args.lb[0] = 1.0e-9;

	// share invested
	args.lb[1] = 1.0e-9;
	args.ub[1] = 1.0 - 1.0e-9;

	// equity share of investments
	args.lb[2] = 1.0e-9;
	args.ub[2] = 1.0 - 1.0e-9;

	arr3d::index_gen indices;

	for (int ix=0; ix<nx; ++ix) {
		args.x = grids.x[ix];
		args.ub[0] = args.x - 1.0e-9;
		for (int iyP=0; iyP<nyP; ++iyP) {
			auto idx = indices[range()][range()][iyP];
			arr3d::array_view<2>::type ev = EV[idx];
			args.evalues = &ev;
			for (int ip=0; ip<np; ++ip) {
				solve_decisions(ix, iyP, ip, args);
			}
		}
	}

	if (t == p.T - 8) {
		std::ofstream policyfuns("output/policies.csv");
		policyfuns << "V, x, s, c, q_b, q_e\n";

		int iyP = 1;
		int ip = 0;
		for (int ix=0; ix<nx; ++ix) {
			policyfuns << V[ix][iyP][ip] << ",";
			policyfuns << grids.x[ix] << ",";
			policyfuns	<< s[ix][iyP][ip] << ",";
			policyfuns << c[ix][iyP][ip] << ",";
			policyfuns	<< q_b[ix][iyP][ip] << ",";
			policyfuns << q_e[ix][iyP][ip] << "\n";
		}
		policyfuns.close();

		std::ofstream evs("output/EV.csv");
		for (int ise=0; ise<n_se; ++ise)
			evs << grids.se[ise] << ",";
		evs << '\n';

		for (int isf=0; isf<n_sf; ++isf) {
			evs << grids.sf[isf] << ",";
			for (int ise=0; ise<n_se; ++ise) {
				evs << EV[isf][ise][iyP] << ",";
			}
			evs << '\n';
		}
		evs.close();
	}
	--t;
}

void BellmanImpl::solve_decisions(int ix, int iyP,
	int ip, const ObjArgs& args)
{
	OptResults results;
	double val, x = grids.x[ix];
	double lprefshock = grids.lpref[ip];
	double z3[3];
	double z2[2];
	double lb2[2];
	double ub2[2];
	double z1, lb, ub;
	bool success;
	
	// No saving
	z1 = 0;
	val = value_fn(&z1, (void*) &args, true, true, true);
	results.v = val;
	results.s = z1;
	results.q_b = 0;
	results.q_e = 0;

	// Saving in bonds only, maximize over s
	lb = 1.0e-9;
	ub = x - 1.0e-9;
	z1 = 0.5 * ub;
	const std::function<double(const double*, void*)>& objfn_b_only
		= [&](const double* zz, void* aargs) {
			return value_fn(zz, aargs, true, false, true);
		};
	success = lbfgs_wrapper(&z1, objfn_b_only, (void*) &args, &lb, &ub, 1);
	val = objfn_b_only(&z1, (void*) &args);
	if ( (val > results.v) & success ) {
		results.v = val;
		results.s = z1;
		results.q_b = 1;
		results.q_e = 0;
	}

	// Saving in stocks only, maximize over s
	lb = 1.0e-9;
	ub = x - 1.0e-9;
	z1 = 0.5 * ub;
	const std::function<double(const double*, void*)>& objfn_s_only
		= [&](const double* zz, void* aargs) {
			return value_fn(zz, aargs, true, true, false);
		};
	success = lbfgs_wrapper(&z1, objfn_s_only, (void*) &args, &lb, &ub, 1);
	val = objfn_s_only(&z1, (void*) &args);
	if ( (val > results.v) & success ) {
		results.v = val;
		results.s = z1;
		results.q_b = 0;
		results.q_e = 1;
	}

	// Saving in money only, maximize over s
	lb = 1.0e-9;
	ub = x - 1.0e-9;
	z1 = 0.5 * ub;
	const std::function<double(const double*, void*)>& objfn_m_only
		= [&](const double* zz, void* aargs) {
			return value_fn(zz, aargs, false, true, true);
		};
	success = lbfgs_wrapper(&z1, objfn_m_only, (void*) &args, &lb, &ub, 1);
	val = objfn_m_only(&z1, (void*) &args);
	if ( (val > results.v) & success ) {
		results.v = val;
		results.s = z1;
		results.q_b = 0;
		results.q_e = 0;
	}

	// Saving in money & bonds, maximize over s, b
	lb2[0] = 1.0e-9;
	lb2[1] = 1.0e-9;
	ub2[0] = x - 1.0e-9;
	ub2[1] = 1.0 - 1.0e-9;
	z2[0] = 0.5 * ub2[0];
	z2[1] = 0.5;
	const std::function<double(const double*, void*)>& objfn_m_b_only
		= [&](const double* zz, void* aargs) {
			return value_fn(zz, aargs, false, false, true);
		};
	success = lbfgs_wrapper(z2, objfn_m_b_only, (void*) &args, lb2, ub2, 2);
	val = objfn_m_b_only(z2, (void*) &args);
	if ( (val > results.v) & success ) {
		results.v = val;
		results.s = z2[0];
		results.q_b = z2[1];
		results.q_e = 0;
	}

	// Saving in money & stocks, maximize over s, q_e
	lb2[0] = 1.0e-9;
	lb2[1] = 1.0e-9;
	ub2[0] = x - 1.0e-9;
	ub2[1] = 1.0 - 1.0e-9;
	z2[0] = 0.5 * ub2[0];
	z2[1] = 0.5;
	const std::function<double(const double*, void*)>& objfn_m_s_only
		= [&](const double* zz, void* aargs) {
			return value_fn(zz, aargs, false, true, false);
		};
	success = lbfgs_wrapper(z2, objfn_m_s_only, (void*) &args, lb2, ub2, 2);
	val = objfn_m_s_only(z2, (void*) &args);
	if ( (val > results.v) & success ) {
		results.v = val;
		results.s = z2[0];
		results.q_b = 0;
		results.q_e = z2[1];
	}

	// Saving in bonds & stocks, maximize over s, q_b
	lb2[0] = 1.0e-9;
	lb2[1] = 1.0e-9;
	ub2[0] = x - 1.0e-9;
	ub2[1] = 1.0 - 1.0e-9;
	z2[0] = 0.5 * ub2[0];
	z2[1] = 0.5;
	const std::function<double(const double*, void*)>& objfn_b_s_only
		= [&](const double* zz, void* aargs) {
			return value_fn(zz, aargs, true, false, false);
		};
	success = lbfgs_wrapper(z2, objfn_b_s_only, (void*) &args, lb2, ub2, 2);
	val = objfn_b_s_only(z2, (void*) &args);
	if ( (val > results.v) & success ) {
		results.v = val;
		results.s = z2[0];
		results.q_b = z2[1];
		results.q_e = 1.0 - z2[1];
	}

	// Look for interior solution
	z3[0] = 0.5 * x;
	z3[1] = 0.5;
	z3[2] = 0.5;

	const std::function<double(const double*, void*)>& objfn_interior
		= [&](const double* zz, void* aargs) {
			return value_fn(zz, aargs, false, true, false);
		};
	success = lbfgs_wrapper(z3, objfn_interior, (void*) &args, args.lb, args.ub, 3);
	val = objfn_interior(z3, (void*) &args);
	if ( (val > results.v) & success )
		results.set(val, z3);

	s[ix][iyP][ip] = results.s;
	c[ix][iyP][ip] = x - results.s;
	q_b[ix][iyP][ip] = results.q_b;
	q_e[ix][iyP][ip] = results.q_e;
	V[ix][iyP][ip] = results.v;
}

Bellman::Bellman(const Parameters& p, const Grids& grids)
{
	impl = new BellmanImpl(p, grids);
}

Bellman::~Bellman()
{
	delete impl;
}

void Bellman::solve()
{
	std::cout << "Solving terminal period.\n";
	impl->compute_terminal_value();

	while (impl->t >= 0) {
		impl->update_EV();
		std::cout << "Solving period " << impl->t << "\n";
		impl->compute_value_t();
	}
}

namespace {
	double wrapper_cd_util(double c, double m, const ObjArgs& args)
	{
		return cd_util(c, m, args.gam, args.phi1, args.phi2);
	}

	double value_fn(const double* z, void* vargs, bool m0, bool b0, bool e0)
	{
		const ObjArgs* args = (ObjArgs*) vargs;

		double c, s, q_b, q_e;

		s = z[0];

		if ( m0 )
			s = 0;

		if ( b0 & e0 ) {
			q_b = 0;
			q_e = 0;
		}
		else if ( b0 ) {
			q_b = 0;
			q_e = z[1];
		}
		else if ( e0 ) {
			q_e = 0;
			q_b = z[1];
		}
		else if ( m0 ) {
			q_b = z[1];
			q_e = 1.0 - q_b;
		}
		else {
			q_b = z[1] * z[2];
			q_e = z[1] * (1.0 - z[2]);
		}

		c = args->x - s;

		double m, u, sf, se, ev;
		m = (1.0 - q_b - q_e) * s;
		u = wrapper_cd_util(c, m, *args);
		sf = m + q_b * s * args->Rb;
		se = q_e * s;

		ev = linterp2(args->sfgrid, args->segrid, *(args->evalues),
			args->n_sf, args->n_se, sf, se);

		return u + args->beta * ev;
	}
}