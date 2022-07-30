#!/bin/bash
#******************************************************************************#
#                            D E S C R I P T I O N                             #
#******************************************************************************#
# This script is used to list all Integration Servers and Applications         #
# deployed on all running Integration Nodes. This will create a file named     #
# apps_list.txt.YYYY-MM-DD-HHMMss that will contain the results.               #
# This script takes no parameter input.                                        #
#                                                                              #
#******************************************************************************#
#                          C H A N G E  C O N T R O L                          #
#******************************************************************************#
# Date   Name                   Change                                         #
# ------ ------------ ---------------------------------------------------------#
# 022618 mojahidam@gmail.com    Initial release                                #
#******************************************************************************#

#******************************************************************************#
#                            P R O C E D U R E S                               #
#******************************************************************************#

#******************************************************************************#
#                         I N I T I A L I Z A T I O N                          #
#******************************************************************************#

date=`date +%Y-%m-%d-%H%M%S`
file_name=apps_list.txt.$date

#******************************************************************************#
#                               M A I N  B O D Y                               #
#******************************************************************************#

echo "##########" > $file_name
echo "Listing Integration Nodes"
mqsilist >> $file_name
echo >> $file_name
echo >> $file_name
mqsilist | grep -o "node.*" | cut -f2 -d \' | while read brkr; do
        echo "Listing Integration Servers in Integration Node: $brkr"
        echo "##########$brkr##########" >> $file_name
        echo >> $file_name
        mqsilist $brkr >> $file_name
        echo >> $file_name
        echo >> $file_name
        mqsilist $brkr | grep -o "server.*" | cut -f2 -d \' | while read eg ; do
                echo "Listing Applications deployed in Integration server: $eg"
                echo "**********$eg**********" >> $file_name
                mqsilist $brkr -e $eg -d 2 >> $file_name
                echo >> $file_name
                echo >> $file_name
        done
done