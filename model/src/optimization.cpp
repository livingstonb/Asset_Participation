#include <optimization.h>
#define OPTIM_ENABLE_ARMA_WRAPPERS
#include <optim.hpp>
#include <cmath>



bool lbfgs_wrapper(double* z, const optimlib_fn& obj_fn, void* args,
	const double* lb, const double* ub)
{
	arma::vec ax(3, 1);
	ax(0) = z[0];
	ax(1) = z[1];
	ax(2) = z[2];

	std::function<double(const arma::vec&, arma::vec*, void*)>
		fn = [&](const arma::vec& data, arma::vec* grad, void* opts)
		{
			double y = -obj_fn(data.memptr(), opts);
			return y;
		};

	optim::algo_settings_t options;
	options.vals_bound = true;
	// arma::vec lb(3, 1);
	// lb[0] = 0.0;
	// lb[1] = 0.0;
	// lb[2] = 0.0;
	// arma::vec ub(3, 1);
	// ub[0] = 200.0;
	// ub[1] = 0.5;
	// ub[2] = 0.5;
	// options.lower_bounds = lb;
	// options.upper_bounds = ub;
	options.lower_bounds = arma::vec(lb, 3);
	options.upper_bounds = arma::vec(ub, 3);

	bool success = optim::lbfgs(ax, fn, args, options);

	z[0] = ax(0);
	z[1] = ax(1);
	z[2] = ax(2);
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