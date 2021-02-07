


using nlopt_fn = 
double f(const std::vector`<double>` &x, std::vector`<double>` &grad, void* f_data);

nlopt::opt optimizer(nlopt::LD_LBFGS, n);