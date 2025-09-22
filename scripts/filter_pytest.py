"""Filter pytest output to show information for a specific test.

Reads pytest output from stdin and prints test run and summary information.
"""

import argparse
import re
import sys
import typing

import rich.box
import rich.console
import rich.panel

console = rich.console.Console()


def print_with_highlighting(line: str):
    # Define token-to-color mappings using Rich color names
    color_mapping = {
        "PASSED": "bright_green b",  # ANSI: \e[1;92m
        "XPASS": "bright_green b",  # ANSI: \e[1;92m
        "SKIPPED": "bright_yellow b",  # ANSI: \e[1;93m
        "XFAIL": "bright_yellow b",  # ANSI: \e[1;93m
        "WARNING": "bright_yellow b",  # ANSI: \e[1;93m
        "FAILED": "bright_red b",  # ANSI: \e[1;91m
        "ERROR": "bright_red b",  # ANSI: \e[1;91m
        "INFO": "bright_black b",  # ANSI: \e[1;90m (gray)
    }

    # Find all tokens and their positions
    tokens_found = [
        (match.start(), match.end(), token, color)
        for token, color in color_mapping.items()
        for match in re.finditer(rf"\b{re.escape(token)}\b", line)
    ]

    # If no tokens found, just use rich.print as before
    if not tokens_found:
        rich.print(line)
        return

    # Sort tokens by position
    tokens_found.sort(key=lambda x: x[0])

    # Build the line with Rich markup for tokens
    result_line = ""
    last_pos = 0

    for start, end, _, color in tokens_found:
        # Add text before the token (unchanged)
        result_line += line[last_pos:start]

        # Add the token with Rich markup
        result_line += f"[{color}]{line[start:end]}[/{color}]"
        last_pos = end

    # Add remaining text after the last token
    result_line += line[last_pos:]

    # Use rich.print which will handle both our markup and default highlighting
    rich.print(result_line)


def filter_pytest_output(test_name_with_path: str, lines: list[str]):  # noqa: C901, PLR0912, PLR0915
    """Filter pytest output for a specific test.

    Args:
        test_name_with_path: Name of the test to filter for, e.g. "tests/unit/component/foo.py::Bar::test_something[some_param]"
        lines: Input data
    """
    test_name = test_name_with_path.split("::", maxsplit=1)[-1]

    # Regex patterns
    begin_runs_regex = r"^==+ test session starts =="
    search_test_run_regex = rf"^(tests/.*::{re.escape(test_name).replace('::', r'(::|\.)')})(\s?.*)"
    print_test_run_until_regex = r"^(tests/.*::|==)"
    begin_summaries_regex = r"^==+ (FAILURES|ERRORS) =="
    search_test_summary_regex = rf"^_.*{re.escape(test_name).replace('::', r'(::|\.)')} _"
    print_test_summary_until_regex = r"^(--+ Captured log call --|__|==)"
    begin_short_summary_regex = r"^==+ short test summary info =="
    summary_test_regex = rf"^(ERROR|FAILED) tests/.*::{re.escape(test_name)}(?:\s|$)"
    summary_some_test_regex = r"^(ERROR|FAILED) tests/[^:]*::([^\s]+)(?:\s|$)"
    summary_stats_regex = r"^=+ \d+ x?(failed|xfailed|error|skipped|passed|xpassed)"

    # State tracking
    in_test_runs: bool = False
    printing_test_run: bool = False
    in_summaries: typing.Literal[False] | str = False
    in_short_summaries: typing.Literal[False] | str = False
    printing_test_summary: bool = False

    rich.print(
        rich.panel.Panel(
            test_name,
            style="b bright_red",
            border_style="bright_red",
            box=rich.box.DOUBLE,
            expand=False,
        )
    )

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
            if match := re.match(search_test_run_regex, line):
                printing_test_run = True
                console.print(match.group(1), style="bright_red", end="")
                console.print(match.group(2))
                continue

            # If we're printing a test run, check if we should stop
            if printing_test_run:
                if re.match(print_test_run_until_regex, line):
                    printing_test_run = False
                else:
                    print_with_highlighting(line)
                continue

        # Handle summaries section
        if in_summaries:
            # Check if this line matches our target test summary
            if re.match(search_test_summary_regex, line):
                printing_test_summary = True
                console.print(in_summaries, style="b bright_red")
                print_with_highlighting(line)
                continue

            # If we're printing a test summary, check if we should stop
            if printing_test_summary:
                if re.match(print_test_summary_until_regex, line):
                    in_summaries = False
                    printing_test_summary = False
                else:
                    print_with_highlighting(line)
                    continue

        if re.match(begin_short_summary_regex, line):
            in_short_summaries = line
            continue

        if in_short_summaries:
            if re.match(summary_test_regex, line):
                printing_test_summary = True
                console.print(in_short_summaries, style="b bright_red")
                print_with_highlighting(line)
                continue

            if printing_test_summary:
                if re.match(summary_some_test_regex, line) or re.match(summary_stats_regex, line):
                    in_short_summaries = False
                    printing_test_summary = False
                    continue
                print_with_highlighting(line)


def intermediate_pytest_output(lines: list[str]):  # noqa: C901, PLR0912, PLR0915
    # Regex patterns
    begin_runs_regex = r"^==+ test session starts =="
    search_test_run_regex = (
        r"^(tests/[^:]*::[^\s]+)(?:\s+(PASSED|XPASS|ERROR|FAILED|XFAIL|SKIPPED|RERUN)(?:\s|$)|\s|$)"
    )
    run_result_regex = r"^(PASSED|XPASS|ERROR|FAILED|XFAIL|SKIPPED|RERUN)(?:\s|$)"
    print_test_run_until_regex = r"^(tests/.*::|==)"
    summary_stats_regex = r"^=+ \d+ x?(failed|xfailed|error|skipped|passed|xpassed)"

    # State tracking
    runs_started = False
    current_test = None
    test_started = False
    in_summary = False

    passed_counter = 0

    def print_passed():
        nonlocal passed_counter
        if passed_counter > 0:
            print("PASSED", f"{passed_counter} tests")
            passed_counter = 0

    def print_info(status: str, test_name: str):
        nonlocal passed_counter
        if status == "RERUN":
            return
        if status == "PASSED":
            passed_counter += 1
        else:
            print_passed()
            print(status, test_name)

    for line_ in lines:
        line = line_.rstrip("\n")

        if re.match(begin_runs_regex, line):
            runs_started = True
            continue
        if not runs_started:
            continue

        if re.match(summary_stats_regex, line):
            print_passed()
            print(line)
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
            print_passed()
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
