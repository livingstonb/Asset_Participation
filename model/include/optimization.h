#ifndef OPTIMIZATION_HEADER
#define OPTIMIZATION_HEADER

// void optimize(const double* vals_inp, int n);

// template<typename T>
// void optimize(const T& vals_inp, int n)
// {
// 	double* arr = new double[n];

// 	for (int i=0; i<n; ++i)
// 		arr[i] = vals_inp[i];

// 	optimize(arr, n);
// 	delete[] arr;
// }

bool test_opt(const double*, int n);

// double test_fn(const arma::vec& x, arma::vec* grad_out, void* opt_data);

#endif