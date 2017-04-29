// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015-2016 elementary LLC.
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
    public Printer printer;
    private Gtk.Image printer_image;
    private Gtk.Image status_image;
    private Gtk.Label name_label;
    private Gtk.Label status_label;

    public PrinterRow (Printer printer) {
        this.printer = printer;
        name_label = new Gtk.Label (printer.info);
        name_label.get_style_context ().add_class ("h3");
        name_label.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) name_label).xalign = 0;
        status_label = new Gtk.Label ("<span font_size=\"small\">%s</span>".printf (GLib.Markup.escape_text (printer.state_reasons_localized)));
        status_label.use_markup = true;
        status_label.tooltip_text = printer.state_reasons_localized;
        status_label.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) status_label).xalign = 0;
        printer_image = new Gtk.Image.from_icon_name ("printer", Gtk.IconSize.DND);
        printer_image.pixel_size = 32;
        status_image = new Gtk.Image.from_icon_name ("user-available", Gtk.IconSize.MENU);
        status_image.halign = status_image.valign = Gtk.Align.END;
        var overlay = new Gtk.Overlay ();
        overlay.width_request = 38;
        overlay.add (printer_image);
        overlay.add_overlay (status_image);
        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.margin_start = 3;
        grid.column_spacing = 3;
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (name_label, 1, 0, 1, 1);
        grid.attach (status_label, 1, 1, 1, 1);
        add (grid);
        page = new PrinterPage (printer);
        update_status ();
        Cups.Notifier.get_default ().printer_state_changed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => {
            if (printer.dest.name == name) {
                update_status ();
                status_label.tooltip_text = printer.state_reasons_localized;
            }
        });

        printer.enabled_changed.connect (update_status);
        show_all ();
        printer.deleted.connect (() => {
            page.destroy ();
            destroy ();
        });
    }

    private void update_status () {
        if (printer.is_offline ()) {
            status_image.icon_name = "user-offline";
        } else if (printer.enabled) {
            status_image.icon_name = "user-available";
        } else {
            status_image.icon_name = "user-busy";
        }
    }
}
