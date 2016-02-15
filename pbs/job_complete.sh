#!/bin/bash

# The current job has to:
# 0) Job need to be run on scratch partition
#  * pre-defined environment
#    - $SCRATCH   : absolute path to scratch partition
#    - $PRODUCTS  : directory where job outputs are save inside Home partition
#    - $RESOURCES : directory with software and data to be used during job
#    - $OBSID     : Observation ID; input directory name
#    - $DMODE     : Observation data mode
#    - $POS_RA    : Object's RA position
#    - $POS_DEC   : Object's Dec position
#  - define the environment
#    - $WORKDIR   : directory inside $SCRATCH where the job is to be run
# 1) Install the Heasoft
#  - at $WORKDIR
#  - unpack heasoft tarball from $RESOURCES/software
#  - define $HEASDIR to the newly created heasoft directory
#  - untar xselect patch to '-C $HEASDIR'
#  - build the package
#    - cd into $HEASDIR/BUILD_DIR
#    - ./configure &> log.configure
#    - make &> log.make
#    - make install &> log.makeInstall
# 2) Install the Swift caldb (notice it is sufficient to copy the files)
#  - at $WORKDIR
#  - rsync $CALDB .
# 3) Copy the data to be processed
#  - at $WORKDIR
#  - rsync $RESOURCES/data/$OBSID .
# 4) Run the xrtpipeline
#  - necessary parameters:
#    - $OBSID
#    - $DMODE
#    - $POS_RA
#    - $POS_DEC
#    - $OUTDIR
# 5) Copy the output data to Home
#  - rsync $WORKDIR to $PRODUCTS

check_variable()
{ # '$1' is meant to be the variable name
    VAR="$1"
    [[ -z "${!VAR}" ]] && { >&2 echo "oops: $VAR variable not defined."; return 1; }
    return 0
}

check_file()
{
    FILE="$1"
    [[ ! -f "$FILE" ]] && { >&2 echo "oops: $FILE seems not to exist. Finishing."; return 1; }
    return 0
}

check_dir()
{
    DIR="$1"
    [[ ! -d "$DIR" ]] && { >&2 echo "oops: $DIR is not reachable. Finishing."; return 1; }
    return 0
}

pkg_config()
{
    LOG="${LOGDIR:-.}/logConfigure.txt"
    ./configure $@ > $LOG 2>&1
    [ "$?" -ne "0" ] && { echo "oops: Config failed. Look at $LOG file."; return 1; }
    return 0
}

pkg_make()
{
    LOG="${LOGDIR:-.}/logMake.txt"
    make > $LOG 2>&1
    [ "$?" -ne "0" ] && { echo "oops: Make failed. Look at $LOG file."; return 1; }
    return 0
}

pkg_install()
{
    LOG="${LOGDIR:-.}/logInstall.txt"
    make install > $LOG 2>&1
    [ "$?" -ne "0" ] && { echo "oops: Install failed. Look at $LOG file."; return 1; }
    return 0
}

exit_clean()
{
    rm -rf $TEMPDIR
    exit ${1:-0}
}

HOST=$(hostname -f)
echo "Host being used: $HOST"

missing_vars=()
check_variable SCRATCH || missing_vars+=('SCRATCH')
check_variable RESOURCES || missing_vars+=('RESOURCES')
check_variable PRODUCTS || missing_vars+=('PRODUCTS')
check_variable OBSID || missing_vars+=('OBSID')
check_variable POS_RA || missing_vars+=('POS_RA')
check_variable POS_DEC || missing_vars+=('POS_DEC')
check_variable DMODE || missing_vars+=('DMODE')
[ ${#missing_vars[@]} -ne "0" ] && { echo -e "Declare the variables we need:\n ${missing_vars[@]} \nCiao."; exit 1; }

JID=${PBS_JOBID%%.*}
WORKDIR="${SCRATCH}/work/$JID"
mkdir -p $WORKDIR || exit 1
echo "env: WORKDIR=$WORKDIR"
cd $WORKDIR
echo "cwd: $PWD"

TEMPDIR="$WORKDIR/tmp"
mkdir $TEMPDIR && cd $TEMPDIR

HEASOFT_TAR="$RESOURCES/software/heasoft-current.tgz"
echo -n "exe: unpack heasoft.."
check_file "$HEASOFT_TAR" && tar -xzf "$HEASOFT_TAR" || exit_clean 1
echo "done"
HEASOFT_ROOT=$(ls -1 | grep "heasoft")
HEASOFT_ROOT=${PWD}/$HEASOFT_ROOT
echo "env: HEASOFT_ROOT=$HEASOFT_ROOT"
XSELSRC="$RESOURCES/software/xselect-patch.tgz"
echo "exe: apply xselect-patch.."
check_file "$XSELSRC" && tar -xzvf "$XSELSRC" -C "$HEASOFT_ROOT" || exit_clean 1

cd "${HEASOFT_ROOT}/BUILD_DIR"
echo "cwd: $PWD"
LOGDIR="$WORKDIR/logs" && mkdir $LOGDIR
pkg_config && pkg_make && pkg_install 
[ "$?" -ne "0" ] && { echo "oops: Heasoft package building failed. Finishing."; exit_clean 1; }
eval `grep "^host=" config.log`
export HEADAS="${HEASOFT_ROOT}/$host"
echo "env: HEADAS=$HEADAS"
source ${HEADAS}/headas-init.sh || exit_clean 1
cd - > /dev/null

echo "cwd: $PWD"
CALDATA="$RESOURCES/caldb"
echo "exe: sync CALDB data.."
check_dir "$CALDATA" && rsync -a $CALDATA . || exit_clean 1
export CALDB="$PWD/caldb"
echo "env: CALDB=$CALDB"
source ${CALDB}/software/tools/caldbinit.sh || exit_clean 1

DATASRC="$RESOURCES/data/$OBSID"
check_dir $DATASRC && rsync -a $DATASRC . || exit_clean 1
INPUT="$PWD/$OBSID"

cd $WORKDIR
echo "cwd: $PWD"
OUTDIR="$PWD/output"
mkdir $OUTDIR || exit_clean 1
OUTPUT="$OUTDIR/${OBSID}_${DMODE}"
OUTLOG="$OUTDIR/logfile.txt"
OMODE="POINTING"
INSTEM="sw$OBSID"

BINLOC=$(which xrtpipeline) || exit_clean 1
echo "env: bin location: $BINLOC"

echo "define heasoft' parfiles dir.."
PFDIR="$TEMPDIR/pfiles"
[ ! -d "$PFDIR" ] && mkdir -p $PFDIR
export PFILES="${PFDIR};${HEADAS}/syspfiles"

echo "define non-interactive mode for heasoft.."
export HEADASNOQUERY=""
export HEADASPROMPT="/dev/null"

echo "define alternative history files location, xselect and ximage.."
export XSEL_HTY=$TEMPDIR
[ ! -f "$HOME/.ximagerc" ] && echo 'set ximage_history_file ""' > "$HOME/.ximagerc"

xrtpipeline datamode=$DMODE obsmode=$OMODE srcra="$POS_RA" srcdec="$POS_DEC" indir=$INPUT outdir=$OUTPUT steminputs=$INSTEM > $OUTLOG 2>&1

[ "$?" -ne "0" ] && >&2 echo "oops: xrtpipeline failed to run. Take a look at $OUTLOG inside $PRODUCTS/$JID."
mkdir $PRODUCTS/$JID
rsync -av $OUTDIR $PRODUCTS/$JID/.
exit_clean

