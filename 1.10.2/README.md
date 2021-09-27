# How to create Tasks and Subtasks

## Tasks

The file tasks.json contains the template that will
be used to create the tasks in Jira.

Then the tasks.csv file contains a CSV file that is
suitable for the tasks.json template and it defines
all tasks that will be created.

## Sub-Tasks

The sub-tasks are defined based on subtasks.json 
template file.

For each task from tasks.csv, a corresponding
subtask csv file can (optionally) be defined.

The name convention for the subtask CSV file name is:
`<TASK_ID>-*.csv`

where:

TASK_ID = the line number (excluding header) from the tasks.csv file
          that represents the parent task

The `subtasks.json` template defines a `PARENT_TASK` field
and its value must be defined at the `<TASK_ID>-*.csv` as
**JIRAID** this way the shell script that creates the tasks
will replace this string with the generated Jira ID.

## Creating the tasks

    IMPORTANT:
    
    The script does not query for existing tasks and sub-tasks
    so if you run the it multiple times it will create duplicated items.

First you need to provide your Jira credentials. To do so, just
run: `source ../jira-user-pass-source.sh`.

After you've provided your credentials, your templates and
CSV files have been properly adjusted you can run:

```
./create_release_tasks.sh
```

... it will create all tasks, their corresponding subtasks as well.
