../jira-batch.sh template.csv template.json | tee tasks.log

i=0
for LINK in `cat tasks.log`; do
    [[ ! ${LINK} =~ ENTMQIC ]] && continue
    i=$((i+1))
    JIRAID=`echo $LINK | sed -re "s#.*/ENTMQIC#ENTMQIC#g"`
    CSV=`ls -1 $i-*csv 2> /dev/null`
    [[ ! -f "$CSV" ]] && continue
    echo Processing subtasks for $CSV
    sed -i "s/JIRAID/${JIRAID}/g" $CSV
    ../jira-batch.sh $CSV subtask.json | tee $CSV.log
    echo
done
