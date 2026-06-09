#!/bin/bash
#############################################
### Run Minor Update (Security Update) on All
### Local Projects and Git Commit
### touch updateMinorAllT3.sh && chmod u+x updateMinorAllT3.sh && vim updateMinorAllT3.sh
#############################################
set -o pipefail
set -u

echo "   Start script to update all local TYPO3 projects..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="${SCRIPT_DIR}/settingsUpdateMinorAllT3.sh"
if [[ -f "$CONFIG_FILE" ]]; then
    source "${CONFIG_FILE}"
else
    cat <<EOF > "${CONFIG_FILE}"
TYPO3_DDEV_PROJECTS_FOLDER="~/DDEV/Projects/"
COMMIT_MESSAGE_PREFIX="[Update]"
EOF
    echo "   Please update project folder config in \"${CONFIG_FILE}\" and start script again."
    exit 1
fi

TYPO3_DDEV_PROJECTS_FOLDER=$(eval echo "$TYPO3_DDEV_PROJECTS_FOLDER")
LOG_FILE="${SCRIPT_DIR}/updateMinorAllT3.log"

CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
echo "" >> "$LOG_FILE"
echo "[RUN] $CURRENT_TIME - Start update cycle" >> "$LOG_FILE"

echo "   Search for projects in $TYPO3_DDEV_PROJECTS_FOLDER..."

for PROJECT_DIR in "$TYPO3_DDEV_PROJECTS_FOLDER"*/ ; do
    echo ""
    echo "=> Check $PROJECT_DIR"

    if [[ ! -f "$PROJECT_DIR/.ddev/config.yaml" ]]; then
        echo "   - no ddev project in folder"
        continue
        else
          echo "   - found ddev"
    fi

    if ! grep -q "typo3" "$PROJECT_DIR/.ddev/config.yaml"; then
        echo "   - no TYPO3 project in .ddev/config.yaml"
        continue
        else
          echo "   - found \"typo3\" in config.yaml"
    fi

    cd "$PROJECT_DIR"
    echo "   cd => $PROJECT_DIR"

    # check uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
         echo "   Found uncommitted changes - stash them ..."
         git stash
         STASHED=true
    else
         STASHED=false
    fi

     # find highest version branch must start with "typo3-" and end with major.minor (e.g. typo3-12.4)
     BRANCH=$(git branch --format '%(refname:short)' | grep -E "^typo3-[0-9]{1,2}\.[0-9]$" | sort -Vr | head -n1 || true)

     # early return
     if [[ -z "$BRANCH" ]]; then
       echo "   no branch with the right definition typo3-xx.x"
       continue
     fi

     echo "   git checkout $BRANCH "
     git checkout "$BRANCH"
     git pull

     # start ddev
     if ! ddev start || ! ddev auth ssh; then
         CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
         echo "[ERROR] $CURRENT_TIME $PROJECT_DIR: ddev start or auth ssh failed" >> "$LOG_FILE"
         if $STASHED; then
           git stash pop;
         fi
         continue
     fi

     # get current TYPO3 Version
     if ! ddev composer install; then
         CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
         echo "[ERROR] $CURRENT_TIME $PROJECT_DIR: composer install failed" >> "$LOG_FILE"
         if $STASHED; then
           git stash pop;
         fi
         ddev stop
         continue
     fi
     OLD_VERSION=$(ddev composer show | grep "^typo3/cms-core " |  awk '{print $2}')
     echo "   current TYPO3-Version $OLD_VERSION"

     # Composer update
     echo "   ddev composer update ..."
     if ! ddev composer update; then
         CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
         echo "[ERROR] $CURRENT_TIME $PROJECT_DIR: composer update failed" >> "$LOG_FILE"
         if $STASHED; then
           git stash pop;
         fi
         ddev stop
         continue
     fi

     # check for changes
     if [[ -n $(git status --porcelain composer.json composer.lock) ]]; then
         NEW_VERSION=$(ddev composer show | grep "^typo3/cms-core " |  awk '{print $2}')
         echo "   new TYPO3-Version $NEW_VERSION"
         git add composer.lock composer.json
         git commit -m "${COMMIT_MESSAGE_PREFIX} ${OLD_VERSION} => ${NEW_VERSION}"
         git push

         CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
         echo "[COMMIT] $CURRENT_TIME $PROJECT_DIR: ${COMMIT_MESSAGE_PREFIX} ${OLD_VERSION} => ${NEW_VERSION}" >> "$LOG_FILE"

         for CONFIGYAML in config/sites/*/config.yaml; do
             [[ -f "$CONFIGYAML" ]] || continue
             url=$(grep -m1 "^base:" "$CONFIGYAML" | awk '{print $2}' | tr -d "'\"")
             if [[ -n "$url" ]]; then
                 echo "[Check Live] $url" >> "$LOG_FILE"
             fi
         done

         echo "   commit and pushed"
     else
         CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
         echo "[SKIP]  $CURRENT_TIME $PROJECT_DIR: ${OLD_VERSION} already up to date" >> "$LOG_FILE"
         echo "   no changes, no commit"
     fi

     # git stash pop
     if $STASHED; then
         echo "   pop stashed changes"
         git stash pop
     fi
     ddev stop
     cd - >/dev/null
done

echo ""
echo "   all updates done"
echo "  "
cat "$LOG_FILE"