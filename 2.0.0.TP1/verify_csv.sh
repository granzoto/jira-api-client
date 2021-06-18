for i in *csv; do
    printf "%-50s" "Verifying $i";
    if [[ $(awk -F, '{print NF}' $i | uniq | wc -l) -gt 1 ]]; then
        echo "[ FAIL ]"
        echo "Incorrect number of columns: "
        awk -F, '{print NF}' $i
    else
        echo "[  OK  ]"
    fi
done
