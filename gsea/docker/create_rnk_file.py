import argparse

import pandas as pd
import numpy as np


def parse_cl_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--input', dest='input_file', required=True)
    parser.add_argument('-o', '--output', dest='output', required=True)
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_cl_args()

    dge_df = pd.read_table(args.input_file, index_col=0)
    dge_df['rnk'] = -np.log(dge_df['pvalue']) * dge_df['log2FoldChange']
    rnk_df = dge_df['rnk'].dropna().sort_values(ascending=False)
    # need to handle cases where the FDR is a hard zero and we get inf:
    finite_idx = np.isfinite(rnk_df)
    if finite_idx.sum() < rnk_df.shape[0]:
        finite_entries = rnk_df.loc[finite_idx]
        top_finite = finite_entries.iloc[0]
        bottom_finite = finite_entries.iloc[len(finite_entries)-1]
        rnk_df.loc[(~finite_idx) & (rnk_df > 0)] = top_finite
        rnk_df.loc[(~finite_idx) & (rnk_df < 0)] = bottom_finite

    rnk_df.to_csv(args.output, sep='\t', header=False)