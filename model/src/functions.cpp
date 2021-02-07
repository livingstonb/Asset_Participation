#include <functions.h>
#include <cmath>

double ces_util(double c, double m, double a, double b)
{
	double x = a * pow(c, 1.0-b) + (1.0-a) * pow(m, 1.0-b);
	return pow(x, 1.0 / (1.0-b));
}

double cd_util(double c, double m, double gam, double phi1, double phi2)
{
	double u, v;

	if (gam == 1.0)
		u = log(c);
	else
		u = pow(c, 1.0 - gam) / (1.0 - gam);
	
	v = pow(m + 0.1, 1.0 + phi2) / (1.0 + phi2);

	return u + phi1 * v;
}