#!/bin/bash

# Create results directory
#mkdir -p </path/to/output/directory>
mkdir -p /home/brontomage20/binwalk_results

# Gather all JPG/JPEG stego files.
files=()
while IFS= read -r -d '' file; do
    files+=("$file")
done < <(find /home/brontomage20/stego_images -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.bmp' \) -print0)

total=${#files[@]}
total_image_time=0

if [ "$total" -eq 0 ]; then
    echo "No stego files found in /home/brontomage20/stego_images"
    exit 1
fi

echo "found $total stego files to process"
echo ""

# Generate a random seed and allow reuse of a previous seed.
seed=$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')
echo "Generated random seed: $seed"
read -rp "Enter seed to reuse or press Enter to keep this seed: " seed_input
if [[ "$seed_input" =~ ^[0-9]+$ ]]; then
    seed="$seed_input"
elif [ -n "$seed_input" ]; then
    echo "Invalid seed entered, using generated seed."
fi
echo "Using seed: $seed"

mapfile -d '' -t files < <(printf '%s\0' "${files[@]}" | python3 -c '
import sys, random
random.seed(int(sys.argv[1]))
data = [x for x in sys.stdin.buffer.read().split(b"\0") if x]
random.shuffle(data)
sys.stdout.buffer.write(b"\0".join(data))
' "$seed")

script_start=$(date +%s%N)

#process all JPG/JPEG files found in randomized order
for img in "${files[@]}"; do
    echo "==="
    echo "Processing: $img"
    echo "==="

    #start timing
    start=$(date +%s%N)

    #get just the file name for the output
    filename=$(basename "$img" | sed 's/\.[^.]*$//')

    outfile="/home/brontomage20/binwalk_results/${filename}.out"
    logfile="/home/brontomage20/binwalk_results/${filename}_result.txt"

    #run binwalker and save results
    stegcracker "$img" /home/brontomage20/Wordlists/wordlist_updated_no_num.txt -q 2>&1 | tee "$logfile"

    # Binwalker creates the file in the same directory as the input with .out appended
    binwalker_output="${img}.out"

    #check if a .out file was created (successful crack)
    if [ -f "$binwalker_output" ]; then
        echo "Success! Hidden data extracted to: ${filename}.out"
        cp "$binwalker_output" "$outfile"
        rm "$binwalker_output"
    fi

    #calculate and display time
    END=$(date +%s%N)
    elapsed=$(((END - start) / 1000000))
    echo "time taken: ${elapsed} milliseconds"
    echo "==="
    echo ""

    total_image_time=$((total_image_time + elapsed))
done


#calculate total time and average
script_end=$(date +%s%N)
total_time=$(((script_end - script_start) / 1000000))

if [ $total -gt 0 ]; then
	average_time=$((total_image_time / total))
else
	average_time=0
fi



echo "============================"
echo "Processing complete! Check results in:"
echo "home directory"
echo "Summary of successful extractions:"
# ls -1 /home/brontomage20/binwalker_results/*.out 2>/dev/null | while read file; do
# 	echo "$file"
# done
echo "time statistics:"
echo " - total images processed: ${total}"
echo " - total processing time: ${total_time} milliseconds ($((total_time / 60)) minutes/1000000)"
echo "============================"
echo ""

#show summary of successful cracks
echo ""
echo "summary of successful extractions:"
successful=0
for file in /home/brontomage20/binwalker_results/*.out; do
	if [ -f "$file" ] && [ -s "$file" ]; then
		# echo "[*checkmark*] $file"
		successful=$((successful + 1))
	fi
done

if [ $successful -eq 0 ]; then
	echo "no hidden data found in any image."
else
	echo ""
	echo "total successful extractions: $successful"
	echo "total failed extractions: $((total - successful))"
fi

# code here