#include <grids.h>
#include <eigen_interface.h>

Grids::Grids() {
	sf.reset(new RVectorWrapper());
	se.reset(new RVectorWrapper());
	returns.reset(new RVectorWrapper());
}