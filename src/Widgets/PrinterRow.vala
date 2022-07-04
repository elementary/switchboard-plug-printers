// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright 2015 - 2022 elementary, Inc. (https://elementary.io)
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

public class Printers.PrinterRow : Gtk.ListBoxRow {
    public PrinterPage page;
    public unowned Printer printer { get; construct; }

    private Gtk.Image printer_image;
    private Gtk.Image status_image;
    private Gtk.Label name_label;
    private Gtk.Label status_label;

    public PrinterRow (Printer printer) {
        Object (printer: printer);
    }

    construct {
        var remove_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            hexpand = true,
            tooltip_text = _("Remove this printer")
        };
        remove_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        name_label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0
        };
        name_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        status_label = new Gtk.Label (null) {
            use_markup = true,
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0
        };

        printer_image = new Gtk.Image.from_icon_name ("printer") {
            pixel_size = 32
        };

        status_image = new Gtk.Image.from_icon_name ("user-available") {
            pixel_size = 16,
            halign = Gtk.Align.END,
            valign = Gtk.Align.END
        };

        var overlay = new Gtk.Overlay () {
            child = printer_image,
            width_request = 38
        };
        overlay.add_overlay (status_image);

        var grid = new Gtk.Grid () {
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 3,
            column_spacing = 3
        };
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (name_label, 1, 0, 1, 1);
        grid.attach (status_label, 1, 1, 1, 1);
        grid.attach (remove_button, 2, 0, 2, 2);

        child = grid;

        page = new PrinterPage (printer);

        printer.bind_property ("info", this, "tooltip-text", GLib.BindingFlags.SYNC_CREATE);
        printer.bind_property ("info", name_label, "label", GLib.BindingFlags.SYNC_CREATE);
        printer.notify["state"].connect (() => {
            update_status ();
        });

        remove_button.clicked.connect (() => {
            var remove_dialog = new RemoveDialog (printer) {
                transient_for = (Gtk.Window) get_root ()
            };
            remove_dialog.present ();
        });

        printer.deleted.connect (() => {
            page.destroy ();
            destroy ();
        });

        update_status ();
    }

    private void update_status () {
        if (printer.is_enabled) {
            status_label.label = "<span font_size=\"small\">%s</span>".printf (GLib.Markup.escape_text (printer.state_reasons));
            switch (printer.state_reasons_raw) {
                case "offline":
                    status_image.icon_name = "user-offline";
                    break;
                case "none":
                case null:
                    status_image.icon_name = "user-available";
                    break;
                case "developer-low":
                case "marker-supply-low":
                case "marker-waste-almost-full":
                case "media-low":
                case "opc-near-eol":
                case "toner-low":
                    status_image.icon_name = "user-away";
                    break;
                default:
                    status_image.icon_name = "user-busy";
                    break;
            }
        } else {
            status_image.icon_name = "user-offline";
            status_label.label = "<span font_size=\"small\">%s</span>".printf (_("Disabled"));
        }
    }
}
