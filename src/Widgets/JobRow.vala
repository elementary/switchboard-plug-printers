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

public class Printers.JobRow : Gtk.ListBoxRow {
    public Job job { get; private set; }
    private Printer printer;

    private Gtk.Grid grid;

    public JobRow (Printer printer, Job job) {
        this.printer = printer;
        this.job = job;

        grid = new Gtk.Grid ();
        grid.tooltip_text = job.translated_job_state ();
        grid.column_spacing = 6;
        grid.row_spacing = 6;
        grid.margin = 6;

        Gtk.Image icon = new Gtk.Image.from_gicon (job.get_file_icon (), Gtk.IconSize.MENU);
        grid.attach (icon, 0, 0);

        Gtk.Label title = new Gtk.Label (job.cjob.title);
        title.hexpand = true;
        title.halign = Gtk.Align.START;
        title.ellipsize = Pango.EllipsizeMode.END;
        grid.attach (title, 1, 0);

        var date_time = job.get_used_time ();
        string date_string = date_time.format ("%F %T");
        Gtk.Label date = new Gtk.Label (date_string);
        grid.attach (date, 2, 0);

        Gtk.Widget state;
        if (job.state_icon () != null) {
            state = new Gtk.Image.from_gicon (job.state_icon (), Gtk.IconSize.MENU);
        } else {
            state = new Gtk.Spinner ();
            ((Gtk.Spinner)state).active = true;
            ((Gtk.Spinner)state).start ();
        }
        grid.attach (state, 3, 0);

        job.state_changed.connect (update_state);
        job.completed.connect (update_state);
        job.stopped.connect (update_state);

        add (grid);
        show_all ();
    }

    public void update_state () {
        var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
        foreach (var _job in jobs) {
            if (_job.cjob.id == job.cjob.id) {
                job = _job;
                break;
            }
        }

        Gtk.Widget state;
        if (job.state_icon () != null) {
            state = new Gtk.Image.from_gicon (job.state_icon (), Gtk.IconSize.MENU);
        } else {
            state = new Gtk.Spinner ();
            ((Gtk.Spinner)state).active = true;
            ((Gtk.Spinner)state).start ();
        }
        grid.remove_column (3);
        grid.attach (state, 3, 0);
        show_all ();

        grid.tooltip_text = job.translated_job_state ();
    }
}
