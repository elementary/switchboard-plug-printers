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

public class Printers.JobsView : Gtk.Frame {
    private Printer printer;
    private Gtk.ListStore list_store;
    private Gtk.Stack stack;

    public JobsView (Printer printer) {
        this.printer = printer;
        // The Job view
        list_store = new Gtk.ListStore (8, typeof (GLib.Icon),
                                           typeof (string),
                                           typeof (string),
                                           typeof (string),
                                           typeof (bool),
                                           typeof (GLib.Icon),
                                           typeof (bool),
                                           typeof (CUPS.IPP.JobState));
        var job_grid = new Gtk.Grid ();
        job_grid.orientation = Gtk.Orientation.VERTICAL;

        var view = new Gtk.TreeView.with_model (list_store);
        view.headers_visible = false;
        view.tooltip_column = 2;
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (view);

        var cell = new Gtk.CellRendererText ();
        var cellell = new Gtk.CellRendererText ();
        cellell.ellipsize = Pango.EllipsizeMode.END;
        var cellspin = new Gtk.CellRendererSpinner ();
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        view.insert_column_with_attributes (-1, "", cellpixbuf, "gicon", 0);
        var column = new Gtk.TreeViewColumn.with_attributes ("", cellell, "text", 1);
        column.expand = true;
        column.resizable = true;
        view.insert_column (column, -1);
        column = new Gtk.TreeViewColumn.with_attributes ("", cell, "text", 3);
        column.resizable = true;
        view.insert_column (column, -1);
        column = new Gtk.TreeViewColumn.with_attributes ("", cellpixbuf, "gicon", 5, "visible", 6);
        view.insert_column (column, -1);
        column = new Gtk.TreeViewColumn.with_attributes ("", cellspin, "active", 4, "visible", 4);
        view.insert_column (column, -1);

        list_store.set_default_sort_func (compare);

        var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
        foreach (var job in jobs) {
            switch (job.cjob.state) {
                case CUPS.IPP.JobState.CANCELED:
                case CUPS.IPP.JobState.ABORTED:
                case CUPS.IPP.JobState.COMPLETED:
                    continue;
                default:
                    add_job (job);
                    continue;
            }
        }

        var toolbar = new Gtk.Toolbar ();
        toolbar.icon_size = Gtk.IconSize.SMALL_TOOLBAR;
        toolbar.get_style_context ().add_class ("inline-toolbar");
        var start_pause_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        toolbar.add (start_pause_button);
        var stop_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("media-playback-stop-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        toolbar.add (stop_button);
        var expander = new Gtk.ToolItem ();
        expander.set_expand (true);
        expander.visible_vertical = false;
        toolbar.add (expander);
        var show_all_button = new Gtk.ToggleToolButton ();
        show_all_button.label = _("Show completed jobs");
        show_all_button.toggled.connect (() => {
            toggle_finished (show_all_button);
        });
        toolbar.add (show_all_button);

        var alert = new Granite.Widgets.AlertView (_("No jobs"), _("There are no jobs on the queue"), "document");
        alert.show_all ();

        stack = new Gtk.Stack ();
        stack.add_named (scrolled, "jobs");
        stack.add_named (alert, "no-jobs");
        if (list_store.iter_n_children (null) > 0) {
            stack.set_visible_child_name ("jobs");
        } else {
            stack.set_visible_child_name ("no-jobs");
        }

        job_grid.add (stack);
        job_grid.add (toolbar);
        add (job_grid);
    }

    private void add_job (Job job) {
        Gtk.TreeIter iter;
        list_store.append (out iter);
        var date_time = job.get_used_time ();
        string date = date_time.format ("%F %T");

        list_store.set (iter, 0, new ThemedIcon (job.cjob.format.replace ("/", "-")),
                              1, job.cjob.title,
                              2, job.translated_job_state (),
                              3, date,
                              4, job.cjob.state == CUPS.IPP.JobState.PROCESSING,
                              5, job.state_icon (),
                              6, job.cjob.state != CUPS.IPP.JobState.PROCESSING,
                              7, job.cjob.state);
    }

    private void toggle_finished (Gtk.ToggleToolButton button) {
        if (button.active == true) {
            button.label = _("Hide completed jobs");

            var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
            foreach (var job in jobs) {
                switch (job.cjob.state) {
                    case CUPS.IPP.JobState.CANCELED:
                    case CUPS.IPP.JobState.ABORTED:
                    case CUPS.IPP.JobState.COMPLETED:
                        add_job (job);
                        continue;
                    default:
                        continue;
                }
            }
        } else {
            button.label = _("Show completed jobs");
            Gtk.TreeIter? iter;
            var iters = new Gee.TreeSet<Gtk.TreeIter?> ();
            if (list_store.get_iter_first (out iter)) {
                do {
                    Value val;
                    list_store.get_value (iter, 7, out val);
                    CUPS.IPP.JobState state = (CUPS.IPP.JobState)val.get_int ();
                    switch (state) {
                        case CUPS.IPP.JobState.CANCELED:
                        case CUPS.IPP.JobState.ABORTED:
                        case CUPS.IPP.JobState.COMPLETED:
                            iters.add (iter);
                            continue;
                        default:
                            continue;
                    }
                } while (list_store.iter_next (ref iter));
            }

            foreach (var _iter in iters) {
                list_store.remove (_iter);
            }
        }

        if (list_store.iter_n_children (null) > 0) {
            stack.set_visible_child_name ("jobs");
        } else {
            stack.set_visible_child_name ("no-jobs");
        }
    }

    static int compare (Gtk.TreeModel model, Gtk.TreeIter a, Gtk.TreeIter b) {
        Value vala, valb;
        model.get_value (a, 7, out vala);
        model.get_value (b, 7, out valb);
        return 0;
    }
}
