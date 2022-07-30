#!/bin/bash
#******************************************************************************#
#                            D E S C R I P T I O N                             #
#******************************************************************************#
# This script is used to stop and start an IIB application. This script takes  #
# three parameters as an input.                                                #
# $1 - Indicates the action to be done i.e., stop or start                     #
# $2 - Indicates the name of integration server containing the application     #
# $3 - Indicates the name of the application                                   #
#                                                                              #
#******************************************************************************#
#                          C H A N G E  C O N T R O L                          #
#******************************************************************************#
# Date   Name                   Change                                         #
# ------ ------------ ---------------------------------------------------------#
# 121819 mojahidam@gmail.com    Initial release                                #
#******************************************************************************#

#******************************************************************************#
#                            P R O C E D U R E S                               #
#******************************************************************************#

errorexit()
{

  #This procedure takes one parameters:
  #$1 - This indicates the exit code to set

  logit "ERROR" "Script ended with exit code $1"

  exit $1
}


warnexit()
{

  #This procedure takes one parameters:
  #$1 - This indicates the exit  code to set

  logit "WARN" "Script ended with exit code $1"

  exit $1
}

logit()
{

  #This procedure takes two parameters:
  #$1 - is the error level
  #$2 - is additional information for the error or information tag

  #Get error message from error file
  errmsg=$2
  errlvl=$1

  echo  "`date '+%b %d %T'` [$errlvl] $0 :: $errmsg" >> $LOGFILE

  #******************************************************************************#
  # Put the logit information out to syslog
  #******************************************************************************#
  logger -i -s "[$errlvl] $0 :: $errmsg"

}

usage()
{
  echo ""
  echo "Usage: $0 [start|stop] [integration server name] [application name]"
  echo ""
  errorexit 1
}

checkNodeStatus()
{
  nodelist=`mqsilist | grep \'$IIBNODE\'`
  if [ $? -ne 0 ];then
    logit "ERROR" "Integration node '$IIBNODE' not found"
    return 2
  fi
  echo $nodelist | grep running
  if [ $? = 0 ];then
    logit "INFO" "Integration node '$IIBNODE' is running"
    return 0
  fi
  echo $nodelist | grep stopped
  if [ $? = 0 ];then
    logit "INFO" "Integration node '$IIBNODE' is stopped"
    return 1
  fi
}

checkIntegrationServerStatus()
{
  eglist=`mqsilist $IIBNODE | grep \'$EG\'`
  if [ $? -ne 0 ];then
    logit "ERROR" "Integration server '$EG'  not found"
    return 2
  fi  
  echo $eglist | grep running
  if [ $? = 0 ];then
    logit "INFO" "Integration server '$EG' is running"
    return 0
  fi
  echo $eglist | grep stopped
  if [ $? = 0 ];then
    logit "INFO" "Integration server '$EG' is stopped"
    return 1
  fi
}

checkApplicationStatus()
{
  applist=`mqsilist $IIBNODE -e $EG | grep \'$APP\'`
  if [ $? -ne 0 ];then
    logit "ERROR" "Application '$APP' not found"
    return 2
  fi
  echo $applist | grep running
  if [ $? = 0 ];then
    logit "INFO" "Application '$APP' is running"
    return 0
  fi
  echo $applist | grep stopped
  if [ $? = 0 ];then
    logit "INFO" "Application '$APP' is stopped"
    return 1
  fi
}

startApplication()
{
  mqsistartmsgflow $IIBNODE -e $EG -k $APP
  ec=$?
  if [ $ec = 0 ];then
    logit "INFO" "Application '$APP' started successfully"
  elif [ $ec = 2 ];then
    logit "ERROR" "The integration node received the deployment request but was unable to process it successfully. See the messages issued from the utility (or the Administration log) for more information."
  elif [ $ec = 9 ];then
    logit "ERROR" "The request has been submitted to the integration node, but no response was received before the timeout expired."
  elif [ $ec = 10 ];then
    logit "ERROR" "Another user or application canceled the request operation before the integration node was able to process it."
  elif [ $ec = 98 ];then
    logit "ERROR" "The integration node is not running."
  elif [ $ec = 99 ];then
    logit "ERROR" "One or more of the parameters that you specified is invalid."
  else
    logit "ERROR" "Unknown exit code $ec"
  fi
  return $ec
}

stopApplication()
{
  mqsistopmsgflow $IIBNODE -e $EG -k $APP
  ec=$?
  if [ $ec = 0 ];then
    logit "INFO" "Application '$APP' stopped successfully"
  elif [ $ec = 2 ];then
    logit "ERROR" "The integration node received the deployment request but was unable to process it successfully. See the messages issued from the utility (or the Administration log) for more information."
  elif [ $ec = 9 ];then
    logit "ERROR" "The request has been submitted to the integration node, but no response was received before the timeout expired."
  elif [ $ec = 10 ];then
    logit "ERROR" "Another user or application canceled the request operation before the integration node was able to process it."
  elif [ $ec = 98 ];then
    logit "ERROR" "The integration node is not running."
  elif [ $ec = 99 ];then
    logit "ERROR" "One or more of the parameters that you specified is invalid."
  else
    logit "ERROR" "Unknown exit code $ec"
  fi
  return $ec
}

#******************************************************************************#
#                         I N I T I A L I Z A T I O N                          #
#******************************************************************************#

# Set Variables
date=`date +%Y%m%d`
rootdir=/var/mqsi
admdir=$rootdir/admin
logdir=$admdir/logs
logfileName="${0##*/}"
LOGFILE=$logdir/$logfileName.log.$date
ACTION=$1
EG=$2
APP=$3

logit "INFO" "Script started"

# Check parameters to make sure that they are valid
if [ $# -ne 3 ];then
  logit "ERROR" "Invalid number of arguments"
  usage 
fi
echo "$1" | grep '?'
if [ $? = 0 ];then
   usage
fi

#******************************************************************************#
#                               M A I N  B O D Y                               #
#******************************************************************************#

checkNodeStatus
ec=$?
if [ $ec = 1 ];then
  logit "ERROR" "Please ensure that integration node '$IIBNODE' is running before invoking script"
  errorexit 1
elif [ $ec = 2 ];then
  logit "ERROR" "Integration node '$IIBNODE' is not defined"
  errorexit 1
fi

case $ACTION in
start)
  logit "INFO" "About to start application '$APP' on integration server '$EG'"
  logit "INFO" "Verifying status of integration server '$EG'"
  checkIntegrationServerStatus
  ec=$?
  if [ $ec = 0 ];then
    logit "INFO" "Verifying status of application '$APP'"
    checkApplicationStatus
    ec=$?
    if [ $ec = 1 ];then
      logit "INFO" "Starting application '$APP' on integration server '$EG'"
      startApplication
    elif [ $ec = 0 ];then
      logit "WARN" "Application '$APP' is already running"
      warnexit 2
    elif [ $ec = 2 ];then
      logit "ERROR" "Please ensure that application name '$APP' is correct"
      errorexit 1
    fi
  elif [ $ec = 1 ];then
    logit "ERROR" "Please ensure that integration server '$EG' is running before issuing start action"
    errorexit 1
  elif [ $ec = 2 ];then
    logit "ERROR" "Please ensure that integration server name '$EG' is correct"
    errorexit 1
  fi
;;

stop)
  logit "INFO" "About to stop application '$APP' on Integration Server '$EG'"
  logit "INFO" "Verifying status of integration server '$EG'"
  checkIntegrationServerStatus
  ec=$?
  if [ $ec = 0 ];then
    logit "INFO" "Verifying status of application '$APP'"
    checkApplicationStatus
    ec=$?
    if [ $ec = 0 ];then
      logit "INFO" "Stopping application '$APP' on integration server '$EG'"
      stopApplication
    elif [ $ec = 1 ];then
      logit "WARN" "Application '$APP' is already stopped"
      warnexit 2
    elif [ $ec = 2 ];then
      logit "ERROR" "Please ensure that application name '$APP' is correct"
      errorexit 1
    fi
  elif [ $ec = 1 ];then
    logit "ERROR" "Please ensure that integration server '$EG' is running before issuing start action"
    errorexit 1
  elif [ $ec = 2 ];then
    logit "ERROR" "Please ensure that integration server name '$EG' is correct"
    errorexit 1
  fi
;;

*)
  logit "ERROR" "Action supplied is invalid"
  usage
;;

esac
logit "INFO" "Script ended successfully"
exit 0
