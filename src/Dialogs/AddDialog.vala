// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
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

// Here because there are some default device_info values so it's nice to have them translated
namespace Printers.Translations {
    private static void translations () {
        /// Tranlators: This is a protocol name, please keep the (https).
        _("Internet Printing Protocol (https)");
        /// Tranlators: This is a protocol name, please keep the (http).
        _("Internet Printing Protocol (http)");
        /// Tranlators: This is a protocol name, please keep the (ipp).
        _("Internet Printing Protocol (ipp)");
        /// Tranlators: This is a protocol name, please keep the (ipps).
        _("Internet Printing Protocol (ipps)");
        /// Tranlators: This is a protocol name, please keep the (ipp14).
        _("Internet Printing Protocol (ipp14)");
        /// Tranlators: This is a protocol name.
        _("LPD/LPR Host or Printer");
        /// Tranlators: This is a protocol name.
        _("AppSocket/HP JetDirect");
    }
}

public class Printers.AddDialog : Granite.Dialog {
    private Gtk.Button refresh_button;
    private Gtk.Stack stack;
    private Granite.Widgets.AlertView alertview;
    private Gtk.Stack drivers_stack;
    private Gee.LinkedList<Printers.DeviceDriver> drivers;
    private Gtk.ListStore driver_list_store;
    private Gtk.TreeView driver_view;
    private Gtk.ListStore make_list_store;
    private Gtk.TreeView make_view;
    private Gtk.ListBox devices_list;
    private Printers.DeviceDriver selected_driver = null;
    private Cancellable driver_cancellable;

    public AddDialog () {
        search_device.begin ();
    }

    construct {
        var spinner = new Gtk.Spinner ();
        spinner.halign = Gtk.Align.CENTER;
        spinner.valign = Gtk.Align.CENTER;
        spinner.start ();

        var loading_label = new Gtk.Label (_("Finding nearby printers…"));

        var loading_grid = new Gtk.Grid ();
        loading_grid.column_spacing = 6;
        loading_grid.halign = loading_grid.valign = Gtk.Align.CENTER;
        loading_grid.add (loading_label);
        loading_grid.add (spinner);
        loading_grid.show_all ();

        devices_list = new Gtk.ListBox ();
        devices_list.expand = true;
        devices_list.set_placeholder (loading_grid);
        devices_list.set_header_func ((Gtk.ListBoxUpdateHeaderFunc) temp_device_list_header);
        devices_list.set_sort_func ((Gtk.ListBoxSortFunc) temp_device_list_sort);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.shadow_type = Gtk.ShadowType.IN;
        scrolled.add (devices_list);

        refresh_button = new Gtk.Button.with_label (_("Refresh"));
        refresh_button.sensitive = false;

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var next_button = new Gtk.Button.with_label (_("Next"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.sensitive = false;

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.spacing = 6;
        button_box.add (refresh_button);
        button_box.add (cancel_button);
        button_box.add (next_button);
        button_box.set_child_secondary (refresh_button, true);

        var devices_grid = new Gtk.Grid ();
        devices_grid.orientation = Gtk.Orientation.VERTICAL;
        devices_grid.row_spacing = 24;
        devices_grid.add (scrolled);
        devices_grid.add (button_box);

        alertview = new Granite.Widgets.AlertView (_("Impossible to list all available printers"), "", "dialog-error");
        alertview.no_show_all = true;

        stack = new Gtk.Stack ();
        stack.margin_start = stack.margin_end = 12;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.width_request = 500;
        stack.height_request = 300;
        stack.add_named (devices_grid, "devices-grid");
        stack.add (alertview);

        deletable = false;
        get_content_area ().add (stack);

        drivers = new Gee.LinkedList<Printers.DeviceDriver> ();

        devices_list.row_selected.connect ((row) => {
            next_button.sensitive = (row != null);
        });

        cancel_button.clicked.connect (() => {
            destroy ();
        });

        next_button.clicked.connect (() => {
            continue_with_tempdevice (((TempDeviceRow) devices_list.get_selected_row ()).temp_device);
        });

        refresh_button.clicked.connect (() => {
            refresh_button.sensitive = false;
            foreach (var row in devices_list.get_children ()) {
                devices_list.remove (row);
            }

            search_device.begin ();
        });
    }

    private async void search_device () {
        try {
            string error;
            GLib.HashTable<string, string> devices;
            yield Cups.get_pk_helper ().devices_get (CUPS.TIMEOUT_DEFAULT, -1, {}, {}, out error, out devices);
            if (error != null) {
                var tempdevices = new Gee.HashMap<int, Printers.TempDevice> (null, null);
                devices.foreach ((key, val) => {
                    var key_vars = key.split (":", 2);
                    int number = int.parse (key_vars[1]);
                    Printers.TempDevice tempdevice;
                    tempdevice = tempdevices.get (number);
                    if (tempdevice == null) {
                        tempdevice = new Printers.TempDevice ();
                        tempdevices.set (number, tempdevice);
                    }

                    switch (key_vars[0]) {
                        case "device-make-and-model":
                            if (val != "Unknown") {
                                tempdevice.device_make_and_model = val;
                            }
                            break;
                        case "device-class":
                            if (val == "network" && tempdevice.device_uri != null && ":" in tempdevice.device_uri) {
                                tempdevice.device_class = "ok-network";
                            } else {
                                tempdevice.device_class = val;
                            }

                            break;
                        case "device-uri":
                            tempdevice.device_uri = val;
                            if (tempdevice.device_class != null && tempdevice.device_class == "network" && ":" in tempdevice.device_uri) {
                                tempdevice.device_class = "ok-network";
                            }
                            break;
                        case "device-info":
                            tempdevice.device_info = _(val);
                            break;
                        case "device-id":
                            tempdevice.device_id = val;
                            break;
                        default:
                            debug ("missing: %s => %s", key_vars[0], val);
                            break;
                    }
                });

                process_devices (tempdevices.values);
            } else {
                show_error (error);
            }
        } catch (Error e) {
            show_error (e.message);
        }
    }

    // Once devices are available.
    private void process_devices (Gee.Collection<Printers.TempDevice> tempdevices) {
        foreach (var tempdevice in tempdevices) {
            devices_list.add (new TempDeviceRow (tempdevice));
        }

        devices_list.show_all ();
        refresh_button.sensitive = true;
    }

    // Shows the error panel
    private void show_error (string error) {
        alertview.no_show_all = false;
        alertview.show_all ();
        stack.set_visible_child (alertview);
        alertview.description = error;
    }

    // Shows the next panel with further configuration
    private void continue_with_tempdevice (TempDevice temp_device) {
        var connection_label = new Gtk.Label (_("Connection:"));
        connection_label.margin_start = 12;
        connection_label.xalign = 1;

        var connection_entry = new Gtk.Entry ();
        connection_entry.hexpand = true;
        connection_entry.placeholder_text = "ipp://hostname/ipp/port1";

        var description_label = new Gtk.Label (_("Description:"));
        description_label.xalign = 1;

        var description_entry = new Gtk.Entry ();
        description_entry.placeholder_text = _("BrandPrinter X3000");
        description_entry.hexpand = true;
        description_entry.text = temp_device.get_model_from_id () ?? "";

        var location_label = new Gtk.Label (_("Location:"));
        location_label.xalign = 1;

        var location_entry = new Gtk.Entry ();
        location_entry.hexpand = true;
        location_entry.placeholder_text = _("Lab 1 or John's desk");

        var spinner = new Gtk.Spinner ();
        spinner.halign = spinner.valign = Gtk.Align.CENTER;
        spinner.start ();

        make_list_store = new Gtk.ListStore (1, typeof (string));

        var cellrenderer = new Gtk.CellRendererText ();
        cellrenderer.xpad = 12;

        make_view = new Gtk.TreeView.with_model (make_list_store);
        make_view.headers_visible = false;
        make_view.get_selection ().mode = Gtk.SelectionMode.BROWSE;
        make_view.insert_column_with_attributes (-1, null, cellrenderer, "text", 0);

        var make_scrolled = new Gtk.ScrolledWindow (null, null);
        make_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        make_scrolled.add (make_view);

        driver_list_store = new Gtk.ListStore (2, typeof (string), typeof (DeviceDriver));

        driver_view = new Gtk.TreeView.with_model (driver_list_store);
        driver_view.headers_visible = false;
        driver_view.get_selection ().mode = Gtk.SelectionMode.BROWSE;
        driver_view.set_tooltip_column (0);
        driver_view.set_search_column (0);

        var driver_cellrenderer = new Gtk.CellRendererText ();
        driver_cellrenderer.ellipsize_set = true;
        driver_cellrenderer.ellipsize = Pango.EllipsizeMode.END;
        driver_view.insert_column_with_attributes (-1, null, driver_cellrenderer, "text", 0);

        var driver_scrolled = new Gtk.ScrolledWindow (null, null);
        driver_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        driver_scrolled.add (driver_view);
        driver_scrolled.expand = true;

        var drivers_grid = new Gtk.Grid ();
        drivers_grid.expand = true;
        drivers_grid.add (make_scrolled);
        drivers_grid.add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        drivers_grid.add (driver_scrolled);

        drivers_stack = new Gtk.Stack ();
        drivers_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        drivers_stack.expand = true;
        drivers_stack.add_named (spinner, "loading");
        drivers_stack.add_named (drivers_grid, "drivers");
        drivers_stack.show_all ();

        var frame = new Gtk.Frame (null);
        frame.margin_top = frame.margin_bottom = 12;
        frame.add (drivers_stack);

        driver_cancellable = new Cancellable ();
        fetch_ppds (temp_device);

        var previous_button = new Gtk.Button.with_label (_("Previous"));

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var next_button = new Gtk.Button.with_label (_("Add Printer"));
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        next_button.sensitive = false;

        var button_grid = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_grid.layout_style = Gtk.ButtonBoxStyle.END;
        button_grid.spacing = 6;
        button_grid.add (previous_button);
        button_grid.add (cancel_button);
        button_grid.add (next_button);

        var device_grid = new Gtk.Grid ();
        device_grid.expand = true;
        device_grid.row_spacing = 12;
        device_grid.column_spacing = 12;
        device_grid.attach (description_label, 0, 1, 1, 1);
        device_grid.attach (description_entry, 1, 1, 1, 1);

        if (":" in temp_device.device_uri) {
            description_entry.grab_focus ();
        } else {
            connection_entry.text = temp_device.device_uri;
            device_grid.attach (connection_label, 0, 0, 1, 1);
            device_grid.attach (connection_entry, 1, 0, 1, 1);
            connection_entry.grab_focus ();
        }

        device_grid.attach (location_label, 0, 2, 1, 1);
        device_grid.attach (location_entry, 1, 2, 1, 1);
        device_grid.attach (frame, 0, 3, 2, 1);
        device_grid.attach (button_grid, 0, 4, 2, 1);
        device_grid.show_all ();

        stack.add (device_grid);
        stack.set_visible_child (device_grid);

        previous_button.clicked.connect (() => {
            driver_cancellable.cancel ();
            stack.visible_child_name = "devices-grid";
            device_grid.destroy ();
        });

        cancel_button.clicked.connect (() => {
            destroy ();
        });

        next_button.clicked.connect (() => {
            try {
                var name = temp_device.device_info.replace (" ", "_");
                name = name.replace ("/", "_");
                name = name.replace ("#", "_");
                var uri = temp_device.device_uri;
                if (connection_entry.visible) {
                    uri = connection_entry.text;
                }

                var pk_helper = Cups.get_pk_helper ();
                pk_helper.printer_add (name, uri, selected_driver.ppd_name, description_entry.text, location_entry.text);
                pk_helper.printer_set_enabled (name, true);
                pk_helper.printer_set_accept_jobs (name, true);
            } catch (Error e) {
                critical (e.message);
            }

            destroy ();
        });

        var driver_selection = driver_view.get_selection ();
        driver_selection.changed.connect (() => {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            if (driver_selection.get_selected (out model, out iter)) {
                var val = Value (typeof (Printers.DeviceDriver));
                model.get_value (iter, 1, out val);
                selected_driver = (Printers.DeviceDriver) val.get_object ();
                bool can_go_next = true;
                can_go_next &= !connection_entry.visible || connection_entry.text.contains ("://");
                can_go_next &= selected_driver != null;
                can_go_next &= description_entry.text != "";
                next_button.sensitive = can_go_next;
            }
        });

        description_entry.changed.connect (() => {
            bool can_go_next = true;
            can_go_next &= !connection_entry.visible || connection_entry.text.contains ("://");
            can_go_next &= selected_driver != null;
            can_go_next &= description_entry.text != "";
            next_button.sensitive = can_go_next;
        });

        connection_entry.changed.connect (() => {
            bool can_go_next = true;
            can_go_next &= !connection_entry.visible || connection_entry.text.contains ("://");
            can_go_next &= selected_driver != null;
            can_go_next &= description_entry.text != "";
            next_button.sensitive = can_go_next;
        });
    }

    // Retreives all the drivers from the CUPS server.
    private void fetch_ppds (TempDevice temp_device) {
        new Thread<void*> (null, () => {
            char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
            CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, null);
            var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.CUPS_GET_PPDS);
            request.do_request (CUPS.HTTP.DEFAULT);

            if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
                unowned CUPS.IPP.Attribute attr = request.first_attribute ();
                var driver = new Printers.DeviceDriver ();
                while (attr != null) {
                    if (attr.get_name () == null) {
                        drivers.add (driver);
                        driver = null;
                        attr = request.next_attribute ();
                        continue;
                    }

                    if (driver == null) {
                        driver = new Printers.DeviceDriver ();
                    }

                    switch (attr.get_name ()) {
                        case "ppd-name":
                            driver.ppd_name = attr.get_string ();
                            break;
                        case "ppd-natural-language":
                            driver.ppd_natural_language = attr.get_string ();
                            break;
                        case "ppd-make":
                            driver.ppd_make = attr.get_string ();
                            break;
                        case "ppd-make-and-model":
                            driver.ppd_make_and_model = attr.get_string ();
                            break;
                        case "ppd-device-id":
                            driver.ppd_device_id = attr.get_string ();
                            break;
                        case "ppd-product":
                            driver.ppd_product = attr.get_string ();
                            break;
                        case "ppd-psversion":
                            driver.ppd_psversion = attr.get_string ();
                            break;
                        case "ppd-type":
                            driver.ppd_type = attr.get_string ();
                            break;
                        case "ppd-model-number":
                            driver.ppd_model_number = attr.get_integer ();
                            break;
                    }

                    attr = request.next_attribute ();
                }
            } else {
                critical ("Error: %s", request.get_status_code ().to_string ());
                return null;
            }

            Idle.add (() => {
                if (!driver_cancellable.is_cancelled ()) {
                    drivers_loaded (temp_device);
                }
                return GLib.Source.REMOVE;
            });

            return null;
        });
    }

    // Once drivers are available.
    private void drivers_loaded (TempDevice temp_device) {
        var make_list = new Gee.TreeSet<string> ();
        foreach (var driver in drivers) {
            make_list.add (driver.ppd_make);

            if (driver_cancellable.is_cancelled ()) {
                return;
            }
        }

        var make_selection = make_view.get_selection ();
        var current_make = temp_device.get_make_from_id ();
        foreach (var make in make_list) {
            Gtk.TreeIter iter;
            make_list_store.append (out iter);
            make_list_store.set (iter, 0, make);
            if (current_make != null && make == current_make) {
                make_selection.select_iter (iter);
                make_view.scroll_to_cell (make_list_store.get_path (iter), null, true, 0.0f, 0.0f);
                populate_driver_list_from_make (make, temp_device.get_model_from_id ());
            }

            if (driver_cancellable.is_cancelled ()) {
                return;
            }
        }

        if (make_selection.count_selected_rows () < 1) {
            Gtk.TreeIter iter;
            make_list_store.get_iter_first (out iter);
            make_selection.select_iter (iter);
            var val = GLib.Value (typeof (string));
            make_list_store.get_value (iter, 0, out val);
            populate_driver_list_from_make (val.get_string ());
        }
        drivers_stack.set_visible_child_name ("drivers");

        make_selection.changed.connect (() => {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            if (make_selection.get_selected (out model, out iter)) {
                var val = Value (typeof (string));
                model.get_value (iter, 0, out val);
                string make_and_model = null;
                if (selected_driver != null) {
                    make_and_model = selected_driver.ppd_make_and_model;
                }

                populate_driver_list_from_make (val.get_string (), make_and_model);
            }
        });
    }

    private void populate_driver_list_from_make (string make, string? selection = null) {
        driver_list_store.clear ();
        foreach (var driver in drivers) {
            if (driver.ppd_make != make) {
                continue;
            }

            Gtk.TreeIter iter;
            driver_list_store.append (out iter);
            var model = driver.ppd_make_and_model;
            model = model.replace ("(recommended)", _("(recommended)"));
            if (driver.ppd_natural_language != null) {
                ///Translators: The first argument is the driver name, the second is the language
                model = _("%s (%s)").printf (model, driver.ppd_natural_language);
            }

            driver_list_store.set (iter, 0, model, 1, driver);
            if (selection != null && (selection in driver.ppd_make_and_model || selection == driver.get_model_from_id ())) {
                driver_view.get_selection ().select_iter (iter);
                driver_view.scroll_to_cell (driver_list_store.get_path (iter), null, true, 0.0f, 0.0f);
            }

            if (driver_cancellable.is_cancelled ()) {
                return;
            }
        }

        if (selected_driver == null && driver_view.get_selection ().count_selected_rows () < 1) {
            Gtk.TreeIter iter;
            driver_list_store.get_iter_first (out iter);
            driver_view.get_selection ().select_iter (iter);
        }
    }

    private static int temp_device_list_sort (TempDeviceRow row1, TempDeviceRow row2) {
        switch (row1.temp_device.device_class) {
            case "direct":
                if (row2.temp_device.device_class == "direct") {
                    return strcmp (row1.temp_device.device_info, row2.temp_device.device_info);
                } else {
                    return -1;
                }
            case "ok-network":
                if (row2.temp_device.device_class == "direct") {
                    return 1;
                } else if (row2.temp_device.device_class == "ok-network") {
                    return strcmp (row1.temp_device.device_info, row2.temp_device.device_info);
                } else {
                    return -1;
                }
            case "network":
                if (row2.temp_device.device_class == "direct") {
                    return 1;
                } else if (row2.temp_device.device_class == "ok-network") {
                    return 1;
                } else if (row2.temp_device.device_class == "network") {
                    return strcmp (row1.temp_device.device_info, row2.temp_device.device_info);
                } else {
                    return -1;
                }
            default:
                if (row2.temp_device.device_class == "direct") {
                    return 1;
                } else if (row2.temp_device.device_class == "ok-network") {
                    return 1;
                } else if (row2.temp_device.device_class == "network") {
                    return 1;
                } else {
                    return strcmp (row1.temp_device.device_info, row2.temp_device.device_info);
                }
        }
    }

    private static void temp_device_list_header (TempDeviceRow row, TempDeviceRow? before) {
        if (before == null || before.temp_device.device_class != row.temp_device.device_class) {
            switch (row.temp_device.device_class) {
                case "serial":
                    row.set_header (new Granite.HeaderLabel (_("Serial")));
                    break;
                case "direct":
                    row.set_header (new Granite.HeaderLabel (_("Local Printers")));
                    break;
                case "network":
                    row.set_header (new Granite.HeaderLabel (_("Network Printers")));
                    break;
                case "ok-network":
                    row.set_header (new Granite.HeaderLabel (_("Available Network Printers")));
                    break;
                default:
                    row.set_header (new Granite.HeaderLabel (row.temp_device.device_class));
                    break;
            }
        } else {
            row.set_header (null);
        }
    }

    public class TempDeviceRow : Gtk.ListBoxRow {
        public TempDevice temp_device { public get; private set; }
        public TempDeviceRow (TempDevice temp_device) {
            this.temp_device = temp_device;
            var grid = new Gtk.Grid ();
            var label = new Gtk.Label (temp_device.device_info);
            get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
            label.margin_start = 12;
            label.margin_top = 3;
            label.margin_bottom = 3;
            ((Gtk.Misc)label).xalign = 0;
            grid.add (label);
            add (grid);
            show_all ();
        }
    }
}
