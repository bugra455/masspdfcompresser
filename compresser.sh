#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_folder>"
    exit 1
fi

input_folder="$1"

if [ ! -d "$input_folder" ]; then
    echo "Error: Input folder '$input_folder' not found."
    exit 1
fi

output_folder="$input_folder/output"
mkdir -p "$output_folder"

# Check if there are any PDF files before proceeding
shopt -s nullglob
pdf_files=("$input_folder"/*.pdf)
shopt -u nullglob

if [ ${#pdf_files[@]} -eq 0 ]; then
    echo "No PDF files found in '$input_folder'."
    exit 1
fi

for input_pdf in "${pdf_files[@]}"; do
    output_pdf="$output_folder/$(basename "$input_pdf")"

    gs -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.5 \
       -dPDFSETTINGS=/screen \
       -dEmbedAllFonts=true -dSubsetFonts=true \
       -dDownsampleColorImages=true -dColorImageDownsampleType=/Bicubic -dColorImageResolution=72 \
       -dDownsampleGrayImages=true -dGrayImageDownsampleType=/Bicubic -dGrayImageResolution=72 \
       -dDownsampleMonoImages=true -dMonoImageDownsampleType=/Bicubic -dMonoImageResolution=72 \
       -dCompressFonts=true -dDiscardUnusedObjects=true -dDiscardUnusedFonts=true \
       -dDetectDuplicateImages=true \
       -sOutputFile="$output_pdf" "$input_pdf"

    if [ ! -f "$output_pdf" ]; then
        echo "Error: Output file '$output_pdf' was not created."
        continue
    fi

    echo "PDF compression completed successfully for '$input_pdf'. Output saved to '$output_pdf'."

    original_size=$(stat -c%s "$input_pdf")
    compressed_size=$(stat -c%s "$output_pdf")

    if command -v numfmt >/dev/null 2>&1; then
        echo "Original size: $(numfmt --to=iec $original_size)"
        echo "Compressed size: $(numfmt --to=iec $compressed_size)"
    else
        echo "Original size: $original_size bytes"
        echo "Compressed size: $compressed_size bytes"
    fi

    if command -v bc >/dev/null 2>&1; then
        compression_ratio=$(bc <<< "scale=2; $original_size / $compressed_size")
        echo "Compression ratio: $compression_ratio"
    else
        echo "Compression ratio: bc command not found."
    fi
done

echo "All PDF files in '$input_folder' have been compressed and saved to '$output_folder'."
