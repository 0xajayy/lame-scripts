#!/usr/bin/env bash

compile()
{
nasm -f elf64 $1 -o $1.o
ld $1.o -o $1.elf
echo shellcode $(printf '\\x' && objdump -d $1.elf | grep "^ " | cut -f2 | tr -d ' ' | tr -d '\n' | sed 's/.\{2\}/&\\x /g'| head -c-3 | tr -d ' ' && echo ' ')
}

banner() {
echo "ICAgICAgICAgICAgICAgX18KICAgICAgICAgICAgICAvIF8pCiAgICAgXy9cL1wvXF8vIC8KICAgX3wgICAgICAgICAvCiBffCAgKCAgfCAoICB8Ci9fXy4tJ3xffC0tfF98ICBzaGVsbGNvZGVyCgoK"|base64 -d
}

help()
{
   banner
echo """
shellcoder tool generate's shellcode from assembly file. created
to automate compilation process. currently supports only linux x64
"""

<<comment
Todo: Add 32 bit support for x86 system, arm architecure (Aarch64, Arm32)
BSD & macos support
comment


   echo "Syntax: $0 [-|h|r|k]"
   echo "options:"
   echo "-r     run's the executable after compilation then removes it "
   echo "-h     Print this Help."
   echo "-k     keep's the executable in case if you need it"
   echo """
without using any of this options we can generate a shellcode loader in c
in filename.s.c
ex:<shellcoder.sh shell.s> // generates shell.s.c loads shellcode in c file

"""
}

run()
{
if [ $# -eq 0 ]; then
echo "$0 -h for help"
else
compile $1
./$1.elf
echo "cleaning up generated executables $1.elf, $1.o"
rm $1.elf $1.o
fi
}

keep(){
if [ $# -eq 0 ]; then
echo "$0 -h for help"
else
compile $1
echo "$1.o, $1.elf executables saved in $(pwd)"
fi
}

error() {
echo "unknown argument usage: $0 shellcode.s or $0 -h for help"
}
while getopts ":hrk" option; do
   case $option in
      h)
         help
         exit;;
      r)
	run $2
	exit;;
      k)
	keep $2
	exit;;
     \?)
	error
	exit;;

   esac
done
loader() {

disassembly=$(objdump -d -M intel ./$1.elf)

cat << EOF > $1.c
/*
$disassembly

*/

#include <stdio.h>
#include <string.h>

unsigned char code[]= "$2";
int main(){

        printf("length of your shellcode is: %d\n", (int)strlen(code));
        int (*ret)() = (int(*)())code;
        ret();
}
EOF

gcc $1.c -o $1.out -z execstack
echo "shellcode loader $1.c created and compiled successfully"

}

main()
{
if [ $# -eq 0 ]; then
echo "$0 -h for help"
elif [ $# -eq '1' ]; then
compile $1
#echo $(printf '\\x' && objdump -d $1.elf | grep "^ " | cut -f2 | tr -d ' ' | tr -d '\n' | sed 's/.\{2\}/&\\x /g'| head -c-3 | tr -d ' ' && echo ' ') > $1.txt
shellcode=$(printf '\\x' && objdump -d $1.elf | grep "^ " | cut -f2 | tr -d ' ' | tr -d '\n' | sed 's/.\{2\}/&\\x /g'| head -c-3 | tr -d ' ' && echo ' ')

loader $1 $shellcode
rm $1.elf $1.o
fi
}

main $1
