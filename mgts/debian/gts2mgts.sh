#!/bin/bash

root=debian/tmp

libdir=$(find ${root} -name "libgts.la" -printf "%h")

old_dlname=$(grep dlname ${libdir}/libgts.la | cut -d"'" -f2)
dlname=$(echo ${old_dlname} | sed 's/gts/mgts/g')

function fix_dt_needed() {
    echo "fixing DT_NEEDED in $1"
    patchelf --replace-needed ${old_dlname} ${dlname} ${1}
}

function fix_soname() {
    echo "fixing DT_SONAME in $1"
    patchelf --set-soname ${dlname} ${1}
}

function fix_filename() {
    file=${1}
    dst=$(echo ${file} | sed 's/gts/mgts/g')
    if [ ${file} = ${dst} ]; then
        dst=$(dirname ${file})/mgts-$(basename ${file})
    fi
    mv $file $dst
    if file -i ${dst} | grep -q application/x-sharedlib; then
        fix_dt_needed $dst
    fi

    if [ -h ${dst} ]; then
        link=$(readlink ${dst})
        dst_link=$(echo ${link} | sed 's/gts/mgts/g')
        if [ ${link} != ${dst_link} ]; then
            ln -sf ${dst_link} ${dst}
        fi
    fi
}

for file in ${root}/usr/bin/*; do
    fix_filename ${file}
done

for file in ${root}/usr/include/*; do
    fix_filename ${file}
done

sed -i 's/gtsconfig.h/mgtsconfig.h/g' ${root}/usr/include/mgts.h

old_lib=$(find ${libdir} -name ${old_dlname})

old_pkgconfig=$(find ${root} -name gts.pc)

sed -i -e 's/gts/mgts/g' -e 's/GTS/MGTS/g' \
    debian/tmp/usr/bin/mgts-config \
    ${libdir}/libgts.la \
    ${old_pkgconfig}

fix_soname ${old_lib}

for file in ${libdir}/*gts*; do
    fix_filename ${file}
done

fix_filename ${old_pkgconfig}
