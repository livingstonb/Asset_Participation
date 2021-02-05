# SIPP

## Required inputs

We use waves 1-4 of the 2014 SIPP. These are large files named *pu2014w#.dta*, which can be split into chunks and compressed with the *build/code/read_sipp.do* do-file. This do-file should be passed the wave number of the raw dataset to be processed, e.g. `do "build/code/do/read_sipp.do" 2` for wave 2.

* *build/input/pu2014w1.dta*
* *build/input/pu2014w2.dta*
* *build/input/pu2014w3.dta*
* *build/input/pu2014w4.dta*

The raw datasets can then be deleted and one can use the following files, produced with the command described above:

* *build/input/sipp_raw_w1.dta*
* *build/input/sipp_raw_w2.dta*
* *build/input/sipp_raw_w3.dta*
* *build/input/sipp_raw_w4.dta*
