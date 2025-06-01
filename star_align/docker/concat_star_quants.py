import argparse
import pathlib

import pandas as pd


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('quant_files', nargs='+')
    parser.add_argument('-o', '--output', 
                        required=True, help='Path to output.')
    parser.add_argument('-s', '--strandedness', 
                        choices=[1,2,3],
                        type=int,
                        required=True,
                        help=('Stranded option for library prep. 1,2,3'
                        ' correspond to the options described in the STAR'
                        ' manual. For example, 1=unstranded,2=1st read aligned'
                        ' with RNA, 3=2nd read aligned with RNA.')
                        )
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    
    master_df = pd.DataFrame()
    selected_col = f'c{args.strandedness}'
    for f in args.quant_files:
        sample_id = pathlib.Path(f).name.split('.')[0]
        # note that c1, c2, and c3 correspond to different strandedness orientations
        # Here, we ch
        df = pd.read_table(f, skiprows=4, names=['c1','c2','c3'], index_col=0)
        df = df[[selected_col]]
        df.columns = [sample_id,]
        master_df = pd.concat([master_df, df], axis=1)
    master_df.to_csv(args.output, sep='\t')