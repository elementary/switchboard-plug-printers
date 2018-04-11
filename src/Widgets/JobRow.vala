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
    private Gtk.Image job_state_icon;
    private Gtk.Stack action_stack;

    public JobRow (Printer printer, Job job) {
        this.printer = printer;
        this.job = job;

        var icon = new Gtk.Image.from_gicon (job.get_file_icon (), Gtk.IconSize.MENU);

        var title = new Gtk.Label (job.cjob.title);
        title.hexpand = true;
        title.halign = Gtk.Align.START;
        title.ellipsize = Pango.EllipsizeMode.END;

        var date_time = job.get_used_time ();
        var date = new Gtk.Label (Granite.DateTime.get_relative_datetime (date_time));

        job_state_icon = new Gtk.Image ();
        job_state_icon.gicon = job.state_icon ();
        job_state_icon.halign = Gtk.Align.END;
        job_state_icon.icon_size = Gtk.IconSize.SMALL_TOOLBAR;

        var cancel_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        cancel_button.tooltip_text = _("Cancel");
        cancel_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var start_pause_image = new Gtk.Image ();
        start_pause_image.icon_name = "media-playback-pause-symbolic";
        start_pause_image.icon_size = Gtk.IconSize.SMALL_TOOLBAR;

        var start_pause_button = new Gtk.Button ();
        start_pause_button.image = start_pause_image;
        start_pause_button.tooltip_text = _("Pause");
        start_pause_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var action_grid = new Gtk.Grid ();
        action_grid.add (cancel_button);
        action_grid.add (start_pause_button);
        action_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        action_stack = new Gtk.Stack ();
        action_stack.add_named (action_grid, "action-grid");
        action_stack.add_named (job_state_icon, "job-state-icon");

        grid = new Gtk.Grid ();
        grid.tooltip_text = job.translated_job_state ();
        grid.column_spacing = 3;
        grid.margin = 3;
        grid.margin_start = grid.margin_end = 6;
        grid.attach (icon, 0, 0);
        grid.attach (title, 1, 0);
        grid.attach (date, 2, 0);
        grid.attach (action_stack, 3, 0);

        add (grid);
        show_all ();

        update_state ();

        job.state_changed.connect (update_state);
        job.completed.connect (update_state);
        job.stopped.connect (update_state);

        start_pause_button.clicked.connect (() => {
            unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
            if (job.get_hold_until () == "no-hold") {
                try {
                    pk_helper.job_set_hold_until (job.cjob.id, "indefinite");
                    start_pause_image.icon_name = "media-playback-start-symbolic";
                    start_pause_button.tooltip_text = _("Resume");
                } catch (Error e) {
                    critical (e.message);
                }
            } else {
                try {
                    pk_helper.job_set_hold_until (job.cjob.id, "no-hold");
                    start_pause_image.icon_name = "media-playback-pause-symbolic";
                    start_pause_button.tooltip_text = _("Pause");
                } catch (Error e) {
                    critical (e.message);
                }
            }
        });

        cancel_button.clicked.connect (() => {
            unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
            try {
                pk_helper.job_cancel_purge (job.cjob.id, false);
                start_pause_button.sensitive = false;
                cancel_button.sensitive = false;
            } catch (Error e) {
                critical (e.message);
            }
        });
    }

    public void update_state () {
        var jobs = printer.get_jobs (true, CUPS.WhichJobs.ALL);
        foreach (var _job in jobs) {
            if (_job.cjob.id == job.cjob.id) {
                job = _job;
                break;
            }
        }

        if (job.state_icon () != null) {
            job_state_icon.gicon = job.state_icon ();
            action_stack.visible_child_name = "job-state-icon";
        } else {
            action_stack.visible_child_name = "action-grid";
        }

        grid.tooltip_text = job.translated_job_state ();
    }
}
