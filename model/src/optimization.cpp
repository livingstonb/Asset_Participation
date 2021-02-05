#include <optimization.h>
#define OPTIM_ENABLE_ARMA_WRAPPERS
#include <optim.hpp>
#include <cmath>

double test_fn(const arma::vec& x, arma::vec* grad_out, void* opt_data)
{
	return pow(x[0] - 0.15, 2.0) + pow(x[1] + 0.234, 2.0);
}

bool test_opt(const double* x, int n)
{
	arma::vec ax(n);
	ax[0] = x[0];
	ax[1] = x[1];

	bool success = optim::bfgs(ax, test_fn, nullptr);
	return success;
}