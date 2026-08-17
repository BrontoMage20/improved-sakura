# This is copied over from the code used for my previous project. It will be edited later to be fully accurate to the continuation project.

image_repo="/home/brontomage20/openstego_temp_round_2"

count=0
success=0
failed=0
total=$(ls "$image_repo"/*.bmp 2>/dev/null | wc -l)
bmp_count="$count"

for image in "$image_repo"/*.BMP; do
    if [ ! -f "$image" ]; then
        echo "no .bmps found :("
        break
    fi

    count=$((count + 1))
    base_name="${image##*/}"; base_name="${base_name%.BMP}"

    echo ""
    echo "$base_name's file info: $(identify -format "Size: %b\nDimensions: %w x %h\nDPI: %x x %y\n" "$image")"
    echo ""
done