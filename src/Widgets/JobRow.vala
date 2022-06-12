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
    public Job job { get; construct set; }
    public Printer printer { get; construct set; }

    private Gtk.Box box;
    private Gtk.Image job_state_icon;
    private Gtk.Stack action_stack;

    public JobRow (Printer printer, Job job) {
        Object (
            job: job,
            printer: printer
        );
    }

    construct {
        var icon = new Gtk.Image.from_gicon (job.get_file_icon ()) {
            pixel_size = 16
        };

        var title = new Gtk.Label (job.cjob.title) {
            hexpand = true,
            halign = Gtk.Align.START,
            ellipsize = Pango.EllipsizeMode.END
        };

        var date_time = job.get_used_time ();
        var date = new Gtk.Label (Granite.DateTime.get_relative_datetime (date_time));

        job_state_icon = new Gtk.Image () {
            gicon = job.state_icon (),
            halign = Gtk.Align.END,
            pixel_size = 16
        };

        var cancel_button = new Gtk.Button () {
            child = new Gtk.Image.from_icon_name ("process-stop-symbolic") {
                pixel_size = 16,
            },
            tooltip_text = _("Cancel")
        };
        cancel_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var start_pause_image = new Gtk.Image () {
            icon_name = "media-playback-pause-symbolic",
            pixel_size = 16
        };

        var start_pause_button = new Gtk.Button () {
            child = start_pause_image,
            tooltip_text = _("Pause")
        };
        start_pause_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.append (cancel_button);
        action_box.append (start_pause_button);

        action_stack = new Gtk.Stack () {
            hhomogeneous = false
        };
        action_stack.add_named (action_box, "action-grid");
        action_stack.add_named (job_state_icon, "job-state-icon");

        box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3) {
            tooltip_text = job.translated_job_state (),
            margin_top = 3,
            margin_bottom = 3,
            margin_start = 6,
            margin_end = 6
        };
        box.append (icon);
        box.append (title);
        box.append (date);
        box.append (action_stack);

        child = box;

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

    private void update_state () {
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

        box.tooltip_text = job.translated_job_state ();
    }
}
