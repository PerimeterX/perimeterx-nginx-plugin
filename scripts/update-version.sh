#!/usr/bin/env bash

set -e

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
base_dir=${dir}/..
ver=$1

if [[ -z "${ver}" ]]; then
    echo "No version specified, exiting."
    exit 1
fi

old_ver=`cat ${base_dir}/VERSION`
escaped_old_ver=$(sed "s/\./\\\./g" <<< ${old_ver})
escaped_ver=$(sed "s/\./\\\./g" <<< ${ver})
old_ver_2=$(sed 's/\./-/2' <<< ${old_ver})
escaped_old_ver_2=$(sed 's/\./-/2' <<< ${escaped_old_ver})
#echo "$escaped_old_ver_2"
escaped_ver_2=$(sed 's/\./-/2' <<< ${escaped_ver})
#echo "$escaped_ver_2"

sed -i.bak "s/$escaped_old_ver/$escaped_ver/g" ${base_dir}/lib/px/utils/pxconstants.lua
sed -i.bak "s/$escaped_old_ver/$escaped_ver/g" ${base_dir}/perimeterx-nginx-plugin-${old_ver_2}.rockspec
sed -i.bak "s/$escaped_old_ver_2/$escaped_ver_2/g" ${base_dir}/perimeterx-nginx-plugin-${old_ver_2}.rockspec
mv ${base_dir}/perimeterx-nginx-plugin-${old_ver_2}.rockspec ${base_dir}/perimeterx-nginx-plugin-${ver_2}.rockspec
sed -i.bak "s/$escaped_old_ver/$escaped_ver/g" ${base_dir}/README.md
sed -i.bak "s/$escaped_old_ver_2/$escaped_ver_2/g" ${base_dir}/README.md
echo "$ver" > ${base_dir}/VERSION

echo "version updated to $ver"
echo "please update CHANGELOG.md and README.md with new version details"