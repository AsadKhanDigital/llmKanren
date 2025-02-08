from dotenv import load_dotenv
from openai import OpenAI

import os

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Generate candidate solutions for the provided scheme definition given defined logic variables and sample test cases
def gen_solutions(logic_variables, definitions, test_inputs, test_outputs, num_candidates=50):

    prompt = \
        f"Here is the incomplete definition of a scheme function that contains logical holes:\n\n{definitions}\n\n" + \
        f"Given the following logic variables: {logic_variables}\n\n" + \
        f"Based on the following inputs: {test_inputs}\n\n" + \
        f"The complete definition should produce the following output for each respective test case: {test_outputs}\n\n" + \
        f"Generate {num_candidates} different valid candidate solutions to the function definition in the form of lambda expressions (with definitions) for it.\n\n" + \
        """
        \n
        Use only the following subset of scheme, do not use any other functions or constructs:
        - 'define'
        - 'letrec'
        - 'lambda'
        - 'if'
        - 'symbol?'
        - 'not'
        - 'and'
        - 'or'
        - 'list'
        - 'null?'
        - 'pair?'
        - 'car'
        - 'cdr'
        - 'cons'
        - 'equal?'
        - 'let'
        - 'match'
        - 'quote'
        - function application
        """ + \
        "\n\n Output only the function definitions. Do not include other text or formatting." + \
        "\n\nDo not include the ```scheme formatting in your response." + \
        "\n\nMake sure that all parantheses are balanced and there are no missing or extra parantheses." + \
        "\n\nDo not use recursion in your solutions."

    try:
    
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.9
        )

    except Exception as e:
        print(e)
        return None

    return response.choices[0].message.content.strip()

# Ensure solutions generated have balanced parentheses
def balance_parentheses(s):
    stack = []
    s = list(s)
    for i in range(len(s)):
        if s[i] == '(':
            stack.append(i)
        elif s[i] == ')':
            if stack:
                stack.pop()
            else:
                s[i] = '' 
    while stack:
        s[stack.pop()] = ''
    return ''.join(s)

def gen_corpus(logic_variables, definitions, test_inputs, test_outputs, num_candidates=10):
    solutions = gen_solutions(logic_variables, definitions, test_inputs, test_outputs, num_candidates)
    solutions = balance_parentheses(solutions)
    
    with open("corpus.scm", "w") as f:
        f.write("(define exprs\n")
        f.write("  '(\n")
        f.write(solutions)
        f.write("\n))")