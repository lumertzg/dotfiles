from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title
from kitty.utils import color_as_int

_tab_widths: dict[int, int] = {}


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Draw centered tmux-style tabs and a fixed session label."""
    screen.cursor.bold = screen.cursor.italic = False

    if extra_data.for_layout and index == 1:
        _tab_widths.clear()

    if not extra_data.for_layout and index == 1:
        if tab.session_name:
            old_fg, old_bg = screen.cursor.fg, screen.cursor.bg
            screen.cursor.fg = as_rgb(color_as_int(draw_data.inactive_fg))
            screen.cursor.bg = as_rgb(color_as_int(draw_data.inactive_bg))
            screen.draw(f"[{tab.session_name}]")
            screen.cursor.fg, screen.cursor.bg = old_fg, old_bg

        tabs_width = sum(_tab_widths.values())
        screen.cursor.x = max(0, (screen.columns - tabs_width) // 2)

    tab_start = screen.cursor.x
    screen.draw(" ")
    draw_title(draw_data, screen, tab, index, max(0, max_tab_length - 2))

    overflow = screen.cursor.x - tab_start - max_tab_length
    if overflow > 0:
        screen.cursor.x -= overflow + 1
        screen.draw("…")

    if screen.cursor.x - tab_start < max_tab_length:
        screen.draw(" ")
    if extra_data.for_layout:
        _tab_widths[tab.tab_id] = screen.cursor.x - tab_start
    return screen.cursor.x
