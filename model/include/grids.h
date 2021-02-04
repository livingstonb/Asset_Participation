#ifndef GRIDS_HEADER
#define GRIDS_HEADER

class RVectorWrapper;

class Grids {
	public:
		Grids();

		int n_sf, n_se, n_y;

		std::unique_ptr<RVectorWrapper> se, sf, returns;
};

#endif