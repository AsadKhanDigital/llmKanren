from string import Template

PROMPT = Template(
    "<system>You are an expert Scheme programmer tasked with synthesizing a function that satisfies given test cases. The function contains logical gaps represented by logic variables. Your task is to analyze the function and synthesize a valid candidate solution that satisfies the test cases. You must adhere strictly to a specific subset of Scheme functions and output ONLY the final function definition without any formatting.</system>\n\n" \

    "IMPORTANT: Your solution MUST ONLY USE the following subset of Scheme without exception:\n\n" \
    "'define'\n\n" \
    "'letrec' (you are not allowed to use let)\n\n" \
    "'lambda'\n\n" \
    "'if'\n\n" \
    "'symbol?'\n\n" \
    "'not'\n\n" \
    "'and'\n\n" \
    "'or'\n\n" \
    "'list'\n\n" \
    "'null?'\n\n" \
    "'pair?'\n\n" \
    "'car'\n\n" \
    "'cdr'\n\n" \
    "'cons'\n\n" \
    "'equal?'\n\n" \
    "'let'\n\n" \
    "'match'\n\n" \
    "'quote'\n\n" \
    "function application\n\n" \
    "Any use of functions or constructs not in this list will invalidate the solution.\n\n" \

    "Analyze this Scheme function with logical gaps:\n\n" \

    "Logic Variables: $logic_variables\n" \
    "Definition: $definition\n" \
    "Input Test Cases:\n" \
    "$test_inputs\n" \
    "Output Test Cases:\n" \
    "$test_outputs\n\n" \

    "Synthesize a valid candidate solution adhering to these constraints:\n\n" \
    "Valid Scheme expression\n\n" \
    "Complete function definition as a lambda expression\n\n" \
    "No recursion\n\n" \
    "No logical gaps or logic variables\n\n" \
    "Syntactically correct with balanced parentheses\n\n" \
    "ONLY uses the specified subset of Scheme functions\n\n" \

    "Rigorously review your solution to ensure it only uses the allowed functions.\n\n" \

    "If the solution uses any function outside the specified subset, revise it.\n\n" \

    "Once you are certain your solution is valid and only uses the allowed functions, output ONLY the function definition as plain text, without any additional text, confirmations, formatting, or code blocks.\n\n" \

    "Your output must be the raw Scheme function definition, without any markdown formatting, code blocks, or additional text. It should start with an opening parenthesis and end with a closing parenthesis, with no other characters before or after."
)

def generate_prompt(logic_variables, definition, test_inputs, test_outputs):

    generated_prompt = PROMPT.substitute(
        logic_variables=logic_variables,
        definition=definition,
        test_inputs=test_inputs,
        test_outputs=test_outputs
    )

    return generated_prompt