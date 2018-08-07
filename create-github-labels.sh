echo ''
echo 'This script will remove the GitHub default labels and create required labels. A personal access token is required to access private repos.'

if [  "$1" == "" ]; then
	echo ''
	echo -n 'GitHub Org/Repo (e.g. foo/bar): '
	read REPO
else
	REPO="$1"
fi

if [  "$GITHUB_TOKEN" == "" ]; then
	echo ''
	echo -n 'GitHub Personal Access Token: '
	read -s GITHUB_TOKEN
fi

REPO_USER=$(echo "$REPO" | cut -f1 -d /)
REPO_NAME=$(echo "$REPO" | cut -f2 -d /)

# Delete default labels
curl -u $GITHUB_TOKEN:x-oauth-basic --request DELETE https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels/bug
curl -u $GITHUB_TOKEN:x-oauth-basic --request DELETE https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels/duplicate
curl -u $GITHUB_TOKEN:x-oauth-basic --request DELETE https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels/enhancement
curl -u $GITHUB_TOKEN:x-oauth-basic --request DELETE https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels/help%20wanted
curl -u $GITHUB_TOKEN:x-oauth-basic --request DELETE https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels/good%20first%20issue
curl -u $GITHUB_TOKEN:x-oauth-basic --request DELETE https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels/invalid
curl -u $GITHUB_TOKEN:x-oauth-basic --request DELETE https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels/question
curl -u $GITHUB_TOKEN:x-oauth-basic --request DELETE https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels/wontfix

# Create state labels.
curl -u $GITHUB_TOKEN:x-oauth-basic --include --request POST --data '{"name":"CONFLICT","color":"bc143e"}' "https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels"
curl -u $GITHUB_TOKEN:x-oauth-basic --include --request POST --data '{"name":"DO NOT MERGE","color":"d93f0b"}' "https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels"
curl -u $GITHUB_TOKEN:x-oauth-basic --include --request POST --data '{"name":"DO NOT REVIEW","color":"d93f0b"}' "https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels"
curl -u $GITHUB_TOKEN:x-oauth-basic --include --request POST --data '{"name":"Needs review","color":"5319e7"}' "https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels"
curl -u $GITHUB_TOKEN:x-oauth-basic --include --request POST --data '{"name":"Questions","color":"b5f492"}' "https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels"
curl -u $GITHUB_TOKEN:x-oauth-basic --include --request POST --data '{"name":"Ready for test","color":"0e8a16"}' "https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels"
curl -u $GITHUB_TOKEN:x-oauth-basic --include --request POST --data '{"name":"Ready to be merged","color":"c2e0c6"}' "https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels"
curl -u $GITHUB_TOKEN:x-oauth-basic --include --request POST --data '{"name":"Requires more work","color":"b60205"}' "https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels"
curl -u $GITHUB_TOKEN:x-oauth-basic --include --request POST --data '{"name":"URGENT","color":"d93f0b"}' "https://api.github.com/repos/$REPO_USER/$REPO_NAME/labels"
