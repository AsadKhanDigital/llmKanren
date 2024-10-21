from collections import deque, defaultdict
from dotenv import load_dotenv
from openai import OpenAI

import sexpdata
import os

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def barliman_output(definition, test_cases):
    prompt = \
        f"""
        Given the following Scheme function definition which contains "hole(s)" represented by comma-prefixed capital letters:

        {definition}

        and the following test cases:

        {test_cases}

        Write out 100 possible implementations of the function that satisfy the test cases by filling in the holes with appropriate Scheme code.

        Output only the function definitions. Do not include other text or formatting.

        Do not include the ```scheme formatting in your response.
        """
    
    try:
        response = client.chat.completions.create(model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        n=1,
        temperature=0.85)
        output = response.choices[0].message.content.strip()
    except Exception as e:
        print(f"Error generating query: {e}")
        raise e
    
    return output

def node_type(expr):
    # Determine the type of the node
    if isinstance(expr, (int, float)):
        return 'num'
    elif expr == sexpdata.Symbol('#t') or expr == sexpdata.Symbol('#f'):
        return 'bool'
    elif isinstance(expr, sexpdata.Symbol):
        return 'var'
    elif isinstance(expr, sexpdata.Quoted):
        return 'quoted-datum'
    elif isinstance(expr, list):
        if len(expr) == 0:
            return 'nil'
        first = expr[0]
        if isinstance(first, sexpdata.Symbol):
            fname = first.value()
            if fname == 'define':
                return 'letrec'  # per the Scheme code, code as letrec
            elif fname == 'lambda':
                return 'lambda'
            elif fname == 'if':
                return 'if'
            elif fname == 'symbol?':
                return 'symbol?'
            elif fname == 'not':
                return 'not'
            elif fname == 'and':
                return 'and'
            elif fname == 'or':
                return 'or'
            elif fname == 'list':
                return 'list'
            elif fname == 'null?':
                return 'null?'
            elif fname == 'pair?':
                return 'pair?'
            elif fname == 'car':
                return 'car'
            elif fname == 'cdr':
                return 'cdr'
            elif fname == 'cons':
                return 'cons'
            elif fname == 'equal?':
                return 'equal?'
            elif fname == 'let':
                return 'let'
            elif fname == 'letrec':
                return 'letrec'
            elif fname == 'match':
                return 'match'
            else:
                # Assume it's an application
                return 'app'
        else:
            # First element is not a symbol; assume it's an application
            return 'app'
    else:
        # Unknown type
        return 'unknown'

def collect_ngrams(expr, context, n, ngrams):
    node_t = node_type(expr)
    # Create the n-gram
    ngram = tuple(context) + (node_t,)
    if len(ngram) == n:
        ngrams[ngram] += 1
    # Update context
    context.append(node_t)
    # Process children
    if isinstance(expr, list):
        if node_t == 'lambda':
            # (lambda params body)
            if len(expr) >= 3:
                body = expr[2]
                collect_ngrams(body, context, n, ngrams)
        elif node_t == 'if':
            # (if test conseq alt)
            if len(expr) >= 4:
                test = expr[1]
                conseq = expr[2]
                alt = expr[3]
                collect_ngrams(test, context, n, ngrams)
                collect_ngrams(conseq, context, n, ngrams)
                collect_ngrams(alt, context, n, ngrams)
        elif node_t == 'let':
            # (let bindings body)
            if len(expr) >= 3:
                bindings = expr[1]
                body = expr[2]
                # Bindings is a list of pairs
                for binding in bindings:
                    if len(binding) == 2:
                        var, val = binding
                        collect_ngrams(val, context, n, ngrams)
                collect_ngrams(body, context, n, ngrams)
        elif node_t == 'letrec':
            # (letrec ((var val) ...) body)
            if len(expr) >= 3:
                bindings = expr[1]
                body = expr[2]
                for binding in bindings:
                    if len(binding) == 2:
                        var, val = binding
                        collect_ngrams(val, context, n, ngrams)
                collect_ngrams(body, context, n, ngrams)
        elif node_t == 'cons':
            # (cons e1 e2)
            if len(expr) >= 3:
                e1 = expr[1]
                e2 = expr[2]
                collect_ngrams(e1, context, n, ngrams)
                collect_ngrams(e2, context, n, ngrams)
        elif node_t == 'app':
            for subexpr in expr:
                collect_ngrams(subexpr, context, n, ngrams)
        else:
            # Other special forms or functions
            for subexpr in expr[1:]:
                collect_ngrams(subexpr, context, n, ngrams)
    elif isinstance(expr, sexpdata.Quoted):
        # Handle quoted expressions if needed
        pass
    # Pop the current node type from context before returning
    context.pop()

def ngram_sort_key(item):
    ngram, count = item
    first_elem = ngram[0]
    return (first_elem, -count)

if __name__ == "__main__":

    n = int(input("Enter value of n for n-grams: "))

    ngrams = defaultdict(int)

    definition = \
        """
        ,A
        """
    
    test_cases = \
        """
        (concat '() '())
        '()

        (concat '(1 2 3) '(4 5 6))
        '(1 2 3 4 5 6)
        """

    output = barliman_output(definition, test_cases)

    definitions = output.strip().split('\n\n')

    for defn in definitions:
        defn = defn.strip()
        if not defn:
            continue
        try:
            # Ensure the definition is properly formatted for parsing
            expr = sexpdata.loads(defn)
            context = deque(maxlen=n-1)
            collect_ngrams(expr, context, n, ngrams)
        except Exception as e:
            print(f"Error parsing definition: {e}")
            continue

    # Now, sort the ngrams
    ngram_list = list(ngrams.items())

    ngram_list.sort(key=ngram_sort_key)

    # Output to statistics.scm
    with open('statistics.scm', 'w') as f:
        f.write('(')
        for ngram, count in ngram_list:
            ngram_str = ' '.join(ngram)
            f.write(f'(({ngram_str}) . {count}) ')
        f.write(')')