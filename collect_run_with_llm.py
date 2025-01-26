#!/usr/bin/env python3
import re
import subprocess
import tempfile
import os
from gen_solutions import gen_corpus  # Assuming your corpus generation code is in llm_corpus.py

def main():
    import sys
    if len(sys.argv) < 2:
        print("Usage: python collect_run_with_llm.py <scheme-file> [<output-csv>]")
        sys.exit(1)

    scheme_file = sys.argv[1]
    output_csv_file = None
    if len(sys.argv) > 2:
        output_csv_file = sys.argv[2]

    real_time_re = re.compile(r'^\s*([\d\.]+)s\s+elapsed real time')
    inc_count_re = re.compile(r'^Inc-count:\s+(\d+)')
    evalo_count_re = re.compile(r'^Evalo-count:\s+(\d+)')

    with open(scheme_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    run_with_llm_blocks = []
    capturing = False
    paren_depth = 0
    current_block = []

    for line in lines:
        if not capturing:
            if '(run-with-llm' in line:
                capturing = True
                current_block = []
                paren_depth = 0

        if capturing:
            current_block.append(line)
            paren_depth += line.count('(')
            paren_depth -= line.count(')')
            if paren_depth <= 0:
                block_text = "".join(current_block)
                run_with_llm_blocks.append(block_text)
                capturing = False
                current_block = []
                paren_depth = 0

    os.makedirs("outputs", exist_ok=True)
    results = []
    test_id = 0

    def parse_block(block):
        try:
            params = re.findall(r"'\((.*?)\)\)\s*\n", block, re.DOTALL)
            if len(params) >= 4:
                logic_vars = params[0].replace('\n', ' ').strip()
                definitions = params[1].replace('\n', ' ').strip()
                test_inputs = params[2].replace('\n', ' ').strip()
                test_outputs = params[3].replace('\n', ' ').strip()
                return logic_vars, definitions, test_inputs, test_outputs
        except Exception as e:
            print(f"Error parsing block: {e}")
        return None, None, None, None

    def make_scheme_content(block, approach):
        new_block = block.replace("(run-with-llm", f"(run-with-{approach}", 1)
        return f'(load "run-with-{approach}.scm")\n\n{new_block}\n(exit)\n'

    def run_test(block_str, approach, num_cand, test_id):
        llm_time = "N/A"
        query_time = "N/A"
        inc_count = "N/A"
        evalo_count = "N/A"
        captured_output = ""
        success = False
        attempt_count = 0

        while attempt_count < 5 and not success:
            attempt_count += 1
            with tempfile.NamedTemporaryFile(mode='w', suffix=".scm", delete=False) as tmpf:
                tmpfilename = tmpf.name
                tmpf.write(block_str)

            try:
                proc = subprocess.run(["chez", tmpfilename],
                                    capture_output=True, text=True)
                output = proc.stdout
                error_output = proc.stderr
                captured_output = output + "\n" + error_output
            finally:
                os.remove(tmpfilename)

            if "Exception in memv: improper list #f" in captured_output:
                continue

            lines_out = captured_output.splitlines()
            times_found = []
            for ln in lines_out:
                m_time = real_time_re.search(ln)
                if m_time:
                    times_found.append(m_time.group(1))

                m_inc = inc_count_re.search(ln)
                if m_inc:
                    inc_count = m_inc.group(1)

                m_evalo = evalo_count_re.search(ln)
                if m_evalo:
                    evalo_count = m_evalo.group(1)

            if approach == "llm":
                if len(times_found) > 0:
                    llm_time = times_found[0]
                if len(times_found) > 1:
                    query_time = times_found[1]
            else:
                if len(times_found) > 0:
                    query_time = times_found[0]

            success = True

        log_filename = f"outputs/test_{test_id}_{approach}_{num_cand if num_cand else 'na'}.log"
        with open(log_filename, "w", encoding="utf-8") as lf:
            lf.write(captured_output)

        return (llm_time, query_time, inc_count, evalo_count)

    approaches = [
        ("llm", 10),
        ("llm", 50),
        ("zinkov", None),
        ("expert", None),
    ]

    for block in run_with_llm_blocks:
        test_id += 1
        logic_vars, definitions, test_inputs, test_outputs = parse_block(block)
        
        if None in [logic_vars, definitions, test_inputs, test_outputs]:
            print(f"Skipping malformed block {test_id}")
            continue

        for approach, num_cand in approaches:
            if approach == "llm":
                gen_corpus(
                    logic_vars,
                    f"(lambda ({logic_vars}) {definitions})",  # Adjusted to match corpus format
                    test_inputs,
                    test_outputs,
                    num_candidates=num_cand
                )
                scheme_text = make_scheme_content(block, "llm")
            else:
                scheme_text = make_scheme_content(block, approach)

            llm_time, query_time, inc_count, evalo_count = run_test(
                scheme_text, approach, num_cand, test_id
            )
            
            results.append((
                test_id,
                approach,
                num_cand if approach == "llm" else "N/A",
                llm_time,
                query_time,
                inc_count,
                evalo_count
            ))

    csv_lines = [
        "test_id,approach,num_candidates,llm_time,query_time,inc_count,evalo_count"
    ]
    for row in results:
        tid, approach, num_cand, t_llm, t_query, inc, evc = row
        csv_lines.append(
            f"{tid},{approach},{num_cand},{t_llm},{t_query},{inc},{evc}"
        )

    if output_csv_file:
        with open(output_csv_file, 'w', encoding='utf-8') as outf:
            outf.write("\n".join(csv_lines))
    else:
        print("\n".join(csv_lines))

if __name__ == "__main__":
    main()