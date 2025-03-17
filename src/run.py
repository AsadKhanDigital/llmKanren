import sys
from LLM import generate_corpus

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python run.py <logic_variables> <definition> <test_inputs> <test_outputs> [num_candidates]")
        sys.exit(1)

    logic_variables, definition, test_inputs, test_outputs = sys.argv[1:5]
    num_candidates = int(sys.argv[5]) if len(sys.argv) > 5 else 100

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
        with open("./src/MK/corpus_zinkov_body.scm", "r") as g:
            f.write(g.read())
        f.write("\n")
        for _ in range(1):
            f.write(corpus)
        f.write("\n))")
    with open("./src/MK/corpus.scm", "r") as f: # for debugging
        print("Corpus:")
        print(f.read())
        print("\n")