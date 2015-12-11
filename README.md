# parastructure

parastructure is a perl script collection to run the population genetics software STRUCTURE from Pritchard et al. 2000 (http://pritch.bsd.uchicago.edu/structure.html ) in parallel on a cluster (beowulf type). Each run of K (the number of populations) is executed separately on each CPU of the cluster trough queue system based on PBS. A summary statistics table and distruct figures (Noah Rosenberg: http://www.stanford.edu/group/rosenberglab/distruct.html ) are built at the end of the run. A patch for the structure (ran.c) is also provided in order to correct the generation of the seed number.

Keywords: population genetics, Structure, HPC, beowulf cluster

This project is licensed under the terms of the MIT license.
Copyright (c) 2015 Lagnel Jacques

