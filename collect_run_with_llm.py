#!/usr/bin/env python3
import re
import subprocess
import tempfile
import os

def main():
    import sys
    if len(sys.argv) < 2:
        print("Usage: python collect_run_with_llm.py <scheme-file> [<output-csv>]")
        sys.exit(1)

    scheme_file = sys.argv[1]
    output_csv_file = None
    if len(sys.argv) > 2:
        output_csv_file = sys.argv[2]

    # Regex to match lines like: "5.765126000s elapsed real time"
    real_time_re = re.compile(r'^\s*([\d\.]+)s\s+elapsed real time')

    # Regexes to match counts:
    #   "Inc-count: 150555"
    #   "Evalo-count: 441"
    inc_count_re = re.compile(r'^Inc-count:\s+(\d+)')
    evalo_count_re = re.compile(r'^Evalo-count:\s+(\d+)')

    # 1) Read the Scheme file
    with open(scheme_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # 2) Gather (run-with-llm ...) blocks by tracking parentheses
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

    # Ensure outputs/ directory exists
    os.makedirs("outputs", exist_ok=True)

    # We store rows as: (test_id, approach, llm_time, query_time, inc_count, evalo_count)
    results = []
    test_id = 0

    def make_scheme_content(block, approach):
        """
        Replace the first '(run-with-llm' with '(run-with-<approach>'
        and load 'run-with-<approach>.scm'. 
        """
        new_block = block.replace("(run-with-llm", f"(run-with-{approach}", 1)
        return f'(load "run-with-{approach}.scm")\n\n{new_block}\n(exit)\n'

    def run_test(block_str, approach, test_id):
        """
        Run Chez up to 5 times if we get the known "Exception in memv: improper list #f" error.
        Parse times according to approach:
          - llm: first time => llm_time, second => query_time
          - zinkov/expert: first time => query_time, llm_time => N/A
        Return (llm_time, query_time, inc_count, evalo_count).
        """
        attempt_count = 0
        captured_output = ""
        llm_time = "N/A"
        query_time = "N/A"
        inc_count = "N/A"
        evalo_count = "N/A"
        success = False

        while attempt_count < 5 and not success:
            attempt_count += 1

            # Write the Scheme code to a temp file
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
                # Retry
                continue

            # Parse times and counters
            lines_out = captured_output.splitlines()

            # We track times differently depending on approach
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

            # Approach-based logic
            if approach == "llm":
                # Expect up to two times, if found
                if len(times_found) > 0:
                    llm_time = times_found[0]
                if len(times_found) > 1:
                    query_time = times_found[1]
            else:
                # zinkov or expert
                # The first time is the query time, LLM time = N/A
                if len(times_found) > 0:
                    query_time = times_found[0]

            success = True

        # Write the output to outputs/test_<test_id>_<approach>.log
        log_filename = f"outputs/test_{test_id}_{approach}.log"
        with open(log_filename, "w", encoding="utf-8") as lf:
            lf.write(captured_output)

        return (llm_time, query_time, inc_count, evalo_count)

    # 4) For each run-with-llm block, create 3 runs: llm, zinkov, expert
    for block in run_with_llm_blocks:
        test_id += 1

        for approach in ["llm", "zinkov", "expert"]:
            scheme_text = make_scheme_content(block, approach)
            llm_time, query_time, inc_count, evalo_count = run_test(
                scheme_text, approach, test_id
            )

            results.append((test_id, approach, llm_time, query_time, inc_count, evalo_count))

    # 5) Produce CSV
    csv_lines = []
    csv_lines.append("test_id,approach,llm_time,query_time,inc_count,evalo_count")
    for row in results:
        tid, approach, t_llm, t_query, inc, evc = row
        csv_lines.append(f"{tid},{approach},{t_llm},{t_query},{inc},{evc}")

    csv_content = "\n".join(csv_lines) + "\n"
    if output_csv_file:
        with open(output_csv_file, 'w', encoding='utf-8') as outf:
            outf.write(csv_content)
    else:
        print(csv_content)

if __name__ == "__main__":
    main()
