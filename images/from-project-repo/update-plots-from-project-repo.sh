#! /bin/bash

set -e

project_repo_path="../../../codiv-sanger-bake-off"

if [ ! -e "$project_repo_path" ]
then
    echo "Could not find project repo:"
    echo ""
    echo "  $project_repo_path"
    echo ""
    echo "For this script to work, the 'codiv-sanger-bake-off' project repo "
    echo "needs to be in the same directory as this ('codiv-sanger-bake-off-tex')"
    echo "repo."
    exit 1
fi

for plot_file in *.pdf
do
    project_plot_path="${project_repo_path}/results/plots/${plot_file}"
    cp "$project_plot_path" "$plot_file"
done
