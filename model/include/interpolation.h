#ifndef INTERPOLATION_HEADER
#define INTERPOLATION_HEADER

struct LInterp2Data;

struct RMatrixRefWrapper;

struct RVectorRefWrapper;

double linterp1(const RMatrixRefWrapper& values,
	const RVectorRefWrapper& grid, double x);

double linterp2(const RMatrixRefWrapper&, const RVectorRefWrapper&,
	const RVectorRefWrapper&, double x0, double x1);

#endif