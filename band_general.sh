#!/bin/bash

#plots bandstructure from p4v output, the dominant orbital contributions are
#plotted using different color gradients
#for tetragonal MAPbI3

#input parameters
. ./conf_bands

#split output of p4v
nbands=$(grep -oP '(?<=  <i type="int" name="NBANDS">   )[0-9]+' vasprun_${molecule}_${metal}_${func}_SOC_bands.xml)
blocksize=`expr $nbands \* $kpoints + $nbands`
blocksize=`expr $blocksize \* $spin`
awk -v bs=$blocksize 'NR%bs==1 {x="'${molecule}_${metal}_${func}_SOC_bands_'" ++i;}{print>x}' ${molecule}_${metal}_${func}_SOC_bands_all.dat
#define special k-points for (pseudo)cubic lattice (G-X-M-R-G)
gpoint1=$(awk 'NR==0 {print $1}' ${molecule}_${metal}_${func}_SOC_bands_1)
apoint=$(awk 'NR==30 {print $1}' ${molecule}_${metal}_${func}_SOC_bands_1)
xpoint=$(awk 'NR==60 {print $1}'  ${molecule}_${metal}_${func}_SOC_bands_1)
zpoint=$(awk 'NR==90 {print $1}' ${molecule}_${metal}_${func}_SOC_bands_1)
gpoint2=$(awk 'NR==120 {print $1}' ${molecule}_${metal}_${func}_SOC_bands_1)
rpoint=$(awk 'NR==150 {print $1}' ${molecule}_${metal}_${func}_SOC_bands_1)
mpoint=$(awk 'NR==180 {print $1}' ${molecule}_${metal}_${func}_SOC_bands_1)
#remove empty lines
sed '/^$/d' ${molecule}_${metal}_${func}_SOC_bands_2 > tmp.dat
sed '/^$/d' ${molecule}_${metal}_${func}_SOC_bands_3 > tmp2.dat
sed '/^$/d' ${molecule}_${metal}_${func}_SOC_bands_4 > tmp3.dat
#normalize data, so that max value of orbital contributions column is 1
awk -vmax2=$(awk 'BEGIN {max2=0} {if ($3>max2) max2=$3} END {print max2}' tmp.dat) '{print $1,$2,$3/max2}' tmp.dat > ${molecule}_${metal}_${func}_SOC_bands_2
awk -vmax3=$(awk 'BEGIN {max3=0} {if ($3>max3) max3=$3} END {print max3}' tmp2.dat) '{print $1,$2,$3/max3}' tmp2.dat >  ${molecule}_${metal}_${func}_SOC_bands_3
awk -vmax4=$(awk 'BEGIN {max4=0} {if ($3>max4) max4=$3} END {print max4}' tmp3.dat) '{print $1,$2,$3/max4}' tmp3.dat > ${molecule}_${metal}_${func}_SOC_bands_4
#put everything in the same file
paste <(awk '{print $1,$2,$3}' "${molecule}_${metal}_${func}_SOC_bands_2") <(awk '{print $3}' "${molecule}_${metal}_${func}_SOC_bands_3") <(awk '{print $3}' "${molecule}_${metal}_${func}_SOC_bands_4") > tmp4.dat
#determine max contribution for each line and print into separate column, values between 0 and 1 mean metal p or d, 1 and 2 metal s and 2 and 3 I p
awk '{
   max=0; maxindex=0;
   for (i=3; i<=NF; i++)
   {
    if ($i>max){
       maxindex=i;
       max=$i;
       }
   }
   {
   if (maxindex==3){
     print $1,$2,$3,$4,$5,max;
   } else if (maxindex==4){
     print $1,$2,$3,$4,$5,max+1;
   } else if (maxindex==5){
     print $1,$2,$3,$4,$5,max+2;
   } else {
     print $1,$2,$3,$4,$5,0;
   }
   }
}' tmp4.dat > ${molecule}_${metal}_${func}_SOC_bands
#insert empty lines again
awk -v kp=$kpoints '{if ((NR%kp)==1) printf("\n"); print; }' ${molecule}_${metal}_${func}_SOC_bands > ${molecule}_${metal}_${func}_SOC_bands_max
#remove first line
sed -i '/./,$!d' ${molecule}_${metal}_${func}_SOC_bands_max
#plot
gnuplot << EOF
set term epslatex color
set size 0.8, 1
set output "./evgauss.tex"
set format "$%g$"
unset xlabel
set title 'band structure $func $molecule $metal I_3'
set ylabel 'E - E_F (eV)'
set yrange [-4:6]
set style line 1 lw 4 lt 12 lc rgb "red"
set style line 2 lw 2 lt 1 lc rgb "grey"
set style line 3 lw 2 lt 2 lc rgb "black"
set style line 4 lw 2 lt 2 lc rgb "black"
set style line 5 lw 4 lt 13 lc rgb "violet"
set style line 6 lw 4 lt 14 lc rgb "green"
set xtics ("G" 0, "A" $apoint, "X" $xpoint, "Z" $zpoint, "G" $gpoint2, "R" $rpoint, "M" $mpoint)
set arrow from $apoint, graph(0,0) to $apoint, graph(1,1) nohead ls 3
set arrow from $xpoint, graph(0,0) to $xpoint, graph(1,1) nohead ls 3
set arrow from $zpoint, graph(0,0) to $zpoint, graph(1,1) nohead ls 3
set arrow from $gpoint2, graph(0,0) to $gpoint2, graph(1,1) nohead ls 3
set arrow from $rpoint, graph(0,0) to $rpoint, graph(1,1) nohead ls 3
f(x)=0
unset key
set cbrange [0:3.0]
set cbtics ("$metal $contvar" 0.5, "$metal $conts" 1.5, "I $contp" 2.5)
set palette defined (0 "black", 0.01 "#adff2f", 1.0 "#355e3b", 1.01 "#fbab60", 2.0 "red", 2.01 "#89cff0", 3.0 "blue")
plot "${molecule}_${metal}_${func}_bands_all.dat" using 1:2 notitle w l ls 2,\
"${molecule}_${metal}_${func}_SOC_bands_max" using 1:2:6 notitle w l lw 3 lt 1 lc palette z,\
f(x) notitle w l ls 4
EOF
latex evgauss2.tex
dvips evgauss2.dvi
mv evgauss2.ps ${molecule}_${metal}_${func}_bands.ps
okular ${molecule}_${metal}_${func}_bands.ps

#remove tmp files and backup files
rm -f tmp.dat tmp2.dat tmp3.dat tmp4.dat
find ./ -name '*~' | xargs rm
