#! /bin/bash

set -e

write_hline() {
    echo "########################################################################"
}

write_banner_msg() {
    echo ""
    write_hline
    echo "$@"
    write_hline
}

# Display help info
usage () {
echo ""
echo "Usage:"
echo "  $0 [ OPTIONS ] [ GIT-REF ]"
echo ""
echo "Example:"
echo ""
echo "  $0 HEAD"
echo ""
echo "Optional flag arguments ( 'OPTIONS' ):"
echo "  -h|--help         Show help message and exit."
echo ""
echo "Positional arguments ( 'GIT-REF' ):"
echo "  The Git ref for the codiv backoff project repo. Plots from this commit"
echo "  will be copied into this manuscript repo."
echo "  If no ref is provided, the default is to use the most recent commit of"
echo "  of the project repo."
echo ""
}

this_dir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

sister_project_dir="$(dirname "$this_dir")/codiv-sanger-bake-off"

# Remove the temporary directory created for project repo
clean_up() {
  test -d "$tmp_dir" && rm -rf "${tmp_dir}/.git" && rm -r "$tmp_dir"
}
# Ensure temp dir gets deleted on exit
trap clean_up EXIT
# Make temp dir for cloning project repo 
# The or ("||") syntax is to support different flavors of `mktemp`; Darwin's
# mktemp behaves differently than Gnu's.
tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t 'tmp_codiv_bakeoff')"


###############################################################################
# Process command line args

positional_args=()

while [ -n "$1" ]
do
    case $1 in
        -h | --help)
            usage
            exit
            ;;
        -* | --*)
            echo "Unrecognized option flag: \"$1\""
            usage
            exit 1
            ;;
        *)
            positional_args+=("$1")
            shift
            ;;
    esac
done

###############################################################################
# Sanity checks

if [ "${#positional_args[@]}" -ge "2" ]
then
    write_banner_msg "ERROR: You provided ${#positional_args[@]} positional arguments; only 1 is allowed"
    exit 1
fi

using_git=true
if [ -d "$sister_project_dir" ]
then
    using_git=false
fi

if [ "${#positional_args[@]}" = "1" ]
then
    using_git=true
fi

project_dir="$tmp_dir"

if [ "$using_git" = true ]
then
    write_banner_msg "Getting plots from project directory via Git..."
else
    write_banner_msg "Getting plots from sister project directory rather than via Git..."
    project_dir="$sister_project_dir"
fi

project_plot_dir="${project_dir}/results/plots"
project_emp_plot_dir="${project_dir}/results/empirical-plots"
image_dir="${this_dir}/images"
if [ ! -d "$image_dir" ]
then
    mkdir "$image_dir"
fi
dest_dir="${image_dir}/from-project-repo"
if [ ! -d "$dest_dir" ]
then
    mkdir "$dest_dir"
fi


if [ "$using_git" = true ]
then
    write_banner_msg "Cloning codiv bakeoff project repo..."
    git clone git@github.com:phyletica/codiv-sanger-bake-off.git "$project_dir"
    
    git_ref="$(cd "$project_dir"; git rev-parse --short HEAD)"
    if [ "${#positional_args[@]}" = "1" ]
    then
        git_ref="${positional_args[0]}"
    fi
    
    commit_sha="$(cd "$project_dir"; git rev-parse --short "$git_ref")"
    
    # Make sure we are on the correct commit so we copy the correct images
    write_banner_msg "Checking out commit $commit_sha  of bakeoff project repo..."
    (
        cd "$project_dir"
        git checkout -b tmp "$commit_sha"
        git lfs pull --include "*.pdf"
        files_to_remove=$(find results/plots -type f ! -name "*.pdf" && find results/empirical-plots -type f ! -name "*.pdf")
        for f in $files_to_remove
        do
            rm "$f"
        done
    )
fi

write_banner_msg "Copying plot directories from project repo..."
cp -r "$project_plot_dir" "$dest_dir"
cp -r "$project_emp_plot_dir" "$dest_dir"
