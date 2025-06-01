import argparse

import pandas as pd


def parse_cl_args():
    '''
    Parse the commandline args and return a namespace
    '''
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--norm_counts', dest='norm_counts', required=True)
    parser.add_argument('-a', '--annotations', dest='annotations', required=True)
    parser.add_argument('-g', '--gct_output', dest='gct_output_file', required=True)
    parser.add_argument('-c', '--cls_output', dest='cls_output_file', required=True)
    parser.add_argument('-t', '--threshold', dest='low_count_threshold', type=float, required=True)
    return parser.parse_args()


def write_gct(count_df, output_gct_file):
    count_df.insert(0, 'Description', '-')
    with open(output_gct_file, 'w') as fout:
        fout.write('#1.2\n')
        fout.write(f'{count_df.shape[0]}\t{count_df.shape[1]-1}\n')
        count_df.to_csv(fout, sep='\t', index_label='Name')


def write_cls(ann_df, output_cls_file):
    unique_conditions = ann_df['condition'].unique()
    with open(output_cls_file, 'w') as fout:
        cls_line_str = ' '.join(unique_conditions)
        fout.write(f'{ann_df.shape[0]} {len(unique_conditions)} 1\n')
        fout.write(f'# {cls_line_str}\n')
        fout.write(f"{' '.join(ann_df['condition'])}")


if __name__ == '__main__':

    args = parse_cl_args()
    counts = pd.read_table(args.norm_counts, sep='\t', index_col=0)
    annotations = pd.read_table(args.annotations, sep='\t', index_col=0)

    # remove the samples that were not at the extremes
    # of the count distribution for the gene of interest
    counts = counts[annotations.index]

    # filter out genes that have little to no expression across all
    # samples
    counts = counts.loc[counts.mean(axis=1) > args.low_count_threshold]

    write_gct(counts, args.gct_output_file)
    write_cls(annotations, args.cls_output_file)