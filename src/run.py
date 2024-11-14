from gen_solutions import gen_corpus

import sys

logic_variables, defintitions, test_inputs, test_outputs = sys.argv[1:] 

print(logic_variables, defintitions, test_inputs, test_outputs)

# Generate the corpus.scm file
# gen_corpus(run_query)