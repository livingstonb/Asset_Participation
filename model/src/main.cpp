
// #include <interpolation.h>
// #include <eigen_interface.h>
#include <iostream>
#include <Parameters.h>
#include <Grids.h>
#include <Bellman.h>
#include <functions.h>

int main() {
	Parameters p;
	Grids grids;
	Bellman model(p, grids);

	model.solve();

	print_vec(grids.y);

	return 0;
}