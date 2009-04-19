#!/bin/bash

echo -n "build starts at "
date

absolute_dir () {
	local D
	D=$(dirname $1)
	echo "`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`"
}

retry () {
	# default retry = 10
	t=$2
	[[ x$t = x ]] && t=10
	expr=$1
	$expr && return
	for (( i=1; $i < $t; i=$i+1)); do
		echo retry = $i
		$expr && return
		echo failed.  sleep for 10 minutes.
		sleep 600
	done
}

OEDIR=$(absolute_dir $0)
RSYNC_TARGET=
LOCK_FILE=${OEDIR}/build-lock

if [ -f ${LOCK_FILE} ] ; then
	echo "Aborted due to already running build.sh"
	exit 10
fi

trap "rm ${LOCK_FILE}" EXIT

touch ${LOCK_FILE}

build() {
       echo "Runing build - ${OM_FEED} ${DISTRO_KERNEL}"
       ####################################################################################
       ## this is a bad hack that needs patching upstream
       patch -N -p0 < paroli.patch 
       patch -N -p0 < openocd.patch 
       ## end bad hack
       ####################################################################################

       retry "bitbake -c fetch ${DISTRO_KERNEL}"
       retry "bitbake -c fetch fso-image"

       ####################################################################################
       ## this is a bad hack that needs patching upstream
       if [ ${OM_FEED} = "experimental" ]; then
	   case ${MACHINE} in
	       om-gta01 ) 
                   ;;
	       om-gta02 ) 
		   patch -N -p0 < om-gta02_conf.patch
		   bitbake xf86-video-glamo ;;
	   esac
       fi
       ## end bad hack
       ####################################################################################

       bitbake -c rebuild linux-openmoko-stable
       bitbake -c rebuild linux-openmoko-devel
#       bitbake -c rebuild ${DISTRO_KERNEL}
       bitbake -c buildall fso-image-nox
       bitbake -c buildall fso-paroli-image
       bitbake -c buildall fso-image 
       bitbake -c buildall fso-console-image
       bitbake -c buildall fso-illume-image
       bitbake -c buildall fso-image-light
       bitbake -c buildall -k task-openmoko-feed
       bitbake -c rebuild u-boot-openmoko
       bitbake -c rebuild qi
}

post_build () {
	true
}

#### include config file to overwrite ####

. ${OEDIR}/build.env


cd ${OEDIR}/openembedded
git checkout -f org.openembedded.dev
git pull 
cd ${OEDIR}

###########################################################################
###########################################################################
# These hacks need to be removed as the patches go upstream

###########################################################################
###########################################################################
 
touch ${OEDIR}/local/conf/local.conf

# remove any old workdirs file
rm ${TMPDIR}/workdirs.txt || true

for OM_FEED in ${OM_FEED_TARGET}
do
        cd ${OEDIR}/openembedded 

        case ${OM_FEED} in
	    testing )
	        echo "Setting up testing build environment"
#		git checkout -b openmoko-testing ${TESTING_BRANCH}
	        git checkout -f org.openembedded.dev
		git reset --hard org.openembedded.dev
		git checkout ${TESTING_BRANCH}
		git reset --hard ${TESTING_BRANCH}
		export DISTRO_KERNEL=${TESTING_KERNEL} ;;

	    unstable )
	        echo "Setting up unstable build environment"
#		git checkout -b openmoko-unstable ${UNSTABLE_BRANCH}
	        git checkout -f org.openembedded.dev
		git reset --hard org.openembedded.dev
		git checkout ${UNSTABLE_BRANCH}
		git reset --hard ${UNSTABLE_BRANCH}
		export DISTRO_KERNEL=${UNSTABLE_KERNEL} ;;

	    experimental )
	        echo "Setting up experimental build environment"
#		git checkout -b openmoko-experimental ${EXPERIMENTAL_BRANCH}
	        git checkout -f org.openembedded.dev
		git reset --hard org.openembedded.dev
		git checkout ${EXPERIMENTAL_BRANCH}
		git reset --hard ${EXPERIMENTAL_BRANCH}
		export DISTRO_KERNEL=${EXPERIMENTAL_KERNEL} ;;
	esac

	export OM_FEED
	cd ${OEDIR}

        for MACHINE in ${MACHINE_TARGET}
	do
	        export BBPATH="${OEDIR}/${MACHINE}-${OM_FEED}-meta:${OEDIR}/local:${OEDIR}/openembedded"
		export MACHINE
		set +xe
		build
		set -xe
	done
done

bitbake package-index

post_build

rm ${LOCK_FILE}

echo -n "build ends at "
date


