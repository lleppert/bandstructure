# bandstructure
scripts for plotting VASP bandstructures, calculating effective masses, etc.

bands_general.sh works with conf_bands. The necessary input files are a VASP .xml file and two output files from
the p4v bandstructure plot program. The first output file is from a nonrelativistic calulcation

${molecule}_${metal}_${func}_bands_all.dat

and the second from a calculation including SOC

${molecule}_${metal}_${func}_SOC_bands_all.dat

Beware, plots only the dominant orbital contribution
