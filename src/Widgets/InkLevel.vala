// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Pantheon Developers (https://launchpad.net/switchboard-plug-printers)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.InkLevel : Gtk.Grid {
    public unowned Printer printer { get; construct; }
    private const string STYLE_CLASS =
    """@define-color levelbar_color %s;
    .coloredlevelbar block.filled {
        background-image:
            linear-gradient(
                to bottom,
                shade (@levelbar_color, 1.3),
                shade (@levelbar_color, 1)
            );
            border: 1px solid shade (@levelbar_color, 0.85);
        box-shadow:
            inset 0 0 0 1px alpha (#fff, 0.05),
            inset 0 1px 0 0 alpha (#fff, 0.45),
            inset 0 -1px 0 0 alpha (#fff, 0.15);
    }
    """;

    public InkLevel (Printer printer) {
        Object (printer: printer);
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        column_spacing = 6;
        var colors = printer.get_color_levels ();
        if (!colors.is_empty) {
            height_request = 100;
        }

        foreach (Printer.ColorLevel color in colors) {
            var level = new Gtk.LevelBar.for_interval (color.level_min, color.level_max);
            level.orientation = Gtk.Orientation.VERTICAL;
            level.value = color.level;
            level.inverted = true;
            level.tooltip_text = get_translated_name (color.name);
            level.expand = true;

            var context = level.get_style_context ();
            context.add_class ("coloredlevelbar");

            var split = color.color.split ("#");

            var css_color = STYLE_CLASS.printf (color.color);
            if (split.length > 2) {
                css_color = STYLE_CLASS.printf ("#" + split[1]);
            } else if (color.color == "none") {
                css_color = STYLE_CLASS.printf ("#3689e6");
            }

            var provider = new Gtk.CssProvider ();
            try {
                provider.load_from_data (css_color, css_color.length);
                context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
            }

            add (level);
        }
    }

    private string get_translated_name (string name) {
        switch (name) {
            case "black(PGBK)":
            case "Black(PGBK)":
                return _("Black (PGBK)");
            case "black(BK)":
            case "Black(BK)":
                return _("Black (BK)");
            case "black":
            case "Black":
                return _("Black");
            case "yellow":
            case "Yellow":
                return _("Yellow");
            case "cyan":
            case "Cyan":
                return _("Cyan");
            case "magenta":
            case "Magenta":
                return _("Magenta");
        }

        return name;
    }
}
