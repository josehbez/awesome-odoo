#! /bin/env bash
HELP (){ 
    echo "Odoo Module Community by https://github.com/josehbez"
    echo ""
    echo "This script is ideal for Privete Repo that publish on Public Repo "
    echo "by readonly."
    echo ""
    echo "How to use?"
    echo ""
    echo "1) Create file odoo-module-community.txt, and very line Files or Dirs to publish"
    echo "2) odoo-module-community.sh URL BRANCH"
    echo "  2.Arg1) https://gitlab:TOKEN@github.com/a/b.git or git@github.com:a/b.git"
    echo "  2.Arg2) master or dev"
    echo "3) Optional export SLACK_WEBHOOK=https://hooks.slack.com/services/A/B/C"
    echo "4) Optional export SLACK_CHANNEL=general"
}


URL=$1
BRANCH=${BRANCH:=master}
DIR=publish
TXT=publish.txt
SLACK_CHANNEL=${SLACK_CHANNEL:=general}

if [ -z "$1" ];  then 
    echo "Is required repo url"
    exit 1
fi 
if [ $URL = "help" ] || [ $URL = "h" ] ; then 
    HELP
    exit 1
fi 
if [ ! -z "$2" ];  then 
    BRANCH=$2
fi 
if [ -d $DIR ]; then 
    rm -fr $DIR
fi

if [ ! -f $TXT ]; then
    echo "Sorry, $TXT no exists."
    exit 1 
fi 

PUBLISH_LIST=()
git clone $URL -b $BRANCH $DIR
while IFS= read -r LINE
do
    LINE_COMMENT=${LINE:0:1}
    COMMENT=#
    if [ $LINE_COMMENT != $COMMENT ] ; then        
        if [ -e $LINE ]; then             
            echo "copy -r $LINE $DIR"            
            cp -r $LINE $DIR
            PUBLISH_LIST+=($LINE)
        else 
            echo "Don't exists $LINE"
        fi        
    fi 
done < ./$TXT


MSG=$(git show -s --format='%s')
cd $DIR

if [[ `git status --porcelain` ]]; then
    [[ ! $(git config --global user.email) ]] &&  git config --global user.email "no-reply@publish.bot"
    [[ ! $(git config --global user.name) ]] && git config --global user.name "Publish Bot"
    
    git add . 
    git commit -m "$MSG"
    git push --set-upstream origin $BRANCH
    cd ..
    MSG_NOTIFY="Publish at branch: $BRANCH \n\n ${PUBLISH_LIST[*]}" 
    echo $MSG_NOTIFY
    if [ ${#PUBLISH_LIST[@]} > 0 ]; then 
        if [[ $SLACK_WEBHOOK ]]; then 
            curl -X POST --data-urlencode "payload={\"channel\": \"#$SLACK_CHANNEL\", \"text\": \"${MSG_NOTIFY}\", }" $SLACK_WEBHOOK
        fi 
    else
        echo "Any file was sync"
    fi 
fi