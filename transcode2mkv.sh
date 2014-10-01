#!/bin/bash

VERSION=2.00
INPUT="$1"
RESOLUTION="$3"
SEPARATE="$4"
CHAPTERS="$5"
TITLES=0
#OPTS_HIGHRES="-e x264 -q 20.0 -r 29.97 --pfr  -a 1 -E faac -B 160 -6 dpl2 -R Auto -D 0.0 -f mkv -4 -X 1024 --strict-anamorphic -m"
#OPTS_LOWRES="-e x264 -q 20.0 -a 1 -E faac -B 128 -6 dpl2 -R 48 -D 0.0 -f mkv -X 480 -m -x cabac=0:ref=2:me=umh:bframes=0:subme=6:8x8dct=0:trellis=0"
#OPTS_SOURCE="-e x264  -q 20.0 -a 1,1 -E faac,ac3 -l 576 -B 160,160 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mkv --detelecine --decomb --strict-anamorphic -m -x b-adapt=2:rc-lookahead=50"
#OPTS_SOURCE="-e x264 -q 20.0 -E faac,ac3 --audio-copy-mask aac,ac3,dtshd,dts,mp3 --audio-fallback ffac3 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mkv --detelecine --decomb --strict-anamorphic -m -x b-adapt=2:rc-lookahead=50"
#OPTS_SOURCE="-v 0 -e x264 -q 20.0 -E faac,ac3 -6 dpl2,auto -R Auto,Auto -D 0.0,0.0 -f mkv --detelecine --decomb --strict-anamorphic -m -x b-adapt=2:rc-lookahead=50 -t 3 -m "
OPTS_SOURCE="-v 0 -e x264 -q 20.0 --h264-profile main --x264-preset veryfast -E copy -f mkv --detelecine --decomb --strict-anamorphic -m -x b-adapt=2:rc-lookahead=50 -t 3 -m "
#OPTS_NORMAL="--no-dvdnav -e x264  -q 22.0 -a 1 -E faac -B 160 -6 dpl2 -R Auto -D 0.0 -f mkv  --detelecine --decomb  --strict-anamorphic -m -x b-adapt=2:rc-lookahead=50"
OPTS_AUDIO_SCAN="--scan 2>&1| grep Hz | grep bps -c"
OPTS_SUBTITLE_SCAN="--scan 2>&1 | grep -A 20 \"subtitle tracks:\" | grep , -c"
AUDIO_TRACKS=""
SUBTITLE_TRACKS=""
MODE=""
HANDBRAKE=HandBrakeCLI
DIRNAME=`dirname "$INPUT"`
BASENAME=`basename "$INPUT"`
OPTS=""
OUTPUT_DIR="$2"
OUTPUT_FILE_NAME=""

echo "::$INPUT::" 1>&2

if [ -z "$INPUT" ] 
then
        usage
fi

function usage () {
	echo "usage $0 <input file / folder> <output folder> <highres|lowres|source> [<separate|title> [chapters]]"	
	echo
	echo "Input either file, VIDEO_TS directory or .ISO"
	echo 
	echo -e "highres:\t1024 x 576"
	echo -e "lowres:\t\t480 x 320"
	echo -e "source:\t\tsame as source."
	echo 
	echo -e "separate:\tseparate files for episodes of a series."
	echo -e "title:\tManual title selectionion."
	echo
	echo -e "chapters:\tFor use with Manual title selection."
	exit 1
}

if [ ! -z "$OUTPUT_DIR" ]
then
	if [ ! -e "$OUTPUT_DIR" ] || [ ! -d "$OUTPUT_DIR" ]
	then
		echo "Output directory does not exist or is not a directory."
		exit 1
	fi
else
	echo "Output to current directory."
	OUTPUT_DIR="."
fi


if [ ! -e "$INPUT" ]
then
	echo "$INPUT does not exist!"
	exit 1
fi

if [ -d "$INPUT" ] 
then
	MODE=DIR
else
	MODE=FILE
fi

echo "Input type is $MODE"

case "$RESOLUTION" in 
	highres|HIGHRES	) 
			OPTS="$OPTS_HIGHRES" ;;
	lowres|LOWRES  	)
			OPTS="$OPTS_LOWRES" ;;
	source|SOURCE	)
			OPTS="$OPTS_SOURCE" ;;
#			OPTS="$OPTS_NORMAL" ;;			
			*) 	
			echo "Resolution must be 'highres', 'source' or 'lowres'." 
			exit 1 
			;;
esac

function titles () {

	TITLES=`$HANDBRAKE -t 0 -i "$INPUT" 2>&1 | grep "+ title" | awk '{ print $3 }'  | sed s/://g`
	#TITLES='1 2 3 4'
	echo $TITLES
}

function generate_string () {

	MAX="$1"
	STRING=""
	i=0
	while [ "$i" -le "$MAX" ]
	do
		if [ -z "$VAR" ]
		then
			VAR=$i
		else 
			VAR=$VAR,$i
		fi
		((i++))
	done	
	echo "$VAR"
}

function audio () {

	#NUMBER=`$HANDBRAKE -i "$INPUT" --scan 2>&1| grep Hz | grep bps -c`

	# Locate main title
	#MAIN_TITLE=$($HANDBRAKE -i "$INPUT" --scan --main-feature 2>&1 | grep "setting title to "|grep -o "[0-9]\+")
	MAIN_TITLE=$(lsdvd "$INPUT" 2>&1 | grep "Longest track"|grep -o "[0-9]\+")
	# Get English and Undefined tracks (output as comma separated list)
	NUMBER=`$HANDBRAKE -i "$INPUT" -t "$MAIN_TITLE" --scan 2>&1| grep Hz | grep bps | egrep ' eng| deu' |grep -v -i "commentary" |cut -f 1 -d ','|grep '[0-9]' -o | tr '\n' ','|sed 's/,$//'`
        #NUMBER='1'

        # If no tracks are selected, select all audio tracks
        if [ "x$NUMBER" == "x" ]
                then
                NUMBER=`$HANDBRAKE -i "$INPUT" -t "$MAIN_TITLE" --scan 2>&1| grep Hz | grep bps -c`
                if [ $NUMBER -eq 0 ]
                then
                        NUMBER=`$HANDBRAKE -i "$INPUT" -t "$MAIN_TITLE" --scan 2>&1| grep -c 'checking audio '`
                fi
                NUMBER=`generate_string $NUMBER`
        fi
	echo "Audio tracks is $NUMBER" 1>&2
	#AUDIO_TRACKS=`generate_string $NUMBER`
	AUDIO_TRACKS="$NUMBER"
	#Tonspuren
	AUDIO_TRACKS="1,2"
	
}

audio

function subtitles () {
	
	NUMBER=`$HANDBRAKE -i "$INPUT" -t "$MAIN_TITLE" --scan 2>&1 | grep -A 20 subtitle\ tracks: | grep , -c`
	echo "Subtitles tracks is $NUMBER" 1>&2
	#SUBTITLE_TRACKS=`generate_string $NUMBER`
	SUBTITLE_TRACKS=0
}

subtitles


if [ "$MODE" = "FILE" ]
then
	mkdir -p "$OUTPUT_DIR/$DIRNAME" 
	OUTPUT_FILE_NAME="$OUTPUT_DIR/$DIRNAME/${BASENAME%.*}"
elif [ "$MODE" = "DIR" ]
then
	echo "$INPUT" | grep -i video_ts >> /dev/null 2>&1
	if [ "$?" = "0" ]
	then
		INTERMEDIATE2=`basename "$DIRNAME"`
		mkdir -p "$OUTPUT_DIR/$DIRNAME"
		OUTPUT_FILE_NAME="$OUTPUT_DIR/$DIRNAME/$INTERMEDIATE2"
	else
		INTERMEDIATE2="$BASENAME"
		mkdir -p "$OUTPUT_DIR/$DIRNAME/$INTERMEDIATE2"
		OUTPUT_FILE_NAME="$OUTPUT_DIR/$DIRNAME/$INTERMEDIATE2/$INTERMEDIATE2"
	fi
	echo "INTERMEDIATE2 = $INTERMEDIATE2"
else
	echo "Mode is not determined..."
	exit 1
fi

if [ "$SEPARATE" = "separate" ]
then
	TITLES=`titles $INPUT`
	echo "TITLES = $TITLES"
	ERROR=0

	for x in $TITLES
	do
	        echo "Processing $INPUT ($x) to $OUTPUT_FILE_NAME-$x.mkv"
		time HandBrakeCLI -v 0 $OPTS -t $x -m -a $AUDIO_TRACKS -s $SUBTITLE_TRACKS -i "$INPUT" -o "$OUTPUT_FILE_NAME-$x.mkv" 2> "$OUTPUT_FILE_NAME-$x.junklog" | tee "$OUTPUT_FILE_NAME-$x.log" 1>&2
		if [ ! "$?" = "0" ]
		then 
			ERROR="1"
		fi 
		echo ""
		echo "Done"
	done
	exit "$ERROR"
elif [ -z "$SEPARATE" ]
then
	echo "Creating a single file."
        echo "Processing $INPUT to $OUTPUT_FILE_NAME.mkv" 1>&2
        echo "`hostname`:start:`date +%s`:$OUTPUT_FILE_NAME `date`" >> cluster.log	
        
	time HandBrakeCLI -v 0 $OPTS --main-feature -m -a $AUDIO_TRACKS -s $SUBTITLE_TRACKS -i "$INPUT" -o "$OUTPUT_FILE_NAME.mkv" 2> "$OUTPUT_FILE_NAME.junklog" | tee "$OUTPUT_FILE_NAME.log" 1>&2

	echo "Done $OUTPUT_FILE_NAME.mkv" 1>&2
        echo "`hostname`:finished:`date +%s`:$OUTPUT_FILE_NAME `date`" >> cluster.log	

else
        x="$SEPARATE"
        CHAPTERS_CLI=""
        if [ -n "$CHAPTERS" ] # If only certain chapters are wanted
        then
                CHAPTERS_CLI=" -c $CHAPTERS "
                OUTPUT_FILE_NAME="$OUTPUT_FILE_NAME-${x}_$CHAPTERS"
        else
                OUTPUT_FILE_NAME="$OUTPUT_FILE_NAME-$x"
        fi
        echo "Processing $INPUT ($x $CHAPTERS) to $OUTPUT_FILE_NAME.mkv" 1>&2
        echo "`hostname`:start:`date +%s`:$OUTPUT_FILE_NAME `date`" >> cluster.log

	time HandBrakeCLI -v 0 $OPTS $CHAPTERS_CLI -t $x -m -a $AUDIO_TRACKS -s $SUBTITLE_TRACKS -i "$INPUT" -o "$OUTPUT_FILE_NAME.mkv" 2> "$OUTPUT_FILE_NAME.junklog" | tee "$OUTPUT_FILE_NAME.log" 1>&2

	echo "Done $OUTPUT_FILE_NAME.mkv" 1>&2
        echo "`hostname`:finished:`date +%s`:$OUTPUT_FILE_NAME `date`" >> cluster.log		

fi




