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
        list_store = new Gtk.ListStore (5, typeof (GLib.Icon),
                                           typeof (string),
                                           typeof (string),
                                           typeof (string),
                                           typeof (Job));
        var job_grid = new Gtk.Grid ();
        job_grid.orientation = Gtk.Orientation.VERTICAL;

        var view = new Gtk.TreeView.with_model (list_store);
        view.headers_visible = false;
        view.tooltip_column = 2;
        view.get_selection ().set_mode (Gtk.SelectionMode.SINGLE);
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (view);

        var cell = new Gtk.CellRendererText ();
        var cellell = new Gtk.CellRendererText ();
        cellell.ellipsize = Pango.EllipsizeMode.END;
        var cellpixbuf = new Gtk.CellRendererPixbuf ();
        view.insert_column_with_attributes (-1, "", cellpixbuf, "gicon", 0);
        var column = new Gtk.TreeViewColumn.with_attributes ("", cellell, "text", 1);
        column.expand = true;
        column.resizable = true;
        view.insert_column (column, -1);
        column = new Gtk.TreeViewColumn.with_attributes ("", cell, "text", 3);
        column.resizable = true;
        view.insert_column (column, -1);
        var jobrenderer = new JobProcessingCellRenderer ();
        column = new Gtk.TreeViewColumn.with_attributes ("", jobrenderer, "job", 4);
        view.insert_column (column, -1);

        list_store.set_default_sort_func (compare);

        var toolbar = new Gtk.Toolbar ();
        toolbar.icon_size = Gtk.IconSize.SMALL_TOOLBAR;
        toolbar.get_style_context ().add_class ("inline-toolbar");
        var start_pause_button = new Gtk.ToolButton (null, null);
        start_pause_button.icon_name = "media-playback-pause-symbolic";
        start_pause_button.sensitive = false;
        var stop_button = new Gtk.ToolButton (null, null);
        stop_button.icon_name = "media-playback-stop-symbolic";
        stop_button.sensitive = false;
        var expander = new Gtk.ToolItem ();
        expander.set_expand (true);
        expander.visible_vertical = false;

        var show_all_button = new Gtk.ToggleToolButton ();
        show_all_button.label = _("Show completed jobs");
        show_all_button.toggled.connect (() => {
            toggle_finished (show_all_button);
        });

        toolbar.add (start_pause_button);
        toolbar.add (stop_button);
        toolbar.add (expander);
        toolbar.add (show_all_button);

        var alert = new Granite.Widgets.AlertView (_("No jobs"), _("There are no jobs on the queue"), "document");
        alert.show_all ();

        stack = new Gtk.Stack ();
        stack.add_named (scrolled, "jobs");
        stack.add_named (alert, "no-jobs");
        stack.set_visible_child_name ("no-jobs");

        var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
        foreach (var job in jobs) {
            switch (job.cjob.state) {
                case CUPS.IPP.JobState.CANCELED:
                case CUPS.IPP.JobState.ABORTED:
                case CUPS.IPP.JobState.COMPLETED:
                    continue;
                default:
                    add_job (job);
                    stack.set_visible_child_name ("jobs");
                    continue;
            }
        }

        view.cursor_changed.connect (() => {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            if (view.get_selection ().get_selected (out model, out iter)) {
                Value val;
                model.get_value (iter, 4, out val);
                var job = (Job) val.get_object ();
                if (job.get_hold_until () == "no-hold") {
                    start_pause_button.icon_name = "media-playback-pause-symbolic";
                } else {
                    start_pause_button.icon_name = "media-playback-start-symbolic";
                }

                if (job.state_icon () == null) {
                    start_pause_button.sensitive = true;
                    stop_button.sensitive = true;
                } else {
                    start_pause_button.icon_name = "media-playback-pause-symbolic";
                    start_pause_button.sensitive = false;
                    stop_button.sensitive = false;
                }
            } else {
                start_pause_button.icon_name = "media-playback-pause-symbolic";
                start_pause_button.sensitive = false;
                stop_button.sensitive = false;
            }
        });

        start_pause_button.clicked.connect (() => {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            if (view.get_selection ().get_selected (out model, out iter)) {
                Value val;
                model.get_value (iter, 4, out val);
                var job = (Job) val.get_object ();
                unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
                if (job.get_hold_until () == "no-hold") {
                    try {
                        pk_helper.job_set_hold_until (job.cjob.id, "indefinite");
                        start_pause_button.icon_name = "media-playback-start-symbolic";
                    } catch (Error e) {
                        critical (e.message);
                    }
                } else {
                    try {
                        pk_helper.job_set_hold_until (job.cjob.id, "no-hold");
                        start_pause_button.icon_name = "media-playback-pause-symbolic";
                    } catch (Error e) {
                        critical (e.message);
                    }
                }
            }
        });

        stop_button.clicked.connect (() => {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            if (view.get_selection ().get_selected (out model, out iter)) {
                Value val;
                model.get_value (iter, 4, out val);
                var job = (Job) val.get_object ();
                unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
                try {
                    pk_helper.job_cancel_purge (job.cjob.id, false);
                    start_pause_button.sensitive = false;
                    stop_button.sensitive = false;
                } catch (Error e) {
                    critical (e.message);
                }
            }
        });

        job_grid.add (stack);
        job_grid.add (toolbar);
        add (job_grid);

        unowned Cups.Notifier notifier  = Cups.Notifier.get_default ();
        notifier.job_created.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs, job_id, job_state, job_state_reason, job_name, job_impressions_completed) => {
            if (printer.dest.name != name) {
                return;
            }

            var jobs_ = printer.get_jobs (true, CUPS.WhichJobs.ALL);
            foreach (var job in jobs_) {
                if (job.cjob.id == job_id) {
                    add_job (job);
                    break;
                }
            }
        });
    }

    private void add_job (Job job) {
        Gtk.TreeIter iter;
        list_store.append (out iter);
        var date_time = job.get_used_time ();
        string date = date_time.format ("%F %T");

        list_store.set (iter, 0, job.get_file_icon (),
                              1, job.cjob.title,
                              2, job.translated_job_state (),
                              3, date,
                              4, job);
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
                    list_store.get_value (iter, 4, out val);
                    CUPS.IPP.JobState state = ((Job)val.get_object ()).cjob.state;
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
        model.get_value (a, 4, out vala);
        model.get_value (b, 4, out valb);
        var timea = ((Job) vala.get_object ()).get_used_time ();
        var timeb = ((Job) valb.get_object ()).get_used_time ();
        return timea.compare (timeb);
    }
}

public class Printers.JobProcessingCellRenderer : Gtk.CellRendererSpinner {

    /* icon property set by the tree column */
    public Job job { get; set; default=null;}
    private Gtk.CellRendererPixbuf cellrendererpixbuf;

    public JobProcessingCellRenderer () {
        
    }

    construct {
        cellrendererpixbuf = new Gtk.CellRendererPixbuf ();
        size = Gtk.IconSize.MENU;
        active = true;
    }

    /* render method */
    public override void render (Cairo.Context ctx, Gtk.Widget widget,
                                 Gdk.Rectangle background_area,
                                 Gdk.Rectangle cell_area,
                                 Gtk.CellRendererState flags) {
        var gicon = job.state_icon ();
        if (gicon == null) {
            base.render (ctx, widget, background_area, cell_area, flags);
        } else {
            cellrendererpixbuf.gicon = gicon;
            cellrendererpixbuf.render (ctx, widget, background_area, cell_area, flags);
        }
    }
}
