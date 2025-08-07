"""Filter pytest output to show information for a specific test.

Reads pytest output from stdin and prints test run and summary information.
"""

import argparse
import re
import sys


def filter_pytest_output(test_name: str, lines: list[str]):  # noqa: C901, PLR0912
    """Filter pytest output for a specific test.

    Args:
        test_name: Name of the test to filter for
        lines: Input data
    """
    # Regex patterns
    begin_runs_regex = r"^==+ test session starts =="
    search_test_run_regex = rf"^tests/.*::{re.escape(test_name)}\s*"
    print_test_run_until_regex = r"^(tests/.*::|==)"
    begin_summaries_regex = r"^==+ (FAILURES|ERRORS) =="
    search_test_summary_regex = rf"^__.*{re.escape(test_name)} __"
    print_test_summary_until_regex = r"^(--+ Captured log call --|__|==)"

    # State tracking
    in_test_runs = False
    printing_test_run = False
    in_summaries: bool | str = False
    printing_test_summary = False

    for line_ in lines:
        line = line_.rstrip("\n")

        # Check if we're entering test runs section
        if re.match(begin_runs_regex, line):
            in_test_runs = True
            in_summaries = False
            continue

        # Check if we're entering summaries section
        if re.match(begin_summaries_regex, line):
            in_test_runs = False
            in_summaries = line
            continue

        # Handle test runs section
        if in_test_runs:
            # Check if this line matches our target test
            if re.match(search_test_run_regex, line):
                printing_test_run = True
                print(line, flush=True)
                continue

            # If we're printing a test run, check if we should stop
            if printing_test_run:
                if re.match(print_test_run_until_regex, line):
                    printing_test_run = False
                else:
                    print(line, flush=True)
                continue

        # Handle summaries section
        if in_summaries:
            # Check if this line matches our target test summary
            if re.match(search_test_summary_regex, line):
                printing_test_summary = True
                print(in_summaries)
                print(line, flush=True)
                continue

            # If we're printing a test summary, check if we should stop
            if printing_test_summary:
                if re.match(print_test_summary_until_regex, line):
                    printing_test_summary = False
                else:
                    print(line, flush=True)
                continue


def intermediate_pytest_output(lines: list[str]):  # noqa: C901, PLR0912, PLR0915
    # Regex patterns
    begin_runs_regex = r"^==+ test session starts =="
    search_test_run_regex = r"^tests/[^:]*::([^\s]+)(?:\s+(PASSED|ERROR|FAILED|SKIPPED)\s|\s|$)"
    run_result_regex = r"^(PASSED|ERROR|FAILED|SKIPPED)\s"
    print_test_run_until_regex = r"^(tests/.*::|==)"
    summary_stats_regex = r"^==+ \d+ x?(failed|error|skipped|passed)"

    # State tracking
    runs_started = False
    current_test = None
    test_started = False
    in_summary = False

    passed_counter = 0

    def print_info(status: str, test_name: str):
        nonlocal passed_counter
        if status == "PASSED":
            passed_counter += 1
        else:
            if passed_counter > 0:
                print("PASSED", f"{passed_counter} tests", flush=True)
                passed_counter = 0
            print(status, test_name, flush=True)

    for line_ in lines:
        line = line_.rstrip("\n")

        if re.match(begin_runs_regex, line):
            runs_started = True
            continue
        if not runs_started:
            continue

        if re.match(summary_stats_regex, line):
            print(line, file=sys.stderr, flush=True)
            break

        if in_summary:
            continue

        # Check if a test is starting
        if match := re.match(search_test_run_regex, line):
            # If we had a previous test that didn't complete, mark it as UNKNOWN
            if current_test and test_started:
                print_info("UNKNOWN", current_test)

            current_test = match.group(1)
            if status := match.group(2):
                print_info(status, current_test)
                test_started = False
            else:
                test_started = True
            continue

        # Check if we have a test result
        if match := re.match(run_result_regex, line):
            if current_test and test_started:
                result = match.group(1)
                print_info(result, current_test)
                current_test = None
                test_started = False
            continue

        # Stop processing when we hit the summary section or end
        if re.match(print_test_run_until_regex, line):
            in_summary = True
            continue

    # Handle case where output ends without reaching end of run
    if current_test and test_started:
        print_info("RUNNING", current_test)


def main():
    parser = argparse.ArgumentParser(
        description="Filter pytest output for a specific test",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example usage:
  pytest -v | python filter-pytest.py test_example
  python -m pytest tests/ | python filter-pytest.py my_test_function
        """,
    )
    parser.add_argument(
        "test_name",
        nargs="*",
        default=None,
        help="Name of the test(s) to filter for (without test_ prefix if not included)",
    )

    args = parser.parse_args()

    try:
        lines = sys.stdin.readlines()
        if not args.test_name:
            intermediate_pytest_output(lines)
        else:
            for test_name in args.test_name:
                filter_pytest_output(test_name, lines)
    except KeyboardInterrupt:
        sys.exit(1)
    except BrokenPipeError:
        # Handle broken pipe gracefully (e.g., when piping to head)
        sys.exit(0)


if __name__ == "__main__":
    main()
