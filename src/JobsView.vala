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
    private unowned CUPS.Destination dest;

    public JobsView (CUPS.Destination dest) {
        this.dest = dest;
        // The Job view
        var list_store = new Gtk.ListStore (7, typeof (GLib.Icon), typeof (string), typeof (string), typeof (string), typeof (bool), typeof (GLib.Icon), typeof (bool));
        Gtk.TreeIter iter;
        var job_grid = new Gtk.Grid ();
        job_grid.orientation = Gtk.Orientation.VERTICAL;

        var view = new Gtk.TreeView.with_model (list_store);
        view.headers_visible = false;
        view.tooltip_column = 3;
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
        column = new Gtk.TreeViewColumn.with_attributes ("", cell, "text", 2);
        column.resizable = true;
        view.insert_column (column, -1);
        column = new Gtk.TreeViewColumn.with_attributes ("", cellpixbuf, "gicon", 5, "visible", 6);
        view.insert_column (column, -1);
        column = new Gtk.TreeViewColumn.with_attributes ("", cellspin, "active", 4, "visible", 4);
        view.insert_column (column, -1);

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

            list_store.set (iter, 0, new ThemedIcon (job.format.replace ("/", "-")),
                                  1, job.title,
                                  2, human_readable_job_state (job.state),
                                  3, date,
                                  4, job.state == CUPS.IPP.JobState.PROCESSING,
                                  5, job_state_icon (job.state),
                                  6, job.state != CUPS.IPP.JobState.PROCESSING);
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

        job_grid.add (scrolled);
        job_grid.add (toolbar);
        add (job_grid);
    }

    private void toggle_finished (Gtk.ToggleToolButton button) {
        if (button.active == true) {
            button.label = _("Hide completed jobs");
        } else {
            button.label = _("Show completed jobs");
        }
    }

    private string human_readable_job_state (CUPS.IPP.JobState state) {
        switch (state) {
            case CUPS.IPP.JobState.PENDING:
                return _("Job Pending");
            case CUPS.IPP.JobState.HELD:
                return _("On Held");
            case CUPS.IPP.JobState.PROCESSING:
                return _("Processing…");
            case CUPS.IPP.JobState.STOPPED:
                return _("Job Stopped");
            case CUPS.IPP.JobState.CANCELED:
                return _("Job Canceled");
            case CUPS.IPP.JobState.ABORTED:
                return _("Job Aborded");
            case CUPS.IPP.JobState.COMPLETED:
            default:
                return _("Job Completed");
        }
    }

    private GLib.Icon? job_state_icon (CUPS.IPP.JobState state) {
        switch (state) {
            case CUPS.IPP.JobState.PENDING:
            case CUPS.IPP.JobState.PROCESSING:
                return null;
            case CUPS.IPP.JobState.HELD:
            case CUPS.IPP.JobState.STOPPED:
                return new ThemedIcon ("media-playback-pause");
            case CUPS.IPP.JobState.CANCELED:
            case CUPS.IPP.JobState.ABORTED:
                return new ThemedIcon ("process-error-symbolic");
            case CUPS.IPP.JobState.COMPLETED:
            default:
                return new ThemedIcon ("process-completed-symbolic");
        }
    }
}
