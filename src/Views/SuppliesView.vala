/*-
 * Copyright (c) 2015-2018 elementary LLC. (https://elementary.io)
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

public class Printers.SuppliesView: Gtk.Grid {
    public Printer printer { get; construct; }

    public SuppliesView (Printer printer) {
        Object (printer: printer);
    }

    construct {
        var name_label = new Gtk.Label (_("Description:")) {
            xalign = 1
        };

        var name_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("BrandPrinter X3000"),
            text = printer.info
        };
        name_entry.bind_property ("text", printer, "info", GLib.BindingFlags.BIDIRECTIONAL);

        var location_label = new Gtk.Label (_("Location:")) {
            xalign = 1
        };

        var location_entry = new Gtk.Entry () {
            text = printer.location,
            placeholder_text = _("Lab 1 or John's Desk")
        };
        location_entry.bind_property ("text", printer, "location", GLib.BindingFlags.BIDIRECTIONAL);

        var default_label = new Gtk.Label (_("Use as default printer:"));

        var default_switch = new Gtk.Switch () {
            active = printer.is_default,
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER
        };
        default_switch.bind_property ("active", printer, "is-default", GLib.BindingFlags.BIDIRECTIONAL);

        var ink_level = new InkLevel (printer) {
            margin_top = 12
        };

        column_spacing = 12;
        row_spacing = 12;
        attach (name_label, 0, 0);
        attach (name_entry, 1, 0);
        attach (location_label, 0, 1);
        attach (location_entry, 1, 1);
        attach (default_label, 0, 2);
        attach (default_switch, 1, 2);
        attach (ink_level, 0, 3, 2, 1);
    }
}
