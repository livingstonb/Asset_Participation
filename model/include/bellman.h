#ifndef BELLMAN_HEADER
#define BELLMAN_HEADER

// Just pass a function pointer to C++?
// Or do the whole thing in C++

// First, given c, do a grid search. Then, check if a corner is optimal.
// If not, use solver.

#include <memory>

class Parameters;

class Grids;

class BellmanImpl;

class Bellman {
	private:
		BellmanImpl* impl = nullptr;

	public:
		Bellman(const Parameters& p, const Grids& grids);

		~Bellman();

		void solve();
};

// double value(const arma::vec& z, arma::vec* grad, void* args) {
//  	// Computes the value associated with a given control vector.
//  	//
// 	// s = z[0]
// 	// q_b = z[1]
// 	// q_e = z[2]

// 	double c, u, m, sf, se;
// 	const Bellman bellman* = (Bellman *) args;

// 	c = bellman->xcurr - z[0];
// 	m = (1 - z[1] - z[2]) * z[0];
// 	sf = m + z[1] * z[0] * args->Rb;
// 	se = z[2] * z[0];

// 	u = bellman->utility(c, m);
// 	ev = bellman->continuation_value(sf, se, args->ycurr);
	
// 	return u + ev;
// }

#endif