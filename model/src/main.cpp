
// #include <interpolation.h>
// #include <eigen_interface.h>
#include <iostream>
// #include "optim.hpp"
#include <optimization.h>

// using LInterp2Spec = LInterp2<RVector, RMatrixBlock>;

int main() {
	// int n0 = 3;
	// int n1 = 2;
	// int ny = 2;

	// RMatrix values(n0 * n1, ny);
	// values << 100, 200,
	// 	101, 201,
	// 	102, 202,
	// 	200, 300,
	// 	201, 301,
	// 	202, 302;


	// RVector grid0(n0);
	// grid0 << 1, 2, 3;

	// RVector grid1(n1);
	// grid1 << 10, 20;

	// std::cout << linterp2(values.col(1), grid0, grid1, 1.5, 30) << '\n';

	double* arr = new double[2];
	arr[0] = -1;
	arr[1] = 1;

	bool success = test_opt(arr, 2);
	std::cout << success << '\n';

	return 0;
}