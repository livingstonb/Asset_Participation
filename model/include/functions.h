#ifndef FUNCTIONS_HEADER
#define FUNCTIONS_HEADER

#include <iostream>

double ces_util(double c, double m, double a, double b);

double cd_util(double c, double m, double gam, double phi1, double phi2);

template<typename T>
void print_vec(const T& vec)
{
	std::cout << "---- values ----\n";
	for (auto& x : vec)
		std::cout << '\t' << x << '\n';

	std::cout << '\n';
}

#endif