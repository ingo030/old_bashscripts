#!/usr/bin/env bash
# sources:
# https://stackoverflow.com/questions/3846380/how-to-iterate-through-all-git-branches-using-bash-script
#####################################################



#####################################################
# Chose a git branch to checkout from interactive list
#
# USAGE:
#   __deployAndCheckout [FOLDER]
#
#   if no FOLDER we're using the current folder
#####################################################

__deployAndCheckout() {
    local BASE_DIR="${1:-$(pwd)}"
    
    if [ ! -d "$BASE_DIR/.git" ]; then
        echo "Error no git repository in "$BASE_DIR
        return 1
    fi

    local current_branch
    current_branch=$(git -C "$BASE_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
    echo "current branch: $current_branch"

    # get remote branches
    echo "git fetch --all --prune --quiet..."
    git -C "$BASE_DIR" fetch --all --prune --quiet

    local branches=()
    local -A seen #assoziative array as we're using branch names

    while IFS="|" read -r name date msg; do
        # ignore 'origin' and 'origin/HEAD'
        if [[ "$name" == "origin" || "$name" == "origin/HEAD" ]]; then
            continue
        fi

        # get a short name to remove doubles from origin
        local short_name="$name"
        if [[ "$name" == origin/* ]]; then
            short_name="${name#origin/}"
        fi

        # ignore current branch
        if [[ "$short_name" == "$current_branch" ]]; then
            continue
        fi
        
        # ignore doubles
        if [[ -n "${seen[$short_name]}" ]]; then
            continue
        fi
        
        seen[$short_name]=1
        branches+=("$name|$date|$msg")

    done < <(git -C "$BASE_DIR" for-each-ref refs/heads refs/remotes \
        --sort=-committerdate \
        --format="%(refname:short)|%(committerdate:iso)|%(contents:subject)" | head -n 30)

    #we re using only up to 10 branches 
    branches=("${branches[@]:0:10}")

    if [ ${#branches[@]} -eq 0 ]; then
        echo "no other branches to checkout"
        return 0
    fi

    echo "the last branches (excl. the current branch) with commits in $BASE_DIR:"
    echo ""
    local i=0
    for entry in "${branches[@]}"; do
        local name date msg
        IFS="|" read -r name date msg <<< "$entry"
        printf "[%d] %s %-60s => %s\n" "$i" "$date" "$name" "$msg"
	i=$((i+1))
    done

    echo ""
    local choice
    echo -n "checkout branch nr (0-9, q to quit): "
    read choice

    if [[ "$choice" =~ ^[qQ]$ ]]; then
        echo "quit, no change"
        return 0
    elif [[ "$choice" =~ ^[0-9]$ ]] && [ "$choice" -lt "${#branches[@]}" ]; then
        local branch
        IFS="|" read -r branch _ <<< "${branches[$choice]}"
        echo "change to branch: $branch"
        
        if [[ "$branch" == origin/* ]]; then
            local local_branch="${branch#origin/}"
            if git -C "$BASE_DIR" show-ref --verify --quiet "refs/heads/$local_branch"; then
                echo "local branch '$local_branch' does exist - checkout directly"
                git -C "$BASE_DIR" checkout "$local_branch"
            else
		echo "local branch doesn't exist yet"
                git -C "$BASE_DIR" checkout -b "$local_branch" --track "$branch"
            fi
        else
            git -C "$BASE_DIR" checkout "$branch"
        fi
    else
        echo "no such option!"
        return 1
    fi
}
