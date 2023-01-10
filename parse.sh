#!/bin/bash

# Check if script has at least one argument
if [[ $# -lt 2 ]] ; then
    echo -e "\nNo parameter passed!\n\tPlease use -f or --filename followed by a full path.\n\tEg: parse.sh -f /vagrant/artifacts/DESKTOP-123.zip\n"
    exit 1
fi

# Read script arguments to store filename to be parsed
while [[ $# -gt 0 ]]
do case $1 in
    -f|--filename) filename="$2"
    shift;;
    *) echo -e "\nUnknown parameter passed: $1\n\tPlease use -f or --filename followed by a full path.\n\tEg: parse.sh -f /vagrant/artifacts/DESKTOP-123.zip\n"
    exit 1;;
esac
shift
done

# Check if filename exists
if [ ! -f $filename ]; then
    echo -e "\nFile $filename not found!\nExiting..\n"
    exit 1
else
    echo -e "\nFile to be parsed: $filename"
fi

# Confirm user choice
read -p "Continue (y/n)?" choice
case "$choice" in 
  y|Y)
	# Set unique values for work directory naming
	hostname=$(basename $filename .zip)
	datetime=$(date -d "today" +"%Y%m%d%H%M")
	workdir="/vagrant/artifacts/$hostname.$datetime"
	splworkdir="/vagrant/parsed/$datetime"
	mkdir $workdir $splworkdir
	cd $workdir
    
	### Create Timeline ###

	# Install unzip utility if required
	# sudo apt-get -qq install -y unzip > /dev/null
	# Extract MFT
	unzip -o -j $filename */\$MFT -d $workdir
	# Parse MFT to body file
	MFTECmd -f $workdir/\$MFT --body $workdir --bodyf mft.body --bdl c	
	# Parse body file to CSV Timeline
	mactime -b $workdir/mft.body -d -y -z UTC > $workdir/$hostname.MftTimeline.csv
	# Move Timeline CSV to Splunk ingestion directory
	mv $workdir/*.MftTimeline.csv $splworkdir

	
	### Create Supertimeline ###
	
	# Parse ZIP file to CSV
	cdqr.py --nohash --max_cpu -y $filename $workdir
	# Move SuperTimeline CSV to Splunk ingestion directory
	mv $workdir/*.SuperTimeline.csv $splworkdir

	### Clean working directory ###
	rm -rf $workdir
	exit 0
  ;;
  n|N) echo -e "No selected. Exiting.\n"
	exit 1
  ;;
  *) echo -e "Invalid choice. Please answer y or n.\n"
	exit 1
  ;;
esac
