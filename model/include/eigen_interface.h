#ifndef EIGEN_INTERFACE_HEADER
#define EIGEN_INTERFACE_HEADER

#include <Eigen/Core>

using RMatrix = Eigen::MatrixXd;
using RVector = Eigen::VectorXd;
using RMatrixBlock = Eigen::Block<const RMatrix>;
using RMatrixRef = Eigen::Ref<const RMatrix>;
using RVectorRef = Eigen::Ref<const RVector>;

class RMatrixWrapper {
	private:
		RMatrix data;

	public:
		RMatrix& get() {return data;}

		const RMatrix& get() const {return data;}
};

struct RMatrixRefWrapper {
	const RMatrixRef data;

	template<typename MatType>
	RMatrixRefWrapper(const MatType& mat_) : data(mat_) {}
};

struct RVectorRefWrapper {
	const RVectorRef data;

	template<typename VecType>
	RVectorRefWrapper(const VecType& mat_) : data(mat_) {}
};

struct LInterp2Data {
	const RMatrixRef& values;
	const RVectorRef& grid0, grid1;

	LInterp2Data(const RMatrixRef& values_,
		const RVectorRef& grid0_, const RVectorRef& grid1_)
		: values(values_), grid0(grid0_), grid1(grid1_) {}
};

#endif