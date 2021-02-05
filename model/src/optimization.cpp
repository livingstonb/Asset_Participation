#include <optimization.h>
#define OPTIM_ENABLE_ARMA_WRAPPERS
#include <optim.hpp>
#include <cmath>

double test_fn(const arma::vec& x, arma::vec* grad_out, void* opt_data)
{
	return fabs(x(0) - 0.15) + fabs(x(1) + 0.234);
}

bool test_opt(const double* x, int n)
{
	arma::vec ax(n, 1);
	ax(0) = x[0];
	ax(1) = x[1];

	// optim::algo_settings_t settings;
	// settings.err_tol = 1.0e-10;
	// settings.iter_max = 1e5;

	bool success = optim::lbfgs(ax, test_fn, nullptr);
	std::cout << "x0* = " << ax(0) << '\n';
	std::cout << "x1* = " << ax(1) << '\n';
	return success;
}