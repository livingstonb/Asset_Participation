
#include <interpolation.h>
#include <eigen_interface.h>
#include <cmath>

namespace {
	template<typename VecType>
	int lookup1d(const VecType& grid, double x);

	double linterp1_impl(const Eigen::Ref<const RMatrix>& values,
		const Eigen::Ref<const RVector>& grid, double x);

	double linterp2_impl(const RMatrixRef& values,
		const RVectorRef& grid0, const RVectorRef& grid1,
		double x0, double x1);
}

double linterp1(const RMatrixRefWrapper& values,
	const RVectorRefWrapper& grid, double x) {
	return linterp1_impl(values.data, grid.data, x);
}

double linterp2(const RMatrixRefWrapper& values,
	const RVectorRefWrapper& grid0,
	const RVectorRefWrapper& grid1, double x0, double x1) {
	return linterp2_impl(values.data, grid0.data, grid1.data,
		x0, x1);
}

namespace {
	template<typename VecType>
	int lookup1d(const VecType& grid, double x) {
		int n = grid.rows();

		if ( x <= grid(0) ) {
			return 1;
		}
		else if ( x >= grid(n-1) ) {
			return n - 1;
		}
		else {
			int lower, upper, mid;
			lower = 0;
			upper = n - 1;

			while ( upper - lower > 1 ) {
				mid = (lower + upper) >> 1;
				if ( x <= grid(mid) )
					upper = mid;
				else
					lower = mid;
			}

			return upper;
		}
	}

	double linterp1_impl(const Eigen::Ref<const RMatrix>& values,
		const Eigen::Ref<const RVector>& grid, double x)
	{
		int iv = lookup1d(grid, x);
		double wt = (grid(iv) - x) / (grid(iv) - grid(iv-1));

		wt = fmax(fmin(wt, 1), 0);

		double val_l = wt * values(iv-1, 0);
		double val_u = (1-wt) * values(iv, 0);
		return val_l + val_u;
	}

	double linterp2_impl(const Eigen::Ref<const RMatrix>& values,
		const Eigen::Ref<const RVector>& grid0,
		const Eigen::Ref<const RVector>& grid1,
		double x0, double x1)
	{
		int n0 = grid0.rows();

		int iv0 = lookup1d(grid0, x0);
		int iv1 = lookup1d(grid1, x1);

		double wt0 = (grid0(iv0) - x0) / (grid0(iv0) - grid0(iv0-1));
		double wt1 = (grid1(iv1) - x1) / (grid1(iv1) - grid1(iv1-1));

		wt0 = fmax(fmin(wt0, 1), 0);
		wt1 = fmax(fmin(wt1, 1), 0);

		double val_ll = wt0 * wt1 * values(iv0-1 + n0 * (iv1-1), 0);
		double val_lu = wt0 * (1-wt1) * values(iv0-1 + n0 * iv1, 0);
		double val_ul = (1-wt0) * wt1 * values(iv0 + n0 * (iv1-1), 0);
		double val_uu = (1-wt0) * (1-wt1) * values(iv0 + n0 * iv1, 0);

		return val_ll + val_lu + val_ul + val_uu;
	}
}

