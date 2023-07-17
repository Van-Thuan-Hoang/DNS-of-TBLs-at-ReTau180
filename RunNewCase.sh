#!/bin/bash

function commandRun {
    echo "$1"
    echo "$1" > command.sh
    sleep 0.2
    source command.sh
}

function CompletationInf { 
   local inputFile="turbChannel.log.1"

   local n=1
   while read line; do

      subStr=${line:0:14}

      #echo "$subStr"

      if [ $n -ge 400 ]; then
         if [ "$subStr" = "run successful" ]; then
            echo "$subStr"
            completationFlag=1
         elif [ "$subStr" = "FILE:turbChann" ]; then
            #echo "$subStr"
            #echo "${line:19:24}"
            fileNum=${line:19:24}
         fi
      fi

      n=$((n+1))

   done < $inputFile
}

function EndTimeRead {
   local inputFile="turbChannel.par"

   local n=1 
   while read line; do
      #echo $n

      if [ $n -eq 11 ]; then
         len=${#line}
         #echo $len

         subStr=${line:10:$len}
         #echo "$subStr"

         newTime=$subStr

         return 
      fi

      n=$((n+1))

   done < $inputFile
}

function WriteSessionName {
   local caseName=$1
   local folder=$2    
   local startTime=$3
   echo "turbChannel" > SESSION.NAME
   lineStr="/hpcfs/users/a1739506/Nek5000/"$caseName"/"$folder$startTime"s/"
   echo $lineStr  >> SESSION.NAME
}

function WriteParFile {
   local fileNum=$1
   local startStr=$2
   local endStr=$3

   local inputFile="turbChannel.par"
   local outputFile="turbChannelNew.par"

   local n=1

   while read line; do

      if [ $n -eq 1 ]; then
         echo "$line" > $outputFile
      elif [ $n -eq 9 ]; then
         echo "startFrom = turbChannel.f"$fileNum" time="$startStr >> $outputFile
      elif [ $n -eq 11 ]; then
         echo "endTime = "$endStr >> $outputFile
      else
         echo "$line" >> $outputFile
      fi

   #   echo $n
      n=$((n+1))

   done < $inputFile

   cp turbChannelNew.par turbChannel.par
}

function add() { n="$@"; bc <<< "${n// /+}"; }
# -----------------------------------------------------------------------------
caseName="Re180D8pi3piM100"
folder="turChaR180D8pi3piM100From" 
timeStep=80

completationFlag=0
fileNum=0

oldTime=$(< runTime.txt)

# ----------------------------------- check wherether or not the simulation completed
commandRun "cd "$folder$oldTime"s"

CompletationInf
echo "$completationFlag $fileNum"
#fileNum=00047

newTime=""; EndTimeRead
#newTime=60.000330

currentTime=$(add $oldTime $fileNum)

echo "From $oldTime (s) -> $currentTime (s) -> $newTime (s)"
#echo "currentTime = $currentTime s"
#echo "endTime     = $newTime s"

cd ..

if [ $completationFlag -eq $1 ]; then
    # echo "The simulation completed"
# -------------------------------------------------------------------------------
echo $newTime > runTime.txt

commandRun "mkdir "$folder$newTime"s"
commandRun "cd "$folder$oldTime"s"
chmod +x ./MoveMonitoringFile
./MoveMonitoringFile
sleep 0.5
cd ..

# ----------------------------------- Coppy files
fileName="turbChannel.box"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="turbChannel.re2"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="turbChannel.ma2"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="turbChannel.usr"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="turbChannel.par"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="SIZE"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="*MonitoringFile"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="jobScript.sh"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="runBash.sh"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="checkStop.txt"; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"

fileName="turbChannel0.f"$fileNum; commandRun "cp "$folder$oldTime"s/"$fileName" "$folder$newTime"s/turbChannel.f"$fileNum
fileName="obj"; commandRun "cp -r "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"
fileName="monitoring"; commandRun "cp -r "$folder$oldTime"s/"$fileName" "$folder$newTime"s/"

# ----------------------------------- write SESSION.NAME
commandRun "cd "$folder$newTime"s"
WriteSessionName $caseName $folder $newTime

# ----------------------------------- write .par file
endTime=$(add $newTime $timeStep)
#endTime=280.007

echo "$endTime"
WriteParFile $fileNum $newTime $endTime

makenek turbChannel > /dev/null

# bash runBash.sh
sbatch jobScript.sh > idRun.txt
cd ..

echo $endTime > endTime.txt

squeue -u a1739506

# -------------------------------------------------------------------------------    
else
    echo "The simulation is running  ..."
fi



