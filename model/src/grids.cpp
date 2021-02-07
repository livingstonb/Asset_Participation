#include <grids.h>
#include <cmath>

namespace {
	std::vector<double> linspace(int n);
	std::vector<double> curved_grid(double a, double b,
		int n, double curv);
}

Grids::Grids()
{
	create_income_dist();

	create_saving_grids();

	create_returns_dist();

	create_pref_dist();
}

void Grids::create_saving_grids()
{
	x = curved_grid(ymin, xmax, nx, curv);
	sf = curved_grid(0.0, xmax, n_sf, curv);
	se = curved_grid(0.0, xmax, n_se, curv);
}

void Grids::create_returns_dist()
{
	// Re.resize(n_re);
	Re = {1.0, 1.014};

	// Re_dist.resize(n_re);
	Re_dist = {0.5, 0.5};
}

void Grids::create_income_dist()
{
	// yP.resize(nyP);
	yP = {0.2, 0.3};

	// yP_trans.resize(nyP * nyP);
	yP_trans = {0.7, 0.3, 0.3, 0.7};

	// yP_dist = RVector(nyP);
	yP_dist = {0.5, 0.5};

	// yT = RVector(nyT);
	yT = {1.0};

	// yT_dist = RVector(nyT);
	yT_dist = {1.0};

	y_dist.reserve(nyP * nyT);
	y.reserve(nyP * nyT);
	double meany = 0;
	for (int iyP=0; iyP<nyP; ++iyP) {
		for (int iyT=0; iyT<nyT; ++iyT) {
			y_dist.push_back(yP_dist[iyP] * yT_dist[iyT]);
			y.push_back(yP[iyP] * yT[iyT]);
			meany += yP[iyP] * yT[iyT] / (yP_dist[iyP] * yT_dist[iyT]);
		}
	}

	for (auto& yval : y)
		yval /= meany;

	for (auto& yTval : yT)
		yTval /= meany;

	ymin = yP[0] * yT[0];
}

void Grids::create_pref_dist()
{
	// lpref.resize(np);
	lpref = {0.1};

	// lpref_dist = RVector(np);
	lpref_dist = {1.0};
}

namespace {
	std::vector<double> linspace(int n)
	{
		std::vector<double> vec_out(n);

		for (int i=0; i<n; ++i)
			vec_out[i] = double(i) / (n - 1);

		return vec_out;
	}

	std::vector<double> curved_grid(double a, double b, int n, double curv)
	{
		std::vector<double> vec_out = linspace(n);

		for (auto& x : vec_out)
			x = a + (b - a) * pow(x, 1.0 / curv);

		return vec_out;
	}
}