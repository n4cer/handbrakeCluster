#!/bin/bash
mkdir -p logs
#lsdvd /dev/sr0 > /dev/null && time ddrescue -r 1 /dev/sr0 $1.iso logs/$1.log

function rip ()
{
	loop=1
	while [ $loop == 1 ]; do
		loop=0
		csskeys
		echo "Starting Rip"
		time ddrescue -r 1 /dev/sr0 $1.iso logs/$1.log
		if [ $? != 0 ]; then
			# Error
			echo "An error has occured during ripping."
			read -p "Retry the rip?" -N 1 retry 
			echo
			if [ "$retry" == "y" ]; then loop=1; fi
		fi
	done

}

function csskeys ()
{
	cssloop=1
	while [ $cssloop == 1 ]; do
		cssloop=0
		lsdvd /dev/sr0 > /dev/null
		if [ $? != 0 ]; then
			# Error
			echo "Error getting CSS keys"
			read -p "(r)etry, (q)uit, or (c)ontinue anyway?" -N 1 retry
			echo
			if [ "$retry" == "r" ]; then cssloop=1; fi
			if [ "$retry" == "q" ]; then exit 0; fi
			if [ "$retry" == "c" ]; then cssloop=0; fi
		fi
	done
}

rip $1

echo "Rip finished"
read -p "Press enter to eject the disk" -N 1 blah 
echo "Ejecting Disk"
eject /dev/sr0
read -p "Press enter to submit the job for processing" -N 1 blah 
echo "Submitting Job"
./submitjob.sh "$1.iso" "$2" "$3"

#eject /dev/sr0



