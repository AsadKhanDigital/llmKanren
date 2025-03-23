from .llm import generate_solution
from .prompt import generate_prompt

def balance_parentheses(s: str) -> str:

    s_list = list(s)
    stack = []

    remove_indices = set()
    
    for i, char in enumerate(s_list):
        if char == '(':
            stack.append(i)
        elif char == ')':
            if stack:
                stack.pop()
            else:
                remove_indices.add(i)

    remove_indices.update(stack)

    return ''.join(ch for i, ch in enumerate(s_list) if i not in remove_indices)

def remove_trailing_newlines(s: str) -> str:
    return s.rstrip('\n')

def generate_corpus(logic_variables, definition, test_inputs, test_outputs, num_candidates=100):
    prompt = generate_prompt(logic_variables, definition, test_inputs, test_outputs)
    corpus = []

    for _ in range(num_candidates):
        solution = generate_solution(prompt)
        solution = balance_parentheses(solution)
        solution = remove_trailing_newlines(solution)
        corpus.append(solution)

    return "\n".join(corpus)