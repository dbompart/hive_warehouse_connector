#!/bin/bash
file=$1
Managed=$2
#Remove all table borders
sed -i "s/|//g" $1
sed -i "/+-*+$/d" $1
#Remove all "createtab_stmt" headers
sed -i "/createtab_stmt/d" $1
#Remove all after LOCATION
if [ $Managed == "--clean"  ]; then
	sed -i '/LOCATION/,$d' $1
fi
cat $1

echo -e  "\nUse ./command file --clean, to remove the TBLProperties and Location\n"
