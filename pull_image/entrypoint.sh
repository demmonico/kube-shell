#!/usr/bin/env sh

GC='\[\033[01;32m\]'
RC='\[\033[01;31m\]'
BC='\[\033[01;34m\]'
NC='\[\033[00m\]'

cat << EOF > /etc/profile.d/shortcuts.sh && chmod +x /etc/profile.d/shortcuts.sh

export PS1='${GC}ksh::${CLUSTER}/${RC}${ENV}${NC}::${BC}\w${NC} \# '

alias ll="ls -al"

# ksh shortcuts
alias khelp='cat /etc/profile.d/shortcuts.sh | grep -E "(alias|\#\#\#)"'

alias k="kubectl"
alias kg="kubectl get"
alias kga="kubectl get cronjob,job,pod"
alias ke="kubectl exec -ti"
alias kl="kubectl logs"

alias kwg="watch -n 5 kubectl get job,pod"

### kcronen <cronjob_name> -n <namespace>
alias kcronen='f(){ kubectl patch cronjobs \$1 -p '\''{ "spec" : { "suspend" : false }}'\'' \$2 \$3; }; f'
alias kcrondis='f(){ kubectl patch cronjobs \$1 -p '\''{ "spec" : { "suspend" : true }}'\'' \$2 \$3; }; f'

### kcronen <cronjob_name> <job_suffix> -n <namespace>
alias kjobfrom='f(){ kubectl create job --from=cronjob/\$1 \$1-\$2 \$3 \$4; }; f'

EOF


sh -l