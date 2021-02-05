#ifndef INTERPOLATION_HEADER
#define INTERPOLATION_HEADER

struct LInterp2Data;

struct RMatrixRefWrapper;

struct RVectorRefWrapper;

namespace {
	template<typename T>
	int lookup1d(const T& grid, int n, double x);
}

// double linterp1(const RMatrixRefWrapper& values,
// 	const RVectorRefWrapper& grid, double x);

// double linterp2(const RMatrixRefWrapper&, const RVectorRefWrapper&,
// 	const RVectorRefWrapper&, double x0, double x1);

template<typename T, typename V>
double linterp1(const T& grid, const V& values, int n, double x)
{
	int iv = lookup1d(grid, n, x);
	double wt = (grid[iv] - x) / (grid[iv] - grid[iv-1];

	wt = fmax(fmin(wt, 1), 0);

	double val_l = wt * values[iv-1];
	double val_u = (1-wt) * values[iv];
	return val_l + val_u;
}

namespace {
	template<typename T>
	int lookup1d(const T& grid, int n, double x) {
		if ( x <= grid[0] ) {
			return 1;
		}
		else if ( x >= grid[n-1] ) {
			return n - 1;
		}
		else {
			int lower, upper, mid;
			lower = 0;
			upper = n - 1;

			while ( upper - lower > 1 ) {
				mid = (lower + upper) >> 1;
				if ( x <= grid[mid] )
					upper = mid;
				else
					lower = mid;
			}

			return upper;
		}
	}
}

#endif