
/*-
 * Copyright 2015-2022 elementary, Inc.
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

public class Printers.InkLevel : Gtk.Box {
    public unowned Printer printer { get; construct; }
    private const string STYLE_CLASS =
    """
    block.filled {
        background-color: #%s;
    }
    """;

    public InkLevel (Printer printer) {
        Object (printer: printer);
    }

    construct {
        homogeneous = true;
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 12;

        var colors = printer.get_color_levels ();

        foreach (Printer.ColorLevel color in colors) {
            string[] colors_codes = { null, "333333" };
            if ("#" in color.color) {
                colors_codes = color.color.split ("#");
            }

            var ink_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);

            for (int i = 1; i < colors_codes.length; i++) {
                var css_color = STYLE_CLASS.printf (colors_codes[i]);

                var level = new Gtk.LevelBar.for_interval (color.level_min, color.level_max) {
                    hexpand = true,
                    vexpand = true,
                    inverted = true,
                    orientation = Gtk.Orientation.VERTICAL,
                    value = color.level
                };

                var provider = new Gtk.CssProvider ();
                try {
                    provider.load_from_data (css_color, css_color.length);
                    level.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                } catch (Error e) {
                    warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
                }

                ink_box.add (level);
            }

            var label = new Gtk.Label (get_translated_name (color.name ?? "black"));

            var color_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            color_box.add (ink_box);
            color_box.add (label);

            add (color_box);
        }
    }

    private unowned string get_translated_name (string name) {
        switch (name) {
            case "black(PGBK)":
            case "Black(PGBK)":
                return _("Black (PGBK)");
            case "black(BK)":
            case "Black(BK)":
                return _("Black (BK)");
            case "black":
            case "black ink":
            case "Black":
                return _("Black");
            case "yellow":
            case "yellow ink":
            case "Yellow":
                return _("Yellow");
            case "cyan":
            case "cyan ink":
            case "Cyan":
                return _("Cyan");
            case "magenta":
            case "magenta ink":
            case "Magenta":
                return _("Magenta");
            case "tri-color ink":
                return _("Tri-color");
        }

        return name;
    }
}
