from gen_solutions import gen_corpus

import sys

run_query = sys.argv[1]

# Generate the corpus.scm file
gen_corpus(run_query)