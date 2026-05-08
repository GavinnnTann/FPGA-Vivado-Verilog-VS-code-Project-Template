#!/usr/bin/env python3
"""
FPGA Project Setup GUI
Reads and writes scripts/config.tcl and scripts/build.ps1.
Run from any directory:  python scripts/setup.py
"""

import os
import re
import subprocess
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext, ttk
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
CONFIG_TCL = SCRIPT_DIR / "config.tcl"
BUILD_PS1 = SCRIPT_DIR / "build.ps1"
SRC_DIR = PROJECT_ROOT / "src_main"
CONSTRAINTS_DIR = PROJECT_ROOT / "constraints"
BOARDS_DIR = PROJECT_ROOT / "boards"

# Folders shown in the Project Files tab (relative to PROJECT_ROOT)
EXPLORER_ROOTS = ["src_main", "src", "constraints", "testbench", "scripts", "boards"]

VIVADO_SEARCH_ROOTS = [
    r"C:\Xilinx\Vivado",
    r"C:\AMD\Vivado",
    r"C:\Program Files\Xilinx\Vivado",
]

VERILOG_TEMPLATE = """\
`timescale 1ns / 1ps
module {module_name}(
    input wire clk,
    // TODO: add your ports here
    output wire led
);

    // TODO: your logic here
    assign led = 1'b0;

endmodule
"""

XDC_MINIMAL = """\
## Constraint file for {project_name}
## Uncomment and rename ports as needed

## Clock (always required)
set_property -dict {{ PACKAGE_PIN {clock_pin} IOSTANDARD LVCMOS33 }} [get_ports {{ clk }}];
create_clock -add -name sys_clk_pin -period {clock_period} -waveform {{0 {clock_half}}} [get_ports {{clk}}];
"""


# ---------------------------------------------------------------------------
# Board I/O
# ---------------------------------------------------------------------------

def _parse_str(text: str, key: str, default: str) -> str:
    m = re.search(rf"^\s*set\s+{key}\s+\"([^\"]*)\"", text, re.MULTILINE)
    return m.group(1) if m else default


def _parse_list_tcl(text: str, key: str) -> list[str]:
    m = re.search(rf"^\s*set\s+{key}\s+\[list\s+(.*?)\]", text, re.MULTILINE)
    if m:
        return re.findall(r'"([^"]+)"', m.group(1))
    m = re.search(rf"^\s*set\s+{key}\s+\"([^\"]*)\"", text, re.MULTILINE)
    return [m.group(1)] if m else []


def read_board_info(board_dir: Path) -> dict:
    board_tcl = board_dir / "board.tcl"
    if not board_tcl.exists():
        return {}
    text = board_tcl.read_text(encoding="utf-8")
    return {
        "display": _parse_str(text, "BOARD_DISPLAY_NAME", board_dir.name),
        "part":    _parse_str(text, "PART_NAME", ""),
        "clock":   _parse_str(text, "CLOCK_MHZ", ""),
        "clock_pin":    _parse_str(text, "CLOCK_PIN", ""),
        "clock_period": _parse_str(text, "CLOCK_PERIOD_NS", ""),
        "clock_half":   _parse_str(text, "CLOCK_HALF_NS", ""),
    }


def list_boards() -> list[tuple[str, str]]:
    """Returns [(dir_name, display_name), ...] sorted by dir_name."""
    result = []
    if BOARDS_DIR.exists():
        for entry in sorted(BOARDS_DIR.iterdir()):
            if entry.is_dir() and (entry / "board.tcl").exists():
                info = read_board_info(entry)
                result.append((entry.name, info.get("display", entry.name)))
    return result


# ---------------------------------------------------------------------------
# Config I/O
# ---------------------------------------------------------------------------

def read_config() -> dict:
    if not CONFIG_TCL.exists():
        return {
            "PROJECT_NAME": "cmod_a7_project",
            "TOP_MODULE": "top",
            "BOARD": "cmod_a7",
            "BUILD_DIR": "C:/fpga_build",
            "SOURCE_FILES": [],
            "CONSTRAINT_FILES": [],
        }
    text = CONFIG_TCL.read_text(encoding="utf-8")
    return {
        "PROJECT_NAME": _parse_str(text, "PROJECT_NAME", "cmod_a7_project"),
        "TOP_MODULE":   _parse_str(text, "TOP_MODULE", "top"),
        "BOARD":        _parse_str(text, "BOARD", "cmod_a7"),
        "BUILD_DIR":    _parse_str(text, "BUILD_DIR", "C:/fpga_build"),
        "SOURCE_FILES":     _parse_list_tcl(text, "SOURCE_FILES"),
        "CONSTRAINT_FILES": _parse_list_tcl(text, "CONSTRAINT_FILES"),
    }


def write_config(cfg: dict):
    if not CONFIG_TCL.exists():
        raise FileNotFoundError(f"config.tcl not found: {CONFIG_TCL}")
    text = CONFIG_TCL.read_text(encoding="utf-8")

    for key in ("PROJECT_NAME", "TOP_MODULE", "BOARD", "BUILD_DIR"):
        val = cfg[key]
        text = re.sub(
            rf'^(\s*set\s+{key}\s+)"[^"]*"',
            lambda m, v=val: f'{m.group(1)}"{v}"',
            text,
            flags=re.MULTILINE,
        )

    for key in ("SOURCE_FILES", "CONSTRAINT_FILES"):
        values = cfg[key]
        if len(values) == 1 and "*" in values[0]:
            new_val = f'"{values[0]}"'
        else:
            items = " ".join(f'"{v}"' for v in values)
            new_val = f"[list {items}]"
        text = re.sub(
            rf'^(\s*set\s+{key}\s+)(?:\[list[^\]]*\]|"[^"]*")',
            lambda m, v=new_val: f"{m.group(1)}{v}",
            text,
            flags=re.MULTILINE,
        )

    CONFIG_TCL.write_text(text, encoding="utf-8")


def read_vivado_path() -> str:
    if not BUILD_PS1.exists():
        return ""
    text = BUILD_PS1.read_text(encoding="utf-8")
    m = re.search(r'\[string\]\$VivadoPath\s*=\s*"([^"]+)"', text)
    return m.group(1) if m else ""


def write_vivado_path(path: str):
    if not BUILD_PS1.exists():
        raise FileNotFoundError(f"build.ps1 not found: {BUILD_PS1}")
    text = BUILD_PS1.read_text(encoding="utf-8")
    updated = re.sub(
        r'(\[string\]\$VivadoPath\s*=\s*)"[^"]*"',
        lambda m, v=path: f'{m.group(1)}"{v}"',
        text,
    )
    BUILD_PS1.write_text(updated, encoding="utf-8")


def find_vivado() -> str:
    found = []
    for root in VIVADO_SEARCH_ROOTS:
        if os.path.isdir(root):
            try:
                for entry in os.scandir(root):
                    if entry.is_dir():
                        bat = Path(entry.path) / "bin" / "vivado.bat"
                        if bat.exists():
                            found.append(str(bat))
            except PermissionError:
                pass
    found.sort(reverse=True)
    return found[0] if found else ""


def validate_setup(cfg: dict, vivado_path: str) -> list[tuple[str, bool, str]]:
    results = []

    ok = os.path.isfile(vivado_path)
    results.append(("Vivado executable", ok, vivado_path or "(not set)"))

    board_dir = BOARDS_DIR / cfg["BOARD"]
    ok = (board_dir / "board.tcl").exists()
    results.append((f"Board '{cfg['BOARD']}' defined", ok, str(board_dir / "board.tcl")))

    build_parent = Path(cfg["BUILD_DIR"]).parent
    ok = build_parent.exists()
    results.append(("Build directory parent exists", ok, str(build_parent)))

    for sf in cfg["SOURCE_FILES"]:
        if "*" in sf:
            matches = list(SRC_DIR.glob(sf))
            ok = len(matches) > 0
            detail = f"{len(matches)} file(s) matched" if ok else f"No matches in {SRC_DIR}"
        else:
            fp = SRC_DIR / sf
            ok = fp.exists()
            detail = str(fp)
        results.append((f"Source '{sf}'", ok, detail))

    top = cfg["TOP_MODULE"]
    found_module = False
    for sf in cfg["SOURCE_FILES"]:
        files = list(SRC_DIR.glob(sf)) if "*" in sf else [SRC_DIR / sf]
        for f in files:
            if f.exists():
                try:
                    content = f.read_text(encoding="utf-8", errors="ignore")
                    if re.search(rf"\bmodule\s+{re.escape(top)}\b", content):
                        found_module = True
                        break
                except OSError:
                    pass
        if found_module:
            break
    results.append((
        f"Top module '{top}' declared",
        found_module,
        "Found in source files" if found_module else "Not found in any source file",
    ))

    for cf in cfg["CONSTRAINT_FILES"]:
        if "*" in cf:
            matches = list(CONSTRAINTS_DIR.glob(cf))
            ok = len(matches) > 0
            detail = f"{len(matches)} file(s) matched"
        else:
            fp = CONSTRAINTS_DIR / cf
            ok = fp.exists()
            detail = str(fp)
        results.append((f"Constraint '{cf}'", ok, detail))

    return results


# ---------------------------------------------------------------------------
# GUI
# ---------------------------------------------------------------------------

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("FPGA Project Setup")
        self.resizable(True, True)
        self.minsize(540, 460)

        self._cfg = read_config()
        self._vivado_path = read_vivado_path()
        self._boards = list_boards()  # [(dir_name, display_name), ...]

        self._build_ui()
        self._populate()

    # -----------------------------------------------------------------------
    # UI construction
    # -----------------------------------------------------------------------

    def _build_ui(self):
        nb = ttk.Notebook(self)
        nb.pack(fill="both", expand=True, padx=10, pady=(10, 4))

        self._t_config    = ttk.Frame(nb, padding=12)
        self._t_workspace = ttk.Frame(nb, padding=12)
        self._t_scaffold  = ttk.Frame(nb, padding=12)
        self._t_validate  = ttk.Frame(nb, padding=12)
        self._t_explorer  = ttk.Frame(nb, padding=(6, 6))

        nb.add(self._t_config,    text="  Project Config  ")
        nb.add(self._t_workspace, text="  Workspace Setup  ")
        nb.add(self._t_scaffold,  text="  New Project  ")
        nb.add(self._t_validate,  text="  Validate  ")
        nb.add(self._t_explorer,  text="  Project Files  ")

        self._build_config_tab()
        self._build_workspace_tab()
        self._build_scaffold_tab()
        self._build_validate_tab()
        self._build_explorer_tab()

        nb.bind("<<NotebookTabChanged>>",
                lambda e: self._refresh_explorer() if nb.index("current") == 4 else None)

        self._status_var = tk.StringVar(value="Ready")
        ttk.Label(self, textvariable=self._status_var, relief="sunken",
                  anchor="w", padding=(6, 2)).pack(fill="x", side="bottom")

    # --- Project Config tab ---

    def _build_config_tab(self):
        f = self._t_config
        self._cv = {}
        r = 0

        # Simple text fields
        for label, key in [("Project name:", "PROJECT_NAME"), ("Top module:", "TOP_MODULE"),
                            ("Build directory:", "BUILD_DIR")]:
            ttk.Label(f, text=label, anchor="e", width=15).grid(
                row=r, column=0, sticky="e", pady=3, padx=(0, 4))
            v = tk.StringVar()
            self._cv[key] = v
            ttk.Entry(f, textvariable=v, width=42).grid(row=r, column=1, columnspan=2, sticky="ew")
            r += 1

        # Board selector
        ttk.Label(f, text="Board:", anchor="e", width=15).grid(
            row=r, column=0, sticky="e", pady=3, padx=(0, 4))
        board_displays = [d for _, d in self._boards] if self._boards else ["(no boards found)"]
        self._board_combo = ttk.Combobox(f, values=board_displays, state="readonly", width=39)
        self._board_combo.grid(row=r, column=1, columnspan=2, sticky="ew")
        self._board_combo.bind("<<ComboboxSelected>>", self._on_board_selected)
        r += 1

        self._board_info = ttk.Label(f, text="", foreground="gray")
        self._board_info.grid(row=r, column=1, columnspan=2, sticky="w", pady=(0, 6))
        r += 1

        ttk.Separator(f, orient="horizontal").grid(row=r, column=0, columnspan=3, sticky="ew", pady=6)
        r += 1

        # Source files
        ttk.Label(f, text="Source files  (src_main/)", font=("", 9, "bold")).grid(
            row=r, column=0, columnspan=3, sticky="w")
        r += 1
        self._src_lb, r = self._listbox_with_scroll(f, r, height=4)
        src_btns = ttk.Frame(f)
        src_btns.grid(row=r, column=0, columnspan=3, sticky="w", pady=(2, 6))
        ttk.Button(src_btns, text="Add file", command=self._add_src).pack(side="left", padx=(0, 4))
        ttk.Button(src_btns, text="Add all *.v", command=lambda: self._set_glob(self._src_lb, "*.v")).pack(side="left", padx=(0, 4))
        ttk.Button(src_btns, text="Remove selected", command=lambda: self._remove_sel(self._src_lb)).pack(side="left")
        r += 1

        ttk.Separator(f, orient="horizontal").grid(row=r, column=0, columnspan=3, sticky="ew", pady=6)
        r += 1

        # Constraint files
        ttk.Label(f, text="Constraint files  (constraints/)", font=("", 9, "bold")).grid(
            row=r, column=0, columnspan=3, sticky="w")
        r += 1
        self._xdc_lb, r = self._listbox_with_scroll(f, r, height=3)
        xdc_btns = ttk.Frame(f)
        xdc_btns.grid(row=r, column=0, columnspan=3, sticky="w", pady=(2, 6))
        ttk.Button(xdc_btns, text="Add file", command=self._add_xdc).pack(side="left", padx=(0, 4))
        ttk.Button(xdc_btns, text="Add all *.xdc", command=lambda: self._set_glob(self._xdc_lb, "*.xdc")).pack(side="left", padx=(0, 4))
        ttk.Button(xdc_btns, text="Remove selected", command=lambda: self._remove_sel(self._xdc_lb)).pack(side="left")
        r += 1

        ttk.Separator(f, orient="horizontal").grid(row=r, column=0, columnspan=3, sticky="ew", pady=6)
        r += 1

        bot = ttk.Frame(f)
        bot.grid(row=r, column=0, columnspan=3)
        ttk.Button(bot, text="Reload from file", command=self._reload).pack(side="left", padx=(0, 8))
        ttk.Button(bot, text="Save config.tcl", command=self._save_config).pack(side="left")

        f.columnconfigure(1, weight=1)

    def _listbox_with_scroll(self, parent, row: int, height: int):
        lb = tk.Listbox(parent, height=height, selectmode="extended",
                        font=("Consolas", 9), activestyle="none")
        lb.grid(row=row, column=0, columnspan=2, sticky="ew")
        sb = ttk.Scrollbar(parent, orient="vertical", command=lb.yview)
        sb.grid(row=row, column=2, sticky="ns")
        lb.configure(yscrollcommand=sb.set)
        return lb, row + 1

    def _on_board_selected(self, _event=None):
        idx = self._board_combo.current()
        if 0 <= idx < len(self._boards):
            board_key, _ = self._boards[idx]
            self._update_board_info(board_key)

    def _update_board_info(self, board_key: str):
        info = read_board_info(BOARDS_DIR / board_key)
        if info:
            self._board_info.configure(
                text=f"Part: {info['part']}  |  Clock: {info['clock']} MHz")
        else:
            self._board_info.configure(text="(board.tcl not found)")

    # --- Workspace Setup tab ---

    def _build_workspace_tab(self):
        f = self._t_workspace

        ttk.Label(f, text="Vivado Installation Path", font=("", 10, "bold")).grid(
            row=0, column=0, columnspan=3, sticky="w", pady=(0, 10))

        ttk.Label(f, text="vivado.bat path:", anchor="e", width=15).grid(
            row=1, column=0, sticky="e", pady=3, padx=(0, 4))
        self._vivado_var = tk.StringVar()
        ttk.Entry(f, textvariable=self._vivado_var, width=40).grid(row=1, column=1, sticky="ew")
        ttk.Button(f, text="Browse", command=self._browse_vivado).grid(row=1, column=2, padx=(4, 0))

        btn_row = ttk.Frame(f)
        btn_row.grid(row=2, column=0, columnspan=3, sticky="w", pady=(8, 4))
        ttk.Button(btn_row, text="Auto-detect", command=self._autodetect).pack(side="left", padx=(0, 8))
        ttk.Button(btn_row, text="Save to build.ps1", command=self._save_vivado).pack(side="left")

        self._vivado_status = ttk.Label(f, text="", foreground="gray")
        self._vivado_status.grid(row=3, column=0, columnspan=3, sticky="w", pady=(4, 0))

        ttk.Separator(f, orient="horizontal").grid(row=4, column=0, columnspan=3, sticky="ew", pady=14)

        ttk.Label(f, text=("After saving, the path is written into the $VivadoPath default\n"
                            "in build.ps1. Run 'Build FPGA Design' from VS Code to confirm."),
                  foreground="gray", justify="left").grid(row=5, column=0, columnspan=3, sticky="w")

        f.columnconfigure(1, weight=1)

    # --- New Project (scaffold) tab ---

    def _build_scaffold_tab(self):
        f = self._t_scaffold
        self._sc = {}

        ttk.Label(f, text="Create a new project from scratch", font=("", 10, "bold")).grid(
            row=0, column=0, columnspan=3, sticky="w", pady=(0, 4))
        ttk.Label(f, text="Creates starter .v and .xdc files, then updates config.tcl.",
                  foreground="gray").grid(row=1, column=0, columnspan=3, sticky="w", pady=(0, 10))

        for row, (label, key) in enumerate([("Project name:", "name"), ("Top module:", "module")], start=2):
            ttk.Label(f, text=label, anchor="e", width=15).grid(row=row, column=0, sticky="e", pady=3, padx=(0, 4))
            v = tk.StringVar()
            self._sc[key] = v
            ttk.Entry(f, textvariable=v, width=36).grid(row=row, column=1, columnspan=2, sticky="ew")

        r = 4
        ttk.Label(f, text="XDC template:", anchor="e", width=15).grid(
            row=r, column=0, sticky="e", pady=3, padx=(0, 4))
        self._sc_xdc = tk.StringVar(value="Board reference (from boards/)")
        xdc_choices = ["Board reference (from boards/)", "DSL Starter Kit", "CMOD A7 only", "Blank (clock only)"]
        ttk.Combobox(f, textvariable=self._sc_xdc, state="readonly", width=33,
                     values=xdc_choices).grid(row=r, column=1, columnspan=2, sticky="ew")
        r += 1

        self._sc_flags = {
            "create_v":   tk.BooleanVar(value=True),
            "create_xdc": tk.BooleanVar(value=True),
            "update_cfg": tk.BooleanVar(value=True),
        }
        for key, label in [("create_v", "Create starter .v file in src_main/"),
                            ("create_xdc", "Create .xdc stub in constraints/"),
                            ("update_cfg", "Update config.tcl with these settings")]:
            ttk.Checkbutton(f, text=label, variable=self._sc_flags[key]).grid(
                row=r, column=0, columnspan=3, sticky="w", pady=2)
            r += 1

        ttk.Separator(f, orient="horizontal").grid(row=r, column=0, columnspan=3, sticky="ew", pady=10)
        r += 1
        ttk.Button(f, text="Create Project", command=self._scaffold).grid(
            row=r, column=0, columnspan=3, pady=(0, 8))
        r += 1

        self._sc_log = scrolledtext.ScrolledText(f, height=7, font=("Consolas", 9), state="disabled")
        self._sc_log.grid(row=r, column=0, columnspan=3, sticky="nsew")

        f.columnconfigure(1, weight=1)
        f.rowconfigure(r, weight=1)

    # --- Validate tab ---

    def _build_validate_tab(self):
        f = self._t_validate

        ttk.Label(f, text="Validate Setup", font=("", 10, "bold")).grid(
            row=0, column=0, sticky="w", pady=(0, 4))
        ttk.Label(f, text="Checks Vivado path, board config, source files, top module declaration, and constraints.",
                  foreground="gray").grid(row=1, column=0, sticky="w", pady=(0, 10))
        ttk.Button(f, text="Run Validation", command=self._validate).grid(
            row=2, column=0, sticky="w", pady=(0, 8))

        self._val_out = scrolledtext.ScrolledText(f, font=("Consolas", 9), state="disabled")
        self._val_out.grid(row=3, column=0, sticky="nsew")
        self._val_out.tag_configure("ok",     foreground="#1a7a1a")
        self._val_out.tag_configure("fail",   foreground="#cc0000")
        self._val_out.tag_configure("detail", foreground="gray")
        self._val_out.tag_configure("sep",    foreground="#888888")

        f.columnconfigure(0, weight=1)
        f.rowconfigure(3, weight=1)

    # --- Project Files (Explorer) tab ---

    def _build_explorer_tab(self):
        f = self._t_explorer

        toolbar = ttk.Frame(f)
        toolbar.pack(fill="x", pady=(0, 4))
        ttk.Label(toolbar, text="Project Files", font=("", 10, "bold")).pack(side="left")
        ttk.Button(toolbar, text="Refresh", command=self._refresh_explorer).pack(side="right")
        ttk.Button(toolbar, text="Open folder", command=self._open_project_folder).pack(side="right", padx=(0, 6))

        ttk.Label(f, text="Double-click a file to open it in VS Code",
                  foreground="gray", font=("", 8)).pack(anchor="w", pady=(0, 4))

        tree_frame = ttk.Frame(f)
        tree_frame.pack(fill="both", expand=True)

        self._tree = ttk.Treeview(tree_frame, columns=("size",), selectmode="browse")
        self._tree.heading("#0", text="Name", anchor="w")
        self._tree.heading("size", text="Size", anchor="e")
        self._tree.column("#0", stretch=True, minwidth=200)
        self._tree.column("size", width=70, stretch=False, anchor="e")

        vsb = ttk.Scrollbar(tree_frame, orient="vertical",   command=self._tree.yview)
        hsb = ttk.Scrollbar(tree_frame, orient="horizontal", command=self._tree.xview)
        self._tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

        self._tree.grid(row=0, column=0, sticky="nsew")
        vsb.grid(row=0, column=1, sticky="ns")
        hsb.grid(row=1, column=0, sticky="ew")
        tree_frame.rowconfigure(0, weight=1)
        tree_frame.columnconfigure(0, weight=1)

        self._tree.bind("<Double-1>", self._explorer_open)
        self._tree.bind("<Return>",   self._explorer_open)

        self._tree_menu = tk.Menu(self, tearoff=False)
        self._tree_menu.add_command(label="Open in VS Code",        command=self._explorer_open_selected)
        self._tree_menu.add_command(label="Open containing folder", command=self._explorer_open_dir)
        self._tree_menu.add_separator()
        self._tree_menu.add_command(label="Use as source file",     command=self._explorer_add_to_sources)
        self._tree_menu.add_command(label="Use as constraint file", command=self._explorer_add_to_constraints)
        self._tree.bind("<Button-3>", self._show_tree_menu)

        self._tree_paths: dict[str, Path] = {}
        self._refresh_explorer()

    def _refresh_explorer(self):
        self._tree.delete(*self._tree.get_children())
        self._tree_paths.clear()

        for folder_name in EXPLORER_ROOTS:
            folder = PROJECT_ROOT / folder_name
            if not folder.exists():
                continue
            node = self._tree.insert(
                "", "end",
                text=f"{folder_name}/",
                values=("",),
                open=folder_name in ("src_main", "constraints"),
            )
            self._tree_paths[node] = folder
            self._populate_tree(node, folder)

        root_files = ["scripts/config.tcl", "scripts/build.ps1", "README.md", ".gitignore"]
        root_node = self._tree.insert("", "end", text="(root)/", values=("",), open=False)
        for rel in root_files:
            fp = PROJECT_ROOT / rel
            if fp.exists():
                size = self._human_size(fp.stat().st_size)
                iid = self._tree.insert(root_node, "end", text=fp.name, values=(size,))
                self._tree_paths[iid] = fp

    def _populate_tree(self, parent_node: str, folder: Path):
        try:
            entries = sorted(folder.iterdir(), key=lambda p: (p.is_file(), p.name.lower()))
        except PermissionError:
            return
        for entry in entries:
            if entry.name.startswith("."):
                continue
            if entry.is_dir():
                node = self._tree.insert(parent_node, "end", text=f"{entry.name}/", values=("",))
                self._tree_paths[node] = entry
                self._populate_tree(node, entry)
            else:
                size = self._human_size(entry.stat().st_size)
                iid = self._tree.insert(parent_node, "end", text=entry.name, values=(size,))
                self._tree_paths[iid] = entry

    @staticmethod
    def _human_size(n: int) -> str:
        for unit in ("B", "KB", "MB"):
            if n < 1024:
                return f"{n} {unit}" if unit == "B" else f"{n:.1f} {unit}"
            n //= 1024
        return f"{n:.1f} GB"

    def _selected_path(self) -> Path | None:
        sel = self._tree.selection()
        return self._tree_paths.get(sel[0]) if sel else None

    def _explorer_open(self, _event=None):
        self._explorer_open_selected()

    def _explorer_open_selected(self):
        p = self._selected_path()
        if p and p.is_file():
            try:
                subprocess.Popen(["code", str(p)], shell=True)
            except Exception as exc:
                messagebox.showerror("Error", f"Could not open VS Code:\n{exc}")

    def _explorer_open_dir(self):
        p = self._selected_path()
        if p:
            target = p if p.is_dir() else p.parent
            subprocess.Popen(["explorer", str(target)], shell=True)

    def _open_project_folder(self):
        subprocess.Popen(["explorer", str(PROJECT_ROOT)], shell=True)

    def _explorer_add_to_sources(self):
        p = self._selected_path()
        if p and p.suffix.lower() in (".v", ".sv") and p.is_file():
            existing = set(self._src_lb.get(0, "end"))
            if p.name not in existing:
                self._src_lb.insert("end", p.name)
                self._set_status(f"Added '{p.name}' to source files — save config to apply.")
            else:
                self._set_status(f"'{p.name}' already in source list.")
        else:
            messagebox.showinfo("Not a Verilog file", "Select a .v or .sv file to add as a source.")

    def _explorer_add_to_constraints(self):
        p = self._selected_path()
        if p and p.suffix.lower() == ".xdc" and p.is_file():
            existing = set(self._xdc_lb.get(0, "end"))
            if p.name not in existing:
                self._xdc_lb.insert("end", p.name)
                self._set_status(f"Added '{p.name}' to constraints — save config to apply.")
            else:
                self._set_status(f"'{p.name}' already in constraint list.")
        else:
            messagebox.showinfo("Not an XDC file", "Select a .xdc file to add as a constraint.")

    def _show_tree_menu(self, event):
        iid = self._tree.identify_row(event.y)
        if iid:
            self._tree.selection_set(iid)
            p = self._tree_paths.get(iid)
            add_src = "normal" if p and p.suffix.lower() in (".v", ".sv") else "disabled"
            add_xdc = "normal" if p and p.suffix.lower() == ".xdc" else "disabled"
            self._tree_menu.entryconfigure("Use as source file",     state=add_src)
            self._tree_menu.entryconfigure("Use as constraint file", state=add_xdc)
            self._tree_menu.tk_popup(event.x_root, event.y_root)

    # -----------------------------------------------------------------------
    # Data binding
    # -----------------------------------------------------------------------

    def _populate(self):
        cfg = self._cfg
        self._cv["PROJECT_NAME"].set(cfg["PROJECT_NAME"])
        self._cv["TOP_MODULE"].set(cfg["TOP_MODULE"])
        self._cv["BUILD_DIR"].set(cfg["BUILD_DIR"])

        # Board dropdown
        board_key = cfg.get("BOARD", "cmod_a7")
        for i, (key, _) in enumerate(self._boards):
            if key == board_key:
                self._board_combo.current(i)
                self._update_board_info(key)
                break

        self._src_lb.delete(0, "end")
        for f in cfg["SOURCE_FILES"]:
            self._src_lb.insert("end", f)

        self._xdc_lb.delete(0, "end")
        for f in cfg["CONSTRAINT_FILES"]:
            self._xdc_lb.insert("end", f)

        self._vivado_var.set(self._vivado_path)
        self._refresh_vivado_status()

    def _reload(self):
        self._cfg = read_config()
        self._vivado_path = read_vivado_path()
        self._boards = list_boards()
        self._populate()
        self._set_status("Reloaded from config.tcl and build.ps1")

    # -----------------------------------------------------------------------
    # Config tab actions
    # -----------------------------------------------------------------------

    def _add_src(self):
        SRC_DIR.mkdir(parents=True, exist_ok=True)
        files = filedialog.askopenfilenames(
            title="Select Verilog source files",
            initialdir=str(SRC_DIR),
            filetypes=[("Verilog / SystemVerilog", "*.v *.sv"), ("All files", "*.*")],
        )
        existing = set(self._src_lb.get(0, "end"))
        for fp in files:
            name = Path(fp).name
            if name not in existing:
                self._src_lb.insert("end", name)
                existing.add(name)

    def _add_xdc(self):
        files = filedialog.askopenfilenames(
            title="Select constraint files",
            initialdir=str(CONSTRAINTS_DIR),
            filetypes=[("XDC files", "*.xdc"), ("All files", "*.*")],
        )
        existing = set(self._xdc_lb.get(0, "end"))
        for fp in files:
            name = Path(fp).name
            if name not in existing:
                self._xdc_lb.insert("end", name)
                existing.add(name)

    def _set_glob(self, lb: tk.Listbox, pattern: str):
        lb.delete(0, "end")
        lb.insert("end", pattern)

    def _remove_sel(self, lb: tk.Listbox):
        for idx in reversed(lb.curselection()):
            lb.delete(idx)

    def _selected_board_key(self) -> str:
        idx = self._board_combo.current()
        if 0 <= idx < len(self._boards):
            return self._boards[idx][0]
        return "cmod_a7"

    def _save_config(self):
        cfg = {
            "PROJECT_NAME":     self._cv["PROJECT_NAME"].get().strip(),
            "TOP_MODULE":       self._cv["TOP_MODULE"].get().strip(),
            "BOARD":            self._selected_board_key(),
            "BUILD_DIR":        self._cv["BUILD_DIR"].get().strip(),
            "SOURCE_FILES":     list(self._src_lb.get(0, "end")),
            "CONSTRAINT_FILES": list(self._xdc_lb.get(0, "end")),
        }
        if not cfg["PROJECT_NAME"] or not cfg["TOP_MODULE"]:
            messagebox.showerror("Validation error", "Project name and top module cannot be empty.")
            return
        if not cfg["SOURCE_FILES"]:
            if not messagebox.askyesno("No source files", "No source files listed. Save anyway?"):
                return
        try:
            write_config(cfg)
            self._cfg = cfg
            self._set_status(
                f"Saved  —  project: {cfg['PROJECT_NAME']}  |  top: {cfg['TOP_MODULE']}  |  board: {cfg['BOARD']}")
        except Exception as exc:
            messagebox.showerror("Save error", str(exc))

    # -----------------------------------------------------------------------
    # Workspace tab actions
    # -----------------------------------------------------------------------

    def _browse_vivado(self):
        path = filedialog.askopenfilename(
            title="Select vivado.bat",
            initialdir=r"C:\Xilinx",
            filetypes=[("Vivado batch file", "vivado.bat"), ("All files", "*.*")],
        )
        if path:
            self._vivado_var.set(path)
            self._refresh_vivado_status()

    def _autodetect(self):
        self._set_status("Searching for Vivado...")
        self.update_idletasks()
        path = find_vivado()
        if path:
            self._vivado_var.set(path)
            self._vivado_status.configure(text=f"Found: {path}", foreground="#1a7a1a")
            self._set_status("Vivado detected automatically")
        else:
            self._vivado_status.configure(
                text="Not found in common locations — browse manually.", foreground="#cc0000")
            self._set_status("Vivado not found automatically")

    def _refresh_vivado_status(self):
        path = self._vivado_var.get()
        if os.path.isfile(path):
            self._vivado_status.configure(text="OK — file exists", foreground="#1a7a1a")
        elif path:
            self._vivado_status.configure(text="File not found at this path", foreground="#cc0000")
        else:
            self._vivado_status.configure(text="No path configured", foreground="gray")

    def _save_vivado(self):
        path = self._vivado_var.get().strip()
        if not path:
            messagebox.showerror("Error", "Vivado path is empty.")
            return
        try:
            write_vivado_path(path)
            self._vivado_path = path
            self._refresh_vivado_status()
            self._set_status("Vivado path saved to build.ps1")
        except Exception as exc:
            messagebox.showerror("Save error", str(exc))

    # -----------------------------------------------------------------------
    # Scaffold tab actions
    # -----------------------------------------------------------------------

    def _scaffold(self):
        project = self._sc["name"].get().strip()
        module  = self._sc["module"].get().strip()
        if not project or not module:
            messagebox.showerror("Missing fields", "Project name and top module are required.")
            return

        log_lines = []
        created_xdc = None

        if self._sc_flags["create_v"].get():
            SRC_DIR.mkdir(parents=True, exist_ok=True)
            vf = SRC_DIR / f"{module}.v"
            if vf.exists() and not messagebox.askyesno("Overwrite?", f"{module}.v already exists. Overwrite?"):
                log_lines.append(f"  skipped  src_main/{module}.v")
            else:
                vf.write_text(VERILOG_TEMPLATE.format(module_name=module), encoding="utf-8")
                log_lines.append(f"  created  src_main/{module}.v")

        if self._sc_flags["create_xdc"].get():
            xdc_name = f"{project}.xdc"
            xf = CONSTRAINTS_DIR / xdc_name
            choice = self._sc_xdc.get()

            if "Board reference" in choice:
                board_key = self._selected_board_key()
                board_xdc = BOARDS_DIR / board_key / "constraints.xdc"
                if board_xdc.exists():
                    content = board_xdc.read_text(encoding="utf-8")
                else:
                    info = read_board_info(BOARDS_DIR / board_key)
                    content = XDC_MINIMAL.format(
                        project_name=project,
                        clock_pin=info.get("clock_pin", "?"),
                        clock_period=info.get("clock_period", "?"),
                        clock_half=info.get("clock_half", "?"),
                    )
            elif "DSL" in choice:
                src = CONSTRAINTS_DIR / "DSL_Starter_Kit.xdc"
                content = src.read_text(encoding="utf-8") if src.exists() else XDC_MINIMAL.format(
                    project_name=project, clock_pin="L17", clock_period="83.33", clock_half="41.66")
            elif "CMOD" in choice:
                src = CONSTRAINTS_DIR / "CMODA7_Constrain.xdc"
                content = src.read_text(encoding="utf-8") if src.exists() else XDC_MINIMAL.format(
                    project_name=project, clock_pin="L17", clock_period="83.33", clock_half="41.66")
            else:
                info = read_board_info(BOARDS_DIR / self._selected_board_key())
                content = XDC_MINIMAL.format(
                    project_name=project,
                    clock_pin=info.get("clock_pin", "L17"),
                    clock_period=info.get("clock_period", "83.33"),
                    clock_half=info.get("clock_half", "41.66"),
                )

            if xf.exists() and not messagebox.askyesno("Overwrite?", f"{xdc_name} already exists. Overwrite?"):
                log_lines.append(f"  skipped  constraints/{xdc_name}")
            else:
                xf.write_text(content, encoding="utf-8")
                log_lines.append(f"  created  constraints/{xdc_name}")
                created_xdc = xdc_name

        if self._sc_flags["update_cfg"].get():
            cfg = read_config()
            cfg["PROJECT_NAME"] = project
            cfg["TOP_MODULE"]   = module
            cfg["BOARD"]        = self._selected_board_key()
            if self._sc_flags["create_v"].get():
                cfg["SOURCE_FILES"] = [f"{module}.v"]
            if created_xdc:
                cfg["CONSTRAINT_FILES"] = [created_xdc]
            write_config(cfg)
            self._cfg = cfg
            self._populate()
            log_lines.append("  updated  scripts/config.tcl")

        self._sc_log.configure(state="normal")
        self._sc_log.delete("1.0", "end")
        self._sc_log.insert("end", f"Project '{project}' created:\n\n")
        self._sc_log.insert("end", "\n".join(log_lines))
        self._sc_log.insert("end", "\n\nSwitch to 'Project Config' to review, then save.")
        self._sc_log.configure(state="disabled")
        self._set_status(f"Project '{project}' scaffolded")

    # -----------------------------------------------------------------------
    # Validate tab actions
    # -----------------------------------------------------------------------

    def _validate(self):
        vivado = self._vivado_var.get() or self._vivado_path
        results = validate_setup(self._cfg, vivado)

        out = self._val_out
        out.configure(state="normal")
        out.delete("1.0", "end")

        all_ok = True
        for label, ok, detail in results:
            icon = "PASS" if ok else "FAIL"
            tag  = "ok"   if ok else "fail"
            out.insert("end", f"  [{icon}]  {label}\n", tag)
            out.insert("end", f"          {detail}\n\n", "detail")
            if not ok:
                all_ok = False

        out.insert("end", "-" * 48 + "\n", "sep")
        if all_ok:
            out.insert("end", "  All checks passed — ready to build.\n", "ok")
        else:
            out.insert("end", "  Some checks failed. Fix items marked FAIL above.\n", "fail")

        out.configure(state="disabled")
        self._set_status("Validation complete")

    # -----------------------------------------------------------------------
    # Utilities
    # -----------------------------------------------------------------------

    def _set_status(self, msg: str):
        self._status_var.set(msg)
        self.update_idletasks()


if __name__ == "__main__":
    app = App()
    app.mainloop()
