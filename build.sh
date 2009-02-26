#!/bin/bash

echo -n "build starts at "
date

trap "rm ${LOCK_FILE}" EXIT

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

touch ${LOCK_FILE}

build() {
       echo "Runing build - ${OM_FEED} ${DISTRO_KERNEL}"
       ####################################################################################
       ## this is a bad hack that needs patching upstream
       patch -N -p0 < element.patch 
       patch -N -p0 < bluez4.patch 
       patch -N -p0 < srcrev.patch 
       patch -N -p0 < paroli.patch 
       patch -N -p0 < devel.patch 
       patch -N -p0 < stable.patch 
       ## end bad hack
       ####################################################################################

       retry "bitbake -c fetch ${DISTRO_KERNEL}"
       retry "bitbake -c fetch fso-image"

       ####################################################################################
       ## this is a bad hack that needs patching upstream
       if [ ${OM_FEED} = "experimental" ]; then
	   case ${MACHINE} in
	       om-gta01 ) 
                   sed -i "s|2.6.28|2.6.29-rc3|" ${OEDIR}/openembedded/packages/linux/linux-openmoko-devel_git.bb  
                   sed -i "s|gta02-packaging-defconfig|gta01_moredrivers_defconfig|" ${OEDIR}/openembedded/packages/linux/linux-openmoko-devel_git.bb  
		   sed -i "s|gta02_packaging_defconfig|gta01_moredrivers_defconfig|" ${OEDIR}/openembedded/packages/linux/linux-openmoko-devel_git.bb
		   sed -i "s|file://openwrt-ledtrig-netdev.patch;patch=1||" ${OEDIR}/openembedded/packages/linux/linux-openmoko-devel_git.bb ;;
	       om-gta02 ) 
                   sed -i "s|2.6.28|2.6.29-rc3|" ${OEDIR}/openembedded/packages/linux/linux-openmoko-devel_git.bb  
                   sed -i "s|gta01_moredrivers_defconfig|gta02_packaging_defconfig|" ${OEDIR}/openembedded/packages/linux/linux-openmoko-devel_git.bb  
		   sed -i "s|gta02-packaging-defconfig|gta02_packaging_defconfig|" ${OEDIR}/openembedded/packages/linux/linux-openmoko-devel_git.bb
		   sed -i "s|file://openwrt-ledtrig-netdev.patch;patch=1||" ${OEDIR}/openembedded/packages/linux/linux-openmoko-devel_git.bb
		   bitbake xf86-video-glamo ;;
	   esac
       fi
       ## end bad hack
       ####################################################################################

       bitbake -c rebuild ${DISTRO_KERNEL}
       bitbake linux-openmoko-2.6.24
       bitbake linux-openmoko-2.6.28
#       bitbake -c rebuild linux-openmoko-2.6.24
#       bitbake -c rebuild linux-openmoko-2.6.28
#       bitbake -c rebuild linux-openmoko-devel
#       bitbake -c rebuild linux-openmoko-stable
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

print_mail () {
#	IMAGENAME="$(basename $(readlink openmoko-devel-image-om-gta02.jffs2))"
	echo build finished on $(date)
	echo
	echo get the latest u-boot from
	echo http://buildhost.openmoko.org/daily/neo1973/deploy/glibc/images/neo1973/$(basename $(readlink uboot-gta02v5-latest.bin))
	echo
	echo get the latest kernel from
	echo http://buildhost.openmoko.org/daily/neo1973/deploy/glibc/images/neo1973/$(basename $(readlink uImage-om-gta02-latest.bin))
	echo
	echo get the latest rootfs from
	echo http://buildhost.openmoko.org/daily/neo1973/deploy/glibc/images/neo1973/${IMAGENAME}
#	echo
#	echo the list of installed packages:
#	cat "$(echo ${IMAGENAME} | sed -e 's/.rootfs.jffs2//')-testlab/list-installed.txt"
}

#post_build () {
#	#rsync -a --delete /space/fic/openmoko-daily/sources /space/www/buildhost
#	#pushd ${TMPDIR}/deploy/glibc/images/neo1973/
#	TMPFILE=$(tempfile -d ${TMPDIR})
#	print_mail >> ${TMPFILE}
#	mail -s "buildhost notification: $(date +%Y%m%d)" nytowl@openmoko.org < ${TMPFILE}
#	rm ${TMPFILE}
#	#popd
#}

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

echo -n "build ends at "
date

rm ${LOCK_FILE}

