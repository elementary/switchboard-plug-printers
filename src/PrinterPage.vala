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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.PrinterPage : Gtk.Grid {
    private Printer printer;

    public PrinterPage (Printer printer) {
        this.printer = printer;
        expand = true;
        margin = 12;
        column_spacing = 12;
        row_spacing = 6;
        var stack = new Gtk.Stack ();
        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.halign = Gtk.Align.CENTER;
        stack_switcher.set_stack (stack);
        stack.add_titled (get_general_page (), "general", _("General"));
        stack.add_titled (get_options_page (), "options", _("Options"));
        create_header ();
        attach (stack_switcher, 0, 1, 3, 1);
        attach (stack, 0, 2, 3, 1);
        show_all ();

    }

    private void create_header () {
        var image = new Gtk.Image.from_icon_name ("printer", Gtk.IconSize.DIALOG);

        var editable_title = new EditableTitle (printer);

        var expander = new Gtk.Grid ();
        expander.hexpand = true;

        var info_button = new Gtk.ToggleButton ();
        info_button.image = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.MENU);
        info_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var enable_switch = new Gtk.Switch ();
        enable_switch.active = printer.state != "5" && printer.is_accepting_jobs;
        enable_switch.notify["active"].connect (() => {
            printer.enabled = enable_switch.active;
        });

        var right_grid = new Gtk.Grid ();
        right_grid.column_spacing = 12;
        right_grid.orientation = Gtk.Orientation.HORIZONTAL;
        right_grid.valign = Gtk.Align.CENTER;
        right_grid.add (expander);
        right_grid.add (info_button);
        right_grid.add (enable_switch);

        var info_popover = new Gtk.Popover (info_button);
        info_popover.hide.connect (() => {
            info_button.active = false;
        });
        info_button.toggled.connect (() => {
            if (info_button.active == true) {
                info_popover.show_all ();
            } else {
                info_popover.hide ();
            }
        });

        attach (image, 0, 0, 1, 1);
        attach (editable_title, 1, 0, 1, 1);
        attach (right_grid, 2, 0, 1, 1);

        var location_label = new Gtk.Label (_("Location:"));
        ((Gtk.Misc) location_label).xalign = 1;
        location_label.hexpand = true;

        var location_entry = new Gtk.Entry ();
        location_entry.text = printer.location ?? "";
        location_entry.hexpand = true;
        location_entry.halign = Gtk.Align.START;
        location_entry.placeholder_text = _("Location of the printer");

        var ip_label = new Gtk.Label (_("IP Address:"));
        ((Gtk.Misc) ip_label).xalign = 1;

        var ip_label_ = new Gtk.Label ("localhost");
        ip_label_.selectable = true;
        ((Gtk.Misc) ip_label_).xalign = 0;

        var ink_level = new InkLevel (printer);

        var info_grid = new Gtk.Grid ();
        info_grid.margin = 6;
        info_grid.column_spacing = 12;
        info_grid.row_spacing = 6;
        info_grid.attach (location_label, 0, 0, 1, 1);
        info_grid.attach (location_entry, 1, 0, 1, 1);
        info_grid.attach (ip_label, 0, 1, 1, 1);
        info_grid.attach (ip_label_, 1, 1, 1, 1);
        info_grid.attach (ink_level, 0, 2, 2, 1);
        info_popover.add (info_grid);
    }

    private Gtk.Grid get_general_page () {
        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 6;

        var jobs_view = new JobsView (printer);

        var default_check = new Gtk.CheckButton.with_label (_("Use as Default Printer"));
        default_check.active = printer.is_default;
        default_check.notify["active"].connect (() => {
            if (default_check.active) {
                printer.is_default = true;
            } else {
                default_check.active = true;
            }
        });
        var expander_grid = new Gtk.Grid ();
        expander_grid.hexpand = true;
        var print_test = new Gtk.Button.with_label (_("Print Test Page"));

        grid.attach (jobs_view, 0, 0, 3, 1);
        grid.attach (default_check, 0, 1, 1, 1);
        grid.attach (expander_grid, 1, 1, 1, 1);
        grid.attach (print_test, 2, 1, 1, 1);
        return grid;
    }

    private Gtk.Grid get_options_page () {
        return new OptionsPage (printer);
    }
}

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
        printer.enabled_changed.connect (update_status);
        show_all ();
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
