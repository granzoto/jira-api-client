[[ -f tasks.log ]] && echo 'Exiting as tasks.log already exists (tasks already created) - Verify all log files' && exit 1

echo "Creating Tasks"
../jira-batch.sh tasks.csv tasks.json | tee tasks.log

read -p "press enter to continue"

i=0
for LINK in `cat tasks.log`; do
    [[ ! ${LINK} =~ ENTMQIC ]] && continue
    i=$((i+1))
    JIRAID=`echo $LINK | sed -re "s#.*/ENTMQIC#ENTMQIC#g"`
    CSV=`ls -1 $i-*csv 2> /dev/null`
    [[ ! -f "$CSV" ]] && continue
    echo Processing subtasks for $CSV
    sed -i "s/JIRAID/${JIRAID}/g" $CSV
    ../jira-batch.sh $CSV subtasks.json | tee $CSV.log
    echo
    read -p "press enter to continue"
done

echo Creating Epic Tasks
../jira-batch.sh static-epictasks.csv epictasks.json | tee epictasks.log
read -p "press enter to continue"

echo Creating Static Sub-Tasks
../jira-batch.sh static-subtasks.csv subtasks.json | tee static-subtasks.log
read -p "press enter to continue"
