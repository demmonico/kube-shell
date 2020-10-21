#!/usr/bin/env sh

GC='\[\033[01;32m\]'
RC='\[\033[01;31m\]'
BC='\[\033[01;34m\]'
NC='\[\033[00m\]'

cat << EOF > /etc/profile.d/shortcuts.sh && chmod +x /etc/profile.d/shortcuts.sh

export PS1='${GC}ksh::${CLUSTER}/${RC}${ENV}${NC}::${BC}\w${NC} \# '

alias ll="ls -al"

##### ksh shortcuts
alias khelp='cat /etc/profile.d/shortcuts.sh | grep -E "(alias|\#\#\#)"'

### resources
alias k="kubectl"
alias kg="kubectl get"
alias kga="kubectl get cronjob,job,pod"

# List all k8s resources in namespace
# kra -n <NAMESPACE>
alias kra="kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found"

### exec
alias ke="kubectl exec -ti"
# kec <pod_filter:selector for grep> -n <NAMESPACE> <CMD:printenv OR 'printenv PATH'>
alias kec='f(){ kubectl get pods \$2 \$3 | grep \$1 | head -n 1 | awk '\''{print \$1}'\'' | xargs -I % kubectl exec -t \$2 \$3 % \$4; }; f'

### monitor
alias kl="kubectl logs --prefix=true"
alias kwg="watch -n 5 kubectl get job,pod"

### cronjob
# kcronen/kcrondis <cronjob_name> -n <NAMESPACE>
alias kcronen='f(){ kubectl patch cronjobs \$1 -p '\''{ "spec" : { "suspend" : false }}'\'' \$2 \$3; }; f'
alias kcrondis='f(){ kubectl patch cronjobs \$1 -p '\''{ "spec" : { "suspend" : true }}'\'' \$2 \$3; }; f'

# Manually run job based on cronjob
# kjobfrom <cronjob_name> <job_suffix> -n <NAMESPACE>
alias kjobfrom='f(){ kubectl create job --from=cronjob/\$1 \$1-\$2 \$3 \$4; }; f'

EOF


sh -l