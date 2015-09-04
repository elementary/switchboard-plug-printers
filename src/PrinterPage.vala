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
    private static string[] reasons = {
        "toner-low",
        "toner-empty",
        "developer-low",
        "developer-empty",
        "marker-supply-low",
        "marker-supply-empty",
        "cover-open",
        "door-open",
        "media-low",
        "media-empty",
        "offline",
        "paused",
        "marker-waste-almost-full",
        "marker-waste-full",
        "opc-near-eol",
        "opc-life-over"
    };

    private static string[] statuses = {
        /// Translators: The printer is low on toner
        N_("Low on toner"),
        /// Translators: The printer has no toner left
        N_("Out of toner"),
        /// Translators: "Developer" is a chemical for photo development, http://en.wikipedia.org/wiki/Photographic_developer
        N_("Low on developer"),
        /// Translators: "Developer" is a chemical for photo development, http://en.wikipedia.org/wiki/Photographic_developer
        N_("Out of developer"),
        /// Translators: "marker" is one color bin of the printer
        N_("Low on a marker supply"),
        /// Translators: "marker" is one color bin of the printer
        N_("Out of a marker supply"),
        /// Translators: One or more covers on the printer are open
        N_("Open cover"),
        /// Translators: One or more doors on the printer are open
        N_("Open door"),
        /// Translators: At least one input tray is low on media
        N_("Low on paper"),
        /// Translators: At least one input tray is empty
        N_("Out of paper"),
        /// Translators: The printer is offline
        NC_("printer state", "Offline"),
        /// Translators: Someone has stopped the Printer
        NC_("printer state", "Stopped"),
        /// Translators: The printer marker supply waste receptacle is almost full
        N_("Waste receptacle almost full"),
        /// Translators: The printer marker supply waste receptacle is full
        N_("Waste receptacle full"),
        /// Translators: Optical photo conductors are used in laser printers
        N_("The optical photo conductor is near end of life"),
        /// Translators: Optical photo conductors are used in laser printers
        N_("The optical photo conductor is no longer functioning")
    };

    private unowned CUPS.Destination dest;

    public PrinterPage (CUPS.Destination dest) {
        this.dest = dest;
        expand = true;
        margin = 12;
        column_spacing = 12;
        row_spacing = 6;
        var image = new Gtk.Image.from_icon_name ("printer", Gtk.IconSize.DIALOG);
        var name = new Gtk.Entry ();
        name.halign = Gtk.Align.START;
        name.text = dest.printer_info;
        var state = new Gtk.Label (human_readable_reason (dest.printer_state_reasons));
        state.hexpand = true;
        ((Gtk.Misc) state).xalign = 0;
        ((Gtk.Misc) state).yalign = 0;
        var stack = new Gtk.Stack ();
        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.margin_top = 6;
        stack_switcher.margin_bottom = 6;
        stack_switcher.halign = Gtk.Align.CENTER;
        stack_switcher.set_stack (stack);
        stack.add_titled (get_general_page (), "general", _("General"));
        stack.add_titled (get_options_page (), "options", _("Options"));
        stack.add_titled (get_tasks_page (), "tasks", _("Tasks"));
        attach (image, 0, 0, 1, 2);
        attach (name, 1, 0, 1, 1);
        attach (state, 1, 1, 1, 1);
        attach (stack_switcher, 0, 2, 2, 1);
        attach (stack, 0, 3, 2, 1);
        show_all ();
    }

    private Gtk.Grid get_general_page () {
        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 6;

        var location_label = new Gtk.Label ("Location:");
        ((Gtk.Misc) location_label).xalign = 1;
        location_label.hexpand = true;

        var location_entry = new Gtk.Entry ();
        location_entry.text = dest.printer_location ?? "";
        location_entry.hexpand = true;
        location_entry.halign = Gtk.Align.START;
        location_entry.placeholder_text = _("Location of the printer");

        var ip_label = new Gtk.Label ("IP Address:");
        ((Gtk.Misc) ip_label).xalign = 1;

        var ip_label_ = new Gtk.Label ("localhost");
        ip_label_.selectable = true;
        ((Gtk.Misc) ip_label_).xalign = 0;

        var exp_grid = new Gtk.Grid ();
        exp_grid.hexpand = true;
        grid.attach (exp_grid, 0, 0, 4, 1);
        grid.attach (location_label, 1, 0, 1, 1);
        grid.attach (location_entry, 2, 0, 1, 1);
        grid.attach (ip_label, 1, 1, 1, 1);
        grid.attach (ip_label_, 2, 1, 1, 1);
        return grid;
    }

    private Gtk.Grid get_options_page () {
        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        return grid;
    }

    private Gtk.Frame get_tasks_page () {
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;

        var list_store = new Gtk.ListStore (4, typeof (GLib.Icon), typeof (string), typeof (string), typeof (string));
        Gtk.TreeIter iter;

        unowned CUPS.Job[] jobs;
        var jobs_number = dest.get_jobs (out jobs, 1, CUPS.WhichJobs.ALL);
        for (int i = 0; i < jobs_number; i++) {
            list_store.append (out iter);
            string date;
            unowned CUPS.Job job = jobs[i];
            if (job.completed_time != 0) {
                var date_time = new DateTime.from_unix_local (job.completed_time);
                date = date_time.format ("%F %T");
            } else if (job.processing_time != 0) {
                var date_time = new DateTime.from_unix_local (job.processing_time);
                date = date_time.format ("%F %T");
            } else {
                var date_time = new DateTime.from_unix_local (job.creation_time);
                date = date_time.format ("%F %T");
            }

            list_store.set (iter, 1, job.title, 2, human_readable_job_state (job.state), 3, date, 0, new ThemedIcon (job.format.replace ("/", "-")));
        }

        // The View:
        var view = new Gtk.TreeView.with_model (list_store);
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (view);

        var cell = new Gtk.CellRendererText ();
        var cellell = new Gtk.CellRendererText ();
        cellell.ellipsize = Pango.EllipsizeMode.END;
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        var column = new Gtk.TreeViewColumn.with_attributes ("Job Title", cellell, "text", 1);
        column.expand = true;
        column.resizable = true;
        view.insert_column_with_attributes (-1, "", cellpixbuf, "gicon", 0);
        view.insert_column (column, -1);
        column = new Gtk.TreeViewColumn.with_attributes ("Time", cell, "text", 3);
        column.resizable = true;
        view.insert_column (column, -1);
        column = new Gtk.TreeViewColumn.with_attributes ("Job State", cell, "text", 2);
        column.resizable = true;
        view.insert_column (column, -1);

        var toolbar = new Gtk.Toolbar ();
        toolbar.icon_size = Gtk.IconSize.SMALL_TOOLBAR;
        toolbar.get_style_context ().add_class ("inline-toolbar");
        var start_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        toolbar.add (start_button);
        var pause_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("media-playback-pause-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        toolbar.add (pause_button);
        var stop_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("media-playback-stop-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        toolbar.add (stop_button);
        var expander = new Gtk.ToolItem ();
        expander.set_expand (true);
        expander.visible_vertical = false;
        toolbar.add (expander);
        var show_all_button = new Gtk.ToggleToolButton ();
        show_all_button.label = _("Show finished jobs");
        show_all_button.toggled.connect (() => {
            toggle_finished (show_all_button);
        });
        toolbar.add (show_all_button);

        grid.add (scrolled);
        grid.add (toolbar);
        var frame = new Gtk.Frame (null);
        frame.add (grid);
        return frame;
    }

    private void toggle_finished (Gtk.ToggleToolButton button) {
        if (button.active == true) {
            button.label = _("Hide finished jobs");
        } else {
            button.label = _("Show finished jobs");
        }
    }

    private string human_readable_reason (string reason) {
        for (int i = 0; i < reasons.length; i++) {
            if (reasons[i] in reason) {
                return _(statuses[i]);
            }
        }

        return reason;
    }

    private string human_readable_job_state (CUPS.IPP.JobState state) {
        switch (state) {
            case CUPS.IPP.JobState.PENDING:
                return _("Pending");
            case CUPS.IPP.JobState.HELD:
                return _("On Held");
            case CUPS.IPP.JobState.PROCESSING:
                return _("Processing");
            case CUPS.IPP.JobState.STOPPED:
                return _("Stopped");
            case CUPS.IPP.JobState.CANCELED:
                return _("Canceled");
            case CUPS.IPP.JobState.ABORTED:
                return _("Aborded");
            case CUPS.IPP.JobState.COMPLETED:
            default:
                return _("Completed");
        }
    }
}

public class Printers.PrinterRow : Gtk.ListBoxRow {
    public PrinterPage page;

    public PrinterRow (CUPS.Destination dest) {
        var label = new Gtk.Label (dest.printer_info);
        var image = new Gtk.Image.from_icon_name ("printer", Gtk.IconSize.DND);
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.add (image);
        grid.add (label);
        add (grid);
        page = new PrinterPage (dest);
        show_all ();
    }
}
