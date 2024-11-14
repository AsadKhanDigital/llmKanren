from gen_solutions import gen_corpus

import sys

logic_variables, definitions, test_inputs, test_outputs = sys.argv[1:] 

print(logic_variables, definitions, test_inputs, test_outputs)

# Generate the corpus.scm file
gen_corpus(logic_variables, definitions, test_inputs, test_outputs)