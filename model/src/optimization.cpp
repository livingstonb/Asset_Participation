#include <optimization.h>
#define OPTIM_ENABLE_ARMA_WRAPPERS
#include <optim.hpp>
#include <cmath>



bool lbfgs_wrapper(double* z, const optimlib_fn& obj_fn, void* args,
	const double* lb, const double* ub, int n)
{
	arma::vec ax(n, 1);
	for (int i=0; i<n; ++i)
		ax(i) = z[i];

	std::function<double(const arma::vec&, arma::vec*, void*)>
		fn = [&](const arma::vec& data, arma::vec* grad, void* opts)
		{
			double y = -obj_fn(data.memptr(), opts);
			return y;
		};

	optim::algo_settings_t options;
	options.vals_bound = true;

	options.lower_bounds = arma::vec(lb, n);
	options.upper_bounds = arma::vec(ub, n);

	bool success = optim::nm(ax, fn, args, options);

	for (int i=0; i<n; ++i)
		z[i] = ax(i);

	return success;
}

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