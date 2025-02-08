import sys
from LLM import generate_corpus

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python run.py <logic_variables> <definition> <test_inputs> <test_outputs> [num_candidates]")
        sys.exit(1)
    
    logic_variables, definition, test_inputs, test_outputs = sys.argv[1:5]
    num_candidates = int(sys.argv[5]) if len(sys.argv) > 5 else 10

    corpus = generate_corpus(
        logic_variables,
        definition,
        test_inputs,
        test_outputs,
        num_candidates
    )

    with open("./src/MK/corpus.scm", "w") as f:
        f.write("(define exprs\n")
        f.write("  '(\n")
        f.write(corpus)
        f.write("\n))")