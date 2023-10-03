#!/bin/bash

# parse input arguments
for i in "$@"; do
case $i in
    -i=*|--input-directory=*)
    INPUT_DATA_DIRECTORY="${i#*=}"
    echo -e "\tINPUT_DATA_DIRECTORY=${INPUT_DATA_DIRECTORY}"
    shift
    ;;
    -o=*|--output-maf=*)
    OUTPUT_MAF="${i#*=}"
    echo -e "\tOUTPUT_MAF=${OUTPUT_MAF}"
    shift
    ;;
    -c=*|--center-name=*)
    CENTER_NAME="${i#*=}"
    echo -e "\tCENTER_NAME=${CENTER_NAME}"
    shift
    ;;
    -p=*|--annotation-scripts-home=*)
    ANNOTATION_SUITE_SCRIPTS_HOME="${i#*=}"
    echo -e "\tANNOTATION_SUITE_SCRIPTS_HOME=${ANNOTATION_SUITE_SCRIPTS_HOME}"
    shift
    ;;
    -t=*|--intermediate-files-directory=*)
    INTERMEDIATE_FILES_DIR="${i#*=}"
    echo -e "\tINTERMEDIATE_FILES_DIR=${INTERMEDIATE_FILES_DIR}"
    shift
    ;;
    -j=*|--annotation-pipeline-jar=*)
    ANNOTATION_PIPELINE_JAR="${i#*=}"
    echo -e "\tANNOTATION_PIPELINE_JAR=${ANNOTATION_PIPELINE_JAR}"
    shift
    ;;
    -s=*|--isoform-override=*)
    ISOFORM_OVERRIDE="${i#*=}"
    echo -e "\tISOFORM_OVERRIDE=${ISOFORM_OVERRIDE}"
    shift
    ;;
    -e=*|--annotation-error-log=*)
    ANNOTATION_ERROR_LOG="${i#*=}"
    echo -e "\tANNOTATION_ERROR_LOG=${ANNOTATION_ERROR_LOG}"
    shift
    ;;
    *)
    ;;
esac
done

ANNOTATION_ERROR_LOG=${ANNOTATION_ERROR_LOG:-./error.log}
ISOFORM_OVERRIDE=${ISOFORM_OVERRIDE:-uniprot}
INTERMEDIATE_FILES_DIR=${INTERMEDIATE_FILES_DIR:-$(mktemp -d)}

formatfile="${INTERMEDIATE_FILES_DIR}/outmafformat.txt"

python "${ANNOTATION_SUITE_SCRIPTS_HOME}/vcf2maf.py" -i "${INPUT_DATA_DIRECTORY}" -o "${INTERMEDIATE_FILES_DIR}" -c "${CENTER_NAME}"

python "${ANNOTATION_SUITE_SCRIPTS_HOME}/merge_mafs.py" -d "${INTERMEDIATE_FILES_DIR}" -o "${INTERMEDIATE_FILES_DIR}/merged.maf"

cut -f 3,5-7,11-13,16,34-35 "${INTERMEDIATE_FILES_DIR}/merged.maf" > "${INTERMEDIATE_FILES_DIR}/merged-minimal.maf"

echo "Hugo_Symbol,Entrez_Gene_Id,Center,NCBI_Build,Chromosome,Start_Position,End_Position,Variant_Classification,Variant_Type,Reference_Allele,Tumor_Seq_Allele1,Tumor_Seq_Allele2,dbSNP_RS,Tumor_Sample_Barcode,HGVSp_Short,t_alt_count,t_ref_count" > "${formatfile}"

java -jar "${ANNOTATION_PIPELINE_JAR}" \
    --filename "${INTERMEDIATE_FILES_DIR}/merged-minimal.maf" \
    --output-filename "${OUTPUT_MAF}" \
    --isoform-override "${ISOFORM_OVERRIDE}" \
    -t "${formatfile}" \
    -e "${ANNOTATION_ERROR_LOG}" \
    -r 