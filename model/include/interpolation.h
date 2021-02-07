#ifndef INTERPOLATION_HEADER
#define INTERPOLATION_HEADER

namespace {
	template<typename T>
	int lookup1d(const T& grid, int n, double x);
}

template<typename T, typename V>
double linterp1(const T& grid, const V& values, int n, double x)
{
	int iv = lookup1d(grid, n, x);
	double wt = (grid[iv] - x) / (grid[iv] - grid[iv-1]);

	wt = fmax(fmin(wt, 1), 0);

	double val_l = wt * values[iv-1];
	double val_u = (1-wt) * values[iv];
	return val_l + val_u;
}

template<typename T, typename V>
double linterp2(const T& grid0, const T& grid1,
	const V& values, int n0, int n1, double x0, double x1)
{
	int iv0 = lookup1d(grid0, n0, x0);
	int iv1 = lookup1d(grid1, n1, x1);

	double wt0 = (grid0[iv0] - x0) / (grid0[iv0] - grid0[iv0-1]);
	double wt1 = (grid1[iv1] - x1) / (grid1[iv1] - grid1[iv1-1]);

	wt0 = fmax(fmin(wt0, 1), 0);
	wt1 = fmax(fmin(wt1, 1), 0);

	double val_ll = wt0 * wt1 * values[iv0-1][iv1-1];
	double val_lu = wt0 * (1-wt1) * values[iv0-1][iv1];
	double val_ul = (1-wt0) * wt1 * values[iv0][iv1-1];
	double val_uu = (1-wt0) * (1-wt1) * values[iv0][iv1];

	return val_ll + val_lu + val_ul + val_uu;
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