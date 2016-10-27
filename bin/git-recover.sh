#!/bin/bash

if [ "$1" == "--help" -o "$1" == "-h" ]
then
    echo "Usage: recover [-p|--progress]"
    echo "Recover git objects reported to be unreachable or dangling (not referenced) in the working copy"
    echo
    echo -e "\t-p | --progress\t\t\t\tShow every action taken or not taken"
    exit
fi

PROGRESS=0
if [ "$1" == "--progress" -o "$1" == "-p" ]
then
    PROGRESS=1
fi

IFS=$'\n'
DANGLINGS=`git fsck --full --strict --no-reflogs --no-progress | cut -f2-3 -d " "`

if [ ! -f recover-undo.sh ]
then
    echo "#!/bin/bash" > recover-undo.sh
fi

LOST_FOUND_CREATED=0
if [ -d "lost+found" ]
then
    LOST_FOUND_CREATED=1
fi

LAST_OUTPUT_CARRIAGE_RETURN=0
for DANGLING in $DANGLINGS
do
	TYPE=`echo $DANGLING | cut -f1 -d " "`
    HASH=`echo $DANGLING | cut -f2 -d " "`
    SHORTNAME="recover_"`expr substr $HASH 1 7`

    echo -n "Dangling "
    echo -n `printf "%-6s" "$TYPE"`
    echo -n " $HASH"
    LAST_OUTPUT_CARRIAGE_RETURN=0

    case "$TYPE" in
        "commit")
            echo "    restored"
            # Show the commit's log entry
            git --no-pager log -n 1 --decorate \
                --pretty=format:'%x09[%C(magenta)%h%Creset] %C(yellow)%cn <%ce>%Creset %n%x09%cd %n%x09%Cgreen%s%Creset' \
                --abbrev-commit

            git branch "$SHORTNAME" "$HASH"
            echo
            echo "git branch -D $SHORTNAME" >> recover-undo.sh
            ;;
        "blob")
            if [ $LOST_FOUND_CREATED -eq 0 ]
            then
                mkdir "lost+found"
                LOST_FOUND_CREATED=1
            fi

            if [ ! -f "lost+found/$HASH" ]
            then
                git cat-file blob $HASH > "lost+found/$HASH"
                echo "    restored"
                LAST_OUTPUT_CARRIAGE_RETURN=0
                echo "rm -v lost+found/$HASH" >> recover-undo.sh
            else
                if [ $PROGRESS -eq 0 ]
                then
                    echo -ne "\r"
                    LAST_OUTPUT_CARRIAGE_RETURN=1
                else
                    echo "    already restored"
                fi
            fi
            ;;
        *)
            if [ $PROGRESS -eq 0 ]
            then
                echo -ne "\r"
                LAST_OUTPUT_CARRIAGE_RETURN=1
            else
                echo "    noop"
            fi
            ;;
    esac
done

if [ "$LAST_OUTPUT_CARRIAGE_RETURN" -eq 1 -a "$PROGRESS" -eq 0 ]
then
    # Clear the line
    echo -ne "\033[0K\r"
fi

if [ $LOST_FOUND_CREATED -eq 1 ]
then
    echo "rm -r lost+found" >> recover-undo.sh
fi
echo "rm recover-undo.sh" >> recover-undo.sh

chmod u+x recover-undo.sh
