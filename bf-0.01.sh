#!/bin/bash
## bf-0.01.sh 0.01 jbgg ##


usage(){
	echo "usage: ./bf-0.01.sh <source.bf>"
	exit
}

programexit(){

	case $1 in
		1)
			echo "overflow of pointer" >&2
			;;
		2)
			echo ", instruction is not available" >&2
			;;
		3)
			echo "unmatching []" >&2
			;;
	esac

	exit 1
}

debug(){
	i=1
	while [ $i -le $ptrmax ]; do
		if [ $i -eq $ptr ]; then
			printf "[*$i]=${mem[$i]};" >&2
		else
			printf "[$i]=${mem[$i]};" >&2
		fi
		i=`expr $i + 1`
	done
	echo '' >&2
}


## getting source file ##
sourcefile=$1
[ -z $sourcefile ] && usage
[ -f $sourcefile ] || usage

## initialize variables ##
# pointer to memory #
ptr=1
ptrmin=1
ptrmax=1
# memory #
mem=()
mem[$ptr]=0
# offset of file #
off=0

## reading source file with only valid characters ##
source=`tr -dc '><+-.,[]' < $sourcefile`
sourcesize=${#source}

## main loop: reading the source ##
off=0
while [ $off -lt ${sourcesize} ]; do
	case "${source:$off:1}" in
		'<')
			[ $ptr -eq $ptrmin ] && programexit 1
			ptr=`expr $ptr - 1`
			off=`expr $off + 1`
			;;
		'>')
			if [ $ptr -eq $ptrmax ]; then
				ptrmax=`expr $ptrmax + 1`
				ptr=$ptrmax
				mem[$ptr]=0
			else
				ptr=`expr $ptr + 1`
			fi
			off=`expr $off + 1`
			;;
		'+')
			if [ ${mem[$ptr]} -eq 255 ]; then
				mem[$ptr]=0
			else
				mem[$ptr]=`expr ${mem[$ptr]} + 1`
			fi
			off=`expr $off + 1`
			;;
		'-')
			if [ ${mem[$ptr]} -eq 0 ]; then
				mem[$ptr]=255
			else
				mem[$ptr]=`expr ${mem[$ptr]} - 1`
			fi
			off=`expr $off + 1`
			;;
		'.')
			printf "\x`printf %x ${mem[$ptr]}`"
			off=`expr $off + 1`
			;;
		',')
			programexit 2
			## off=`expr $off + 1`
			;;
		'[')
			if [ ${mem[$ptr]} -eq 0 ]; then
				off=`expr $off + 1`
				level=0
				while [ true ]; do
					[ $off -ge $sourcesize ] && programexit 3
					if [ ${source:$off:1} = ']' ]; then
						if [ $level -eq 0 ]; then
							off=`expr $off + 1`
							break
						else
							off=`expr $off + 1`
							level=`expr $level - 1`
						fi
					elif [ ${source:$off:1} = '[' ]; then
						off=`expr $off + 1`
						level=`expr $level + 1`
					else
						off=`expr $off + 1`
					fi
				done
			else
				off=`expr $off + 1`
			fi
			;;
		']')
			if [ ${mem[$ptr]} -ne 0 ]; then
				off=`expr $off - 1`
				level=0
				while [ true ]; do
					[ $off -lt 0 ] && programexit 3
					if [ ${source:$off:1} = '[' ]; then
						if [ $level -eq 0 ]; then
							off=`expr $off + 1`
							break
						else
							off=`expr $off - 1`
							level=`expr $level - 1`
						fi
					elif [ ${source:$off:1} = ']' ]; then
						off=`expr $off - 1`
						level=`expr $level + 1`
					else
						off=`expr $off - 1`
					fi
				done

			else
				off=`expr $off + 1`
			fi
			;;
	esac
done

