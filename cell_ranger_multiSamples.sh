#!/bin/bash

# Define the path to CellRanger
CELLRANGER_PATH="/data/lobolab/ReversePatterning.Reza/bin/bin/cell_ranger/cellranger-8.0.1/cellranger"

# Define the path to the reference genome
REF_GENOME="/data/lobolab/ReversePatterning.Reza/bin/bin/cell_ranger/refdata-gex-GRCh38-2024-A"

# Define the directory for output data
OUTPUT_DIR="/data/lobolab/ReversePatterning.Reza/cell_ranger_pipeline/scRNA-seqData/scRNA-seqData_CellRanger_Output"

# Define the Samples Text that includes sample name and the path to its fastq folder
SAMPLES_FILE="/data/lobolab/ReversePatterning.Reza/cell_ranger_pipeline/scRNA-seqData/scRNA-seqData_AllDatys.txt"

# Define the number of cells to be forced to be detected
# FORCE_CELLS="9000"

# Define the chemistry used
# CHEM="SC5P-R2"

# Loop through the samples file and run CellRanger count
while read -r SAMPLE_ID FASTQ_PATH; do
    # Find matching FASTQ files
    MATCHING_FILES=$(find "$FASTQ_PATH" -type f \( -name "XSTEM_20241105_*trimmed.fastq.gz" -o -name "XSTEM_20241108_*trimmed.fastq.gz" \))

    echo "$MATCHING_FILES"

    # Ensure there are matching FASTQ files to process
    if [ -n "$MATCHING_FILES" ]; then
        echo "Processing sample: $SAMPLE_ID"

        # Create a temporary directory for filtered FASTQ files
        TEMP_FASTQ_DIR=$(mktemp -d)
       
        # Copy the matching FASTQ files into the temporary directory

	for file in $MATCHING_FILES; do
		BASENAME=$(basename "$file")
		SAMPLE_NAME=$SAMPLE_ID  # You already have SAMPLE_ID from your loop
		LANE="L001"             # Default lane (adjust if needed)
   
		# Determine R1 or R2 based on filename
		if [[ "$BASENAME" == *"R1"* ]]; then
     			READ="R1"
		elif [[ "$BASENAME" == *"R2"* ]]; then
     			READ="R2"
		else
     			echo "Skipping file: $file (No R1/R2 found)"
        	continue
    		fi

    		# Construct the new filename
		NEW_NAME="${SAMPLE_NAME}_S1_${LANE}_${READ}_001.fastq.gz"

		cp "$file" "$TEMP_FASTQ_DIR/$NEW_NAME"

	done

	ls "$TEMP_FASTQ_DIR"

        # Ensure output directory exists
        cd "$OUTPUT_DIR"

        # Run CellRanger count using the temporary FASTQ directory
        $CELLRANGER_PATH count --id=$SAMPLE_ID \
            --localcores=60 \
            --localmem=200 \
            --create-bam=false \
            --transcriptome=$REF_GENOME \
            --fastqs="$TEMP_FASTQ_DIR" \
            --sample=$SAMPLE_ID

        # Remove the temporary directory
        rm -rf "$TEMP_FASTQ_DIR"

        echo "Completed processing sample: $SAMPLE_ID"
    else
        echo "No matching FASTQ files found for sample $SAMPLE_ID in $FASTQ_PATH"
    fi
done < "$SAMPLES_FILE"
