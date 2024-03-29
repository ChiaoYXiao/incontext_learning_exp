#!/bin/bash
#SBATCH --cpus-per-task=10
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=8
#SBATCH --gres=gpu:8
#SBATCH --time=1:00:00
#SBATCH --job-name=nq
#SBATCH --output=run_dir/%A.out
#SBATCH --error=run_dir/%A.err
#SBATCH --signal=USR1@140
#SBATCH --open-mode=append
#SBATCH --mem=470GB
#SBATCH --partition=learnlab
#SBATCH --constraint=volta32gb

size=base

DATA_DIR='/tmp2/cyxiao/llm/atlas/atlas_data'
INDEX_DIR='/tmp2/cyxiao/llm/atlas/preprocessing/data/indices/atlas_nq/wiki/base'



port=$(shuf -i 15000-16000 -n 1)
EVAL_FILES="${DATA_DIR}/data/nq_data/dev.jsonl" #${DATA_DIR}/data/nq_data/test.jsonl"
FINETUNED="false"
if [ "${FINETUNED}" = "true" ] ; then
    PRETRAINED_MODEL="${DATA_DIR}/models/atlas_nq/${size}"
    #PRETRAINED_INDEX="${INDEX_DIR}" #${DATA_DIR}/indices/atlas_nq/wiki/${size}
else
    PRETRAINED_MODEL="${DATA_DIR}/models/atlas/${size}"
    #PRETRAINED_INDEX="${INDEX_DIR}" #${DATA_DIR}/indices/atlas/wiki/${size}
fi
SAVE_DIR=${DATA_DIR}/experiments/
EXPERIMENT_NAME=${size}-nq-eval-v2
PRECISION="fp32" # "bf16"

python ../../evaluate.py \
    --name ${EXPERIMENT_NAME} \
    --generation_max_length 32 --target_maxlength 32 \
    --gold_score_mode "ppmean" \
    --precision ${PRECISION} \
    --reader_model_type google/t5-${size}-lm-adapt \
    --text_maxlength 218 \
    --target_maxlength 16 \
    --model_path ${PRETRAINED_MODEL} \
    --load_index_path  ${INDEX_DIR} \
    --eval_data ${EVAL_FILES} \
    --per_gpu_batch_size 1 \
    --n_context 20 --retriever_n_context 20 \
    --checkpoint_dir ${SAVE_DIR} \
    --main_port $port \
    --index_mode "faiss"  \
    --task "qa" \
    --write_results
