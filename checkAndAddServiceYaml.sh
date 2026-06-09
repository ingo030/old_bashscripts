#!/usr/bin/env bash
BASE_DIR="${1:-$(pwd)}"
EXT_DIR="$BASE_DIR/extensions"

if [ ! -d "$EXT_DIR" ]; then
    echo "❌ Extensions directory not found: $EXT_DIR"
    exit 1
fi

# Loop through each subfolder in extensions
for dir in "$EXT_DIR"/*/; do
    # Remove trailing slash and get the basename
    folder=$(basename "$dir")

    # Target file path
    yaml_file="$dir/Configuration/Services.yaml"

    # Check if Services.yaml exists
    if [ ! -f "$yaml_file" ]; then
        # Split by underscore
        project=$(echo "$folder" | cut -d'_' -f1)
        extension=$(echo "$folder" | cut -d'_' -f2)

        # Capitalize first letter
        project_cap=$(echo "${project:0:1}" | tr '[:lower:]' '[:upper:]')${project:1}
        extension_cap=$(echo "${extension:0:1}" | tr '[:lower:]' '[:upper:]')${extension:1}

        echo "Creating Services.yaml in: $folder"
        echo "  Projectname=$project_cap"
        echo "  Extensionname=$extension_cap"

        # Ensure Configuration folder exists
        mkdir -p "$dir/Configuration"

        # Write the YAML file
        cat > "$yaml_file" <<EOF
services:
  _defaults:
    autowire: true
    autoconfigure: true
    public: false

  Goldland\\${project_cap}${extension_cap}\\:
    resource: '../Classes/*'
EOF
    fi
done
