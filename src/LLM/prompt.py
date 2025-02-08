from string import Template

PROMPT = Template(
    "<system>You are an expert in Scheme programming and have been tasked with synthesizing a function that satisfies a set of test cases. The function contains logical gaps represented by logic variables. Your task is to analyze the function and synthesize a valid candidate solution that satisfies the test cases.</system>\n\n\n" \

    "1. Analyze the following Scheme function containing logical gaps represented by logic variables. The function must satisfy a set of test cases represented by a series of inputs and their respective outputs:\n\n" \

    "Logic Variables: $logic_variables\n" \
    "Definition: $definition\n"
    "Input Test Cases:\n" \
    "$test_inputs\n" \
    "Output Test Cases:\n" \
    "$test_outputs\n\n\n" \

    "2. Synthesize a valid candidate solution for the function that satisfies the test cases while adhering closely to the following constraints:\n\n" \
    "- The solution must be a valid Scheme expression.\n" \
    "- The solution must be a complete function definition in the form of a lambda expression.\n" \
    "- The solution must contain only the function definition without any other text or formatting.\n" \
    "- The solution must not use recursion. \n" \
    "- The solution must not contain any logical gaps or logic variables.\n" \
    "- The solution must not use the ```scheme ``` tag or any other formatting.\n" \
    "- The solution must only use the following subset of Scheme without using any other functions or constructs:" \
    "- The solution must be syntactically correct and contain balanced parantheses.\n" \
    """
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
    """
    "3. Ensure that the synthesized solution is a valid Scheme expression and is syntatically correct with balanced parantheses.\n" \
)

def generate_prompt(logic_variables, definition, test_inputs, test_outputs):

    generated_prompt = PROMPT.substitute(
        logic_variables=logic_variables,
        definition=definition,
        test_inputs=test_inputs,
        test_outputs=test_outputs
    )

    return generated_prompt