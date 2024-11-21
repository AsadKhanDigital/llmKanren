from gen_solutions import gen_corpus

import sys

logic_variables, definitions, test_inputs, test_outputs, debug = sys.argv[1:] 

print("--------------------------------------")
print("Logic Variables: ", logic_variables)
print("Definitions: ", definitions)
print("Test Inputs: ", test_inputs)
print("Test Outputs: ", test_outputs)
print("Debug: ", debug)
print("--------------------------------------")

# Generate the corpus.scm file
gen_corpus(logic_variables, definitions, test_inputs, test_outputs, debug)