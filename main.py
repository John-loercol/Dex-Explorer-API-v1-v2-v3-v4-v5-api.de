import tkinter as tk
import sys

# ─── Constants ────────────────────────────────────────────────────────────────
BG_COLOR       = "#000000"
BOX_BG_COLOR   = "#000000"
BORDER_COLOR   = "#FFFFFF"
TEXT_COLOR      = "#FFFFFF"
BTN_HOVER_BG   = "#1A1A1A"

TITLE_TEXT = "แจ้งเตือนการใช้งานอุปกรณ์"

MESSAGE_TEXT = (
    "คำเตือน\n\n"
    "กรุณาระมัดระวังการใช้พื้นที่จัดเก็บข้อมูลในอุปกรณ์นี้\n"
    "เพื่อป้องกันความผิดพลาดร้ายแรงที่อาจเกิดขึ้นในอนาคต\n\n"
    "โปรดตรวจสอบและจัดการพื้นที่เก็บข้อมูลให้เหมาะสมอยู่เสมอ"
)


def build_ui(root: tk.Tk) -> None:
    """Build the fullscreen dark-mode alert window."""

    # ── Window setup ──────────────────────────────────────────────────────────
    root.title(TITLE_TEXT)
    root.configure(bg=BG_COLOR)
    root.attributes("-fullscreen", True)     # True fullscreen (no taskbar)
    root.attributes("-topmost", True)        # Stay on top of everything
    root.focus_force()

    # Allow ESC as an additional way to close (optional – remove if unwanted)
    root.bind("<Escape>", lambda e: close_app(root))

    # ── Outer frame (fills entire screen, centres the dialog) ─────────────────
    outer = tk.Frame(root, bg=BG_COLOR)
    outer.place(relx=0, rely=0, relwidth=1, relheight=1)

    # ── Dialog box ────────────────────────────────────────────────────────────
    box = tk.Frame(
        outer,
        bg=BOX_BG_COLOR,
        highlightbackground=BORDER_COLOR,
        highlightthickness=2,
        padx=40,
        pady=36,
    )
    box.place(relx=0.5, rely=0.5, anchor="center")

    # Title label inside box
    title_lbl = tk.Label(
        box,
        text=TITLE_TEXT,
        bg=BOX_BG_COLOR,
        fg=BORDER_COLOR,
        font=("Segoe UI", 14, "bold"),
        anchor="center",
    )
    title_lbl.pack(pady=(0, 16))

    # Thin horizontal divider
    divider = tk.Frame(box, bg=BORDER_COLOR, height=1, width=380)
    divider.pack(fill="x", pady=(0, 20))

    # Message label
    msg_lbl = tk.Label(
        box,
        text=MESSAGE_TEXT,
        bg=BOX_BG_COLOR,
        fg=TEXT_COLOR,
        font=("Segoe UI", 11),
        justify="center",
        wraplength=420,
    )
    msg_lbl.pack(pady=(0, 28))

    # ── OK button ─────────────────────────────────────────────────────────────
    btn = tk.Button(
        box,
        text="  ตกลง  ",
        bg=BOX_BG_COLOR,
        fg=TEXT_COLOR,
        activebackground=BTN_HOVER_BG,
        activeforeground=TEXT_COLOR,
        highlightbackground=BORDER_COLOR,
        highlightthickness=1,
        relief="flat",
        font=("Segoe UI", 11),
        cursor="hand2",
        bd=0,
        padx=20,
        pady=8,
        command=lambda: close_app(root),
    )
    btn.pack()

    # Hover effect
    btn.bind("<Enter>", lambda e: btn.config(bg=BTN_HOVER_BG))
    btn.bind("<Leave>", lambda e: btn.config(bg=BOX_BG_COLOR))


def close_app(root: tk.Tk) -> None:
    """Exit fullscreen and destroy the window."""
    root.attributes("-fullscreen", False)
    root.destroy()
    sys.exit(0)


def main() -> None:
    root = tk.Tk()
    build_ui(root)
    root.mainloop()


if __name__ == "__main__":
    main()
