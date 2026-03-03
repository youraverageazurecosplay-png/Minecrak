import os
import shutil
import sys
import threading
import time
from contextlib import contextmanager

from .constants import ANSI


class Spinner:
    def __init__(self, message: str):
        self.message = message
        self._stop = threading.Event()
        self._thread = None

    def start(self):
        self._thread = threading.Thread(target=self._spin, daemon=True)
        self._thread.start()

    def stop(self, final_message: str | None = None):
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=1)
        if final_message:
            sys.stdout.write(f"\r{final_message}\n")
        else:
            sys.stdout.write("\n")
        sys.stdout.flush()

    def _spin(self):
        frames = [".", "..", "..."]
        idx = 0
        while not self._stop.is_set():
            sys.stdout.write(f"\r{ANSI['dim']}{self.message}{frames[idx % len(frames)]}{ANSI['reset']}")
            sys.stdout.flush()
            idx += 1
            time.sleep(0.35)


def clear_screen():
    os.system("clear")


def term_width(default: int = 100) -> int:
    return shutil.get_terminal_size((default, 25)).columns


def center_line(text: str, width: int | None = None) -> str:
    w = width or term_width()
    return text.center(w)


def divider(char: str = "-") -> str:
    return char * term_width()


def _truncate(s: str, max_len: int) -> str:
    if len(s) <= max_len:
        return s
    return s[: max_len - 3] + "..."


def box(title: str, lines: list[str], color: str = "cyan") -> str:
    w = min(100, term_width() - 2)
    inner = w - 4
    top = f"+{'-' * (w - 2)}+"
    title_text = _truncate(f" {title} ", inner)
    title_row = f"| {title_text.ljust(inner)} |"
    body = [f"| {_truncate(line, inner).ljust(inner)} |" for line in lines]
    bottom = top
    paint = ANSI.get(color, "")
    reset = ANSI["reset"]
    return "\n".join([f"{paint}{top}", title_row, *body, bottom, reset])


def print_header(title: str, subtitle: str = ""):
    print(ANSI["blue"] + divider("=") + ANSI["reset"])
    print(ANSI["bold"] + ANSI["cyan"] + center_line(title) + ANSI["reset"])
    if subtitle:
        print(ANSI["dim"] + center_line(subtitle) + ANSI["reset"])
    print(ANSI["blue"] + divider("=") + ANSI["reset"])


def print_error(message: str):
    print(f"{ANSI['red']}[error]{ANSI['reset']} {message}")


def print_success(message: str):
    print(f"{ANSI['green']}[ok]{ANSI['reset']} {message}")


def print_info(message: str):
    print(f"{ANSI['magenta']}[info]{ANSI['reset']} {message}")


def prompt(prompt_text: str, default: str | None = None) -> str:
    suffix = f" [{default}]" if default else ""
    value = input(f"{ANSI['yellow']}{prompt_text}{suffix}: {ANSI['reset']}").strip()
    return value or (default or "")


def choose_from_menu(title: str, options: list[str]) -> int:
    while True:
        clear_screen()
        print_header("Minecrak Dev Launcher", title)
        lines = [f"{i + 1}. {opt}" for i, opt in enumerate(options)]
        lines.append("0. Back / Exit")
        print(box("Menu", lines, color="cyan"))
        value = input(f"{ANSI['yellow']}Select option: {ANSI['reset']}").strip()
        if value.isdigit():
            idx = int(value)
            if 0 <= idx <= len(options):
                return idx
        print_error("Invalid selection. Press Enter to try again.")
        input()


@contextmanager
def spinning(message: str):
    spinner = Spinner(message)
    spinner.start()
    try:
        yield
    finally:
        spinner.stop()
