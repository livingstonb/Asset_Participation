#include <grids.h>

namespace {
	RVector linspace(int n);
	RVector curved_grid(double a, double b, int n, double curv);
}

void Grids::create_saving_grids()
{
	sf = curved_grid(0.0, xmax, n_sf, curv);
	se = curved_grid(0.0, xmax, n_se, curv);
}

void Grids::create_returns_dist()
{
	Re = RVector(n_re);
	Re << 1.0, 1.014;

	Re_dist = RVector(n_re);
	Re_dist << 0.5, 0.5;
}

void Grids::create_income_dist()
{
	yP = RVector(nyP);
	yP << 0.2, 0.3;

	yP_trans = RMatrix(nyP, nyP);
	yP_trans << 0.7, 0.3,
				0.3, 0.7;

	yP_dist = RVector(nyP);
	yP_dist << 0.5, 0.5;

	yT = RVector(nyT);
	yT << 1.0;

	yT_dist = RVector(nyT);
	yT_dist << 1.0;

	y_dist = yP_dist * yT_dist.transpose();

	y = yP * yT.transpose();
	double meany = yP_dist.T * y * yT_dist;
	y /= meany;
	yT /= meany;
}

void Grids::create_pref_dist()
{
	lpref = RVector(np);
	lpref << 0.1;

	lpref_dist = RVector(np);
	lpref_dist << 1.0;
}

namespace {
	RVector linspace(int n)
	{
		RVector vec_out(n);

		for (int i=0; i<n; ++i)
			vec_out[i] = i / (n - 1);

		return vec_out;
	}

	RVector curved_grid(double a, double b, int n, double curv)
	{
		RVector vec_out = linspace(n);
		vec_out = a + (b - a) * vec_out.array().pow(1.0 / curv);
		return vec_out;
	}
}