#!/bin/bash
# brought up to BASH 4 conventions by Michael Hirsch mhirsch@bu.edu
# original by Matt Zettergren 

runTranscar()
{
[[ -z $1 ]] && { echo "error: must specify root directory e.g. ./run_beams ../BT"; exit 1; } 

set +e #don't stop on error unless I direct it to

#not necessary
#http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in 
#TDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" 

ODIR=$1
TClog=$ODIR/transcarBash.log

#check for unused output dir
[[ ! -d "$ODIR" ]] && { echo "Energy directory $ODIR does not exist" | teea $TClog; exit 98; }

#mkdir -pv $ODIR/dir.input $ODIR/dir.output |& teea $TClog

# here are files generated by Fortran code
#TCoutFN=(transcar_output emissions.dat ediffnumflux.dat)

#copy transcar input
cp -v -t "$ODIR/dir.input/" dir.input/DATCAR dir.input/90kmmaxpt123.dat |& teea $TClog
cp -v -t "$ODIR/dir.data/" dir.data/type |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.geomag" dir.data/dir.linux/dir.geomag/data_geom.bin |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.geomag" dir.data/dir.linux/dir.geomag/igrf90.dat |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.geomag" dir.data/dir.linux/dir.geomag/igrf90s.dat |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.projection/" dir.data/dir.linux/dir.projection/varpot.dat |& teea $TClog
#cp -v -t "$ODIR/dir.data/dir.linux/dir.projection/" dir.data/dir.linux/dir.projection/varcourant.dat |& teea $TClog  #makes program crash
cp -v -t "$ODIR/dir.data/dir.linux/dir.cine/" dir.data/dir.linux/dir.cine/DATDEG |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.cine/" dir.data/dir.linux/dir.cine/DATFEL |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.cine/" dir.data/dir.linux/dir.cine/DATTRANS |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.cine/" dir.data/dir.linux/dir.cine/FELTRANS |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.cine/" dir.data/dir.linux/dir.cine/flux.flag |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.cine/dir.euvac" dir.data/dir.linux/dir.cine/dir.euvac/EUVAC.dat |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.cine/dir.seff" dir.data/dir.linux/dir.cine/dir.seff/crsb8 |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.cine/dir.seff" dir.data/dir.linux/dir.cine/dir.seff/crsphot1.dat |& teea $TClog
cp -v -t "$ODIR/dir.data/dir.linux/dir.cine/dir.seff" dir.data/dir.linux/dir.cine/dir.seff/rdtb8 |& teea $TClog

#copy transcar itself
cp -v transconvec_13.op.out "$ODIR/"

#Cleaning up any partially completed simulations
#for outFN in "${TCoutFN[@]}"; do
# currFN="dir.output/$outFN"
# [[ -f $currFN ]] && { rm -v "$currFN" |& teea $TClog }
#done

# run TRANSCAR
#echo "RUN_TRANSCAR.SH: transconvec_13.op is running"
#time strace -e trace=open transconvec_13.op.out | tee $PWD/bid
#time transconvec_13.op.out | tee $PWD/bid | egrep -A3 -e "*******|Error|felin.f"
#time transconvec_13.op.out > $PWD/bid & tail -f $PWD/bid | egrep --line-buffered -A3 -e "*******|Error|felin.f"

#must have /usr/bin/time to use the system time command, as bash time command won't accept arguments!
# egrep --line-buffered is necessary to avoid annoying random line truncations while waiting for stdout to fill!
#/usr/bin/time --output="$ODIR/timing.txt" ./transconvec_13.op.out | \


# exec used to reduce memory usage http://stackoverflow.com/questions/786376
 (cd $ODIR && exec ./transconvec_13.op.out) |& teea $ODIR/TranscarErrors.txt
    # egrep -i --line-buffered -e "Warning|Error|felin.f|trans.f|Input eV/cm2/s" | \
      


# Copying data files to output directory $ODIR
#for outFN in ${TCoutFN[@]}; do
# cp -v "dir.output/$outFN" "$ODIR/" |& teea $TClog
#done

}

teea ()
{
tee --append "$1" #by default, tee overwrites
}

noMore ()
{
echo "run_transcar: aborting on user request Ctrl C" | teea $TClog
return 99
}

trap noMore SIGINT

#now run the transcar function, passing the output directory 
runTranscar $1

