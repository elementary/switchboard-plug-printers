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
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.PrinterList : Gtk.Grid {
    public signal void new_printer_page (Gtk.Widget widget);
    public signal void focused_printer_page (Gtk.Widget widget);

    Gtk.ListBox list_box;
    Printers.AddPopover add_popover;

    public PrinterList () {

    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        expand = true;
        list_box = new Gtk.ListBox ();

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (list_box);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.width_request = 250;
        scrolled.expand = true;

        var toolbar = new Gtk.Toolbar ();
        toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        toolbar.icon_size = Gtk.IconSize.SMALL_TOOLBAR;
        var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        add_button.tooltip_text = _("Add Printer…");
        var remove_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        remove_button.tooltip_text = _("Remove Printer");
        remove_button.sensitive = false;
        toolbar.add (add_button);
        toolbar.add (remove_button);
        add (scrolled);
        add (toolbar);

        list_box.row_selected.connect ((row) => {
            remove_button.sensitive = (row != null);
            if (row != null) {
                focused_printer_page (((PrinterRow) row).page);
            }
        });

        add_button.clicked.connect (() => {
            if (add_popover != null) {
                if (add_popover.visible) {
                    return;
                } else {
                    add_popover.destroy ();
                }
            }

            add_popover = new Printers.AddPopover (add_button);
            add_popover.show_all ();
        });

        remove_button.clicked.connect (() => {
            var popover = new Gtk.Popover (remove_button);
            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.row_spacing = 6;
            grid.column_spacing = 6;
            var printer = ((PrinterRow)list_box.get_selected_row ()).printer;
            var label = new Gtk.Label (_("By removing '%s' you'll lose all print history\nand configuration associated with it.").printf (printer.info));
            label.wrap = true;
            var image = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
            image.halign = Gtk.Align.CENTER;
            image.valign = Gtk.Align.CENTER;
            var button = new Gtk.Button.with_label (_("Remove"));
            button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            grid.attach (image, 0, 0, 1, 2);
            grid.attach (label, 1, 0, 1, 1);
            grid.attach (button, 1, 1, 1, 1);
            popover.add (grid);
            popover.show_all ();
            button.clicked.connect (() => {
                try {
                    Cups.get_pk_helper ().printer_delete (printer.dest.name);
                } catch (Error e) {
                    critical (e.message);
                }
            });
        });
    }

    public bool has_printer () {
        return list_box.get_children ().length () > 0;
    }

    public void add_printer (Printer printer) {
        var row = new PrinterRow (printer);
        list_box.add (row);
        new_printer_page (row.page);
        if (printer.is_default) {
            list_box.select_row (row);
        }
    }

    public void remove_printer (string printer_name) {
        list_box.get_children ().foreach ((child) => {
            if (child is PrinterRow) {
                if (((PrinterRow) child).printer.dest.name == printer_name) {
                    ((PrinterRow) child).printer.deleted ();
                }
            }
        });
    }
}
