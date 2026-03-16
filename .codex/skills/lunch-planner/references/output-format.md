# Lunch Summary Format

Use this file when preparing the final answer.

The response must contain only the lunch menu content. Do not add any intro beyond the date heading, and do not append questions, suggestions, or closing remarks after the final menu item.

## Date Checklist

- Resolve relative dates before summarizing.
- Write the exact date in the answer.
- Write the final answer in Swedish.
- If a page only says "today" or a weekday, make the mapping explicit in your reasoning.
- If the source date cannot be confirmed, mark the restaurant as unverified.
- List restaurants with a confirmed menu for the requested day before restaurants with fixed, vague, or unverified menus.

## Recommended Response Shape

```text
 Lunch för måndag 16 mars 2026

Restaurangnamn (https://example.com/menu)
- Rätt 1
- Rätt 2
- Pris eller kort kostnotering om det finns

Restaurangnamn (https://example.com/menu)
- Rätt 1
- Kort notering om menyn verkar oklar eller inaktuell
```

## Extraction Hints

- Menu lines often contain food words, weekday labels, prices, or separators such as `:` and `-`.
- Keep nearby lines together when a dish title and description are split apart.
- Run fetched webpage content through `scripts/extract_menu_text.py` first, then remove any remaining repeated navigation text before summarizing.
- Prefer one clean summary over copying long menu blocks.
